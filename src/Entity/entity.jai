Entity_ID :: u32;
DEFAULT_ENTITY_FLAGS :: (.VALID | .ENABLED | .GLOBAL_ENABLED).(Entity_Flag);

Entity_Flag :: enum_flags u16 {
    VALID;
    ENABLED;
    GLOBAL_ENABLED;
    SERIALIZABLE;
}

Entity_Ref :: struct {
    tag   : string;
    slot  : u32;
    id    : Entity_ID;
}

Entity :: struct {
    tag      : string;
    flags    : Entity_Flag;
    id       : Entity_ID;
    slot     : u32;
    parent   : Entity_Ref;
    children : [..] Entity_Ref; 
}

is_entity :: ($T: Type) -> bool {
    info := type_info(T);
    return type_info(Entity) == info || is_subclass_of(info, type_info(Entity).name);
}

entity_array_initialized :: (array : *Entity_Array) -> bool {
    assert(array != null);
    return array.data.data != null;
}

entity_exists :: (entity : *Entity) -> bool {
    assert(entity != null);
    array := entity_array_get_unsafe(entity.slot); 
    if array == null then return false;
    return sparse_test(*array.used_ids, entity.id);   
}

entity_valid :: (entity : *Entity) -> bool {
    assert(entity_exists(entity));
    return xx .VALID & entity.flags;   
}

entity_enabled :: (entity : *Entity) -> bool {
    assert(entity_valid(entity));
    return entity_valid(entity) && (.ENABLED & entity.flags).(bool);   
}

entity_global_enabled :: (entity : *Entity) -> bool {
    assert(entity_valid(entity));
    return entity_enabled(entity) && (.GLOBAL_ENABLED & entity.flags).(bool);   
}

entity_create :: ($TEntity : Type, slot : u32 = 0, tag := "", flags := DEFAULT_ENTITY_FLAGS) -> *TEntity {
    base_array := entity_array_get(slot);
    array := base_array.(*Entity_Array(TEntity));

    assert(array.used_ids.count <= array.capacity);
    id := queue_pop_front(*array.free_ids);
    index := sparse_insert(*array.used_ids, id);
    entity := *array.data[index];
    entity.tag = copy_string(tag);

    if entity.flags & .SERIALIZABLE {
        if entity.tag.count == 0 {
            log_error("Serializable cannot have an empty tag!");
            return null;
        }
        _, found := table_find(*array.to_serialize, tag);
        if found then {
            log_error("Serializable entity with the same tag already exists!");
            return null;
        }
        table_add(*array.to_serialize, tag, id);
    }

    entity.id    = id;
    entity.flags = flags;
    array.count =+ 1;

    return entity;
}

entity_destroy :: (entity : *Entity) {
    if entity == null then {
        log_error("You're trying to destroy a null entity dude");
        return;
    }
    
    entity.flags = entity.flags &~ .VALID;
    
    for child : entity.children {
        entity_destroy(entity_resolve_ref(*child));
    }
    
    array := entity_array_get(entity);
    table_add(*array.to_clean, entity.id, .{});
}

clean_destroyed_entities :: () {

    for array : entity_arrays {
        for _, entity_id : array.to_clean {
            
            entity_index := sparse_search(*array.used_ids, entity_id);
            assert(entity_index != 0);
            entity := array.data[entity_index];
            queue_push_back(*array.free_ids, entity_id);
            deleted, last := sparse_remove(*array.used_ids, entity_id);
            
            if deleted != last {
                array.data[deleted] = array.data[last];
                array.data[last] = .{};
            } else {
                array.data[deleted] = .{};
            }
            array.count-=1;
        }
        table_reset(*array.to_clean);
    }
}

entity_resolve_ref :: (ref : *Entity_Ref) -> *Entity {
    assert(ref != null);
    array := entity_array_get(ref.slot);
    
    if ref.id == 0 then {
        assert(ref.tag.count > 0);
        entity_id, found := table_find(*array.to_serialize, ref.tag);
        if found {
            ref.id = entity_id;
        }
    }

    if ref.id == 0 then return null;

    exists := sparse_test(*array.used_ids, ref.id);
    if !exists then return null;
    index := sparse_search(*array.used_ids, ref.id);
    return *array.data[index];
}

entity_make_ref :: (entity : *Entity) -> Entity_Ref {
    assert(entity_valid(entity));
    return .{
        id   = entity.id,
        tag  = entity.tag,
        slot = entity.slot,
    };
}

entity_clone :: ($TEntity : Type, template : *Entity) -> *Entity {
    assert(entity_valid(template));
    entity := entity_create(TEntity, template.slot, template.tag);
    id := entity.id;
    entity.* = template.*;
    entity.id = id;

    array_reset(*entity.children);
    
    for child : template.children {
        cloned_child := entity_clone(TEntity, entity_resolve_ref(*child));
        entity_set_parent(cloned_child, entity);
    }

    return entity;
}

entity_add_child :: (entity : *Entity, child : *Entity) {
    assert(entity != null && child != null);
    
    for ref : entity.children {
        current_child := entity_resolve_ref(*ref);
        if current_child.id == child.id then return;
    }

    child_ref := entity_make_ref(child);
    array_add(*entity.children, child_ref);
    compute_enabled_iterative(child_ref);
}

entity_remove_child :: (entity : *Entity, child : *Entity) {
    assert(entity != null && child != null);
    index := -1;
    found := false;
    for current_child, index : entity.children { 
        if child.id == current_child.id then { 
            found = true;
            break; 
        }
    }
    if found then array_unordered_remove_by_index(*entity.children, index);
    compute_enabled_iterative(entity_make_ref(child));
}

entity_set_parent :: (entity : *Entity, parent : *Entity) {
    entity_parent := entity_resolve_ref(*entity.parent);
    if entity_exists(entity_parent) && entity_valid(parent) {
        entity_remove_child(entity_parent, entity);
    }
    entity.parent = entity_make_ref(parent);
    entity_add_child(parent, entity);
}

entity_get_parent :: (entity : *Entity) -> *Entity {
    assert(entity_valid(entity));
    parent := entity_resolve_ref(*entity.parent);
    return parent;
}

entity_set_enabled :: (entity : *Entity, enabled := true) {
    assert(entity_valid(entity));
    entity_enabled := (.ENABLED & entity.flags).(bool);
    if enabled != entity_enabled
    then compute_enabled_iterative(entity_make_ref(entity));
}

compute_enabled_iterative :: (entity_ref : Entity_Ref) { 
    stack : [..] Entity_Ref;
    array_add(*stack, entity_ref ,,temp);

    while stack.count > 0 {
        current_ref := pop(*stack);
        current_entity := entity_resolve_ref(*current_ref);
        parent_ref := current_entity.parent;

        parent := entity_resolve_ref(*parent_ref);
        parent_enabled := ifx entity_exists(parent) && entity_valid(parent) then entity_global_enabled(parent) else true;
        new_global_enabled := (.ENABLED & current_entity.flags).(bool) && parent_enabled;
        
        if((.GLOBAL_ENABLED & current_entity.flags).(bool) != new_global_enabled) {
            for child : current_entity.children {
                array_add(*stack, child);
            } 
        }

        if new_global_enabled && !(.GLOBAL_ENABLED & current_entity.flags) { 
            current_entity.flags |= .GLOBAL_ENABLED;
        } 
        else if !new_global_enabled && .GLOBAL_ENABLED & current_entity.flags { 
            current_entity.flags = current_entity.flags &~ .GLOBAL_ENABLED;
        }
    }
}