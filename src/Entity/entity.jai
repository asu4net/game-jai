Entity_ID :: u32;
DEFAULT_ENTITY_FLAGS :: (.VALID | .LOCAL_ENABLED | .ENABLED).(Entity_Flag);

Entity_Flag :: enum_flags u16 {
    VALID;
    LOCAL_ENABLED;
    ENABLED;
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

array_initialized :: (array : *Entity_Array) -> bool {
    assert(array != null);
    return array.data.data != null;
}

is_not_cleaned :: (entity : *Entity) -> bool {
    assert(entity != null);
    array := array_get_unsafe(entity.slot); 
    if array == null then return false;
    return test(*array.used_ids, entity.id);   
}

is_not_destroyed :: (entity : *Entity) -> bool {
    assert(is_not_cleaned(entity));
    return xx .VALID & entity.flags;   
}

is_local_enabled :: (entity : *Entity) -> bool {
    assert(is_not_destroyed(entity));
    return is_not_destroyed(entity) && (.LOCAL_ENABLED & entity.flags).(bool);   
}

is_enabled :: (entity : *Entity) -> bool {
    assert(is_not_destroyed(entity));
    return is_local_enabled(entity) && (.ENABLED & entity.flags).(bool);   
}

create_entity :: ($TEntity : Type, slot : u32 = 0, tag := "", flags := DEFAULT_ENTITY_FLAGS) -> *TEntity {
    base_array := array_get(slot);
    array := base_array.(*Entity_Array(TEntity));

    assert(array.used_ids.count <= array.capacity);
    id := pop_front(*array.free_ids);
    index := insert_id(*array.used_ids, id);
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

destroy_entity :: (entity : *Entity) {
    if entity == null then {
        log_error("You're trying to destroy a null entity dude");
        return;
    }
    
    entity.flags = entity.flags &~ .VALID;
    
    for child : entity.children {
        destroy_entity(resolve_ref(*child));
    }
    
    array := array_get(entity);
    table_add(*array.to_clean, entity.id, .{});
}

clean_destroyed_entities :: () {
    for array : arrays {
        for _, id : array.to_clean {        
            index := search(*array.used_ids, id);
            assert(index != 0);
            entity := array.data[index];
            push_back(*array.free_ids, id);
            deleted, last := remove_id(*array.used_ids, id);       
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

resolve_ref :: (ref : *Entity_Ref) -> *Entity {
    assert(ref != null);
    array := array_get(ref.slot);
    
    if ref.id == 0 then {
        assert(ref.tag.count > 0);
        id, found := table_find(*array.to_serialize, ref.tag);
        if found {
            ref.id = id;
        }
    }

    if ref.id == 0 then return null;

    exists := test(*array.used_ids, ref.id);
    if !exists then return null;
    index := search(*array.used_ids, ref.id);
    return *array.data[index];
}

make_ref :: (entity : *Entity) -> Entity_Ref {
    assert(is_not_destroyed(entity));
    return .{
        id   = entity.id,
        tag  = entity.tag,
        slot = entity.slot,
    };
}

clone :: ($TEntity : Type, template : *Entity) -> *Entity {
    assert(is_not_destroyed(template));
    entity := create_entity(TEntity, template.slot, template.tag);
    id := entity.id;
    entity.* = template.*;
    entity.id = id;

    array_reset(*entity.children);
    
    for child : template.children {
        cloned_child := clone(TEntity, resolve_ref(*child));
        set_parent(cloned_child, entity);
    }

    return entity;
}

add_child :: (entity : *Entity, child : *Entity) {
    assert(entity != null && child != null);
    
    for ref : entity.children {
        current_child := resolve_ref(*ref);
        if current_child.id == child.id then return;
    }

    child_ref := make_ref(child);
    array_add(*entity.children, child_ref);
    compute_enabled_iterative(child_ref);
}

remove_child :: (entity : *Entity, child : *Entity) {
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
    compute_enabled_iterative(make_ref(child));
}

set_parent :: (entity : *Entity, parent : *Entity) {
    parent := resolve_ref(*entity.parent);
    if is_not_cleaned(parent) && is_not_destroyed(parent) {
        remove_child(parent, entity);
    }
    entity.parent = make_ref(parent);
    add_child(parent, entity);
}

get_parent :: (entity : *Entity) -> *Entity {
    assert(is_not_destroyed(entity));
    parent := resolve_ref(*entity.parent);
    return parent;
}

set_enabled :: (entity : *Entity, enabled := true) {
    assert(is_not_destroyed(entity));
    is_local_enabled := (.LOCAL_ENABLED & entity.flags).(bool);
    if enabled != is_local_enabled
    then compute_enabled_iterative(make_ref(entity));
}

compute_enabled_iterative :: (ref : Entity_Ref) { 
    stack : [..] Entity_Ref;
    array_add(*stack, ref ,,temp);

    while stack.count > 0 {
        current_ref := pop(*stack);
        current_entity := resolve_ref(*current_ref);
        parent_ref := current_entity.parent;

        parent := resolve_ref(*parent_ref);
        parent_enabled := ifx is_not_cleaned(parent) && is_not_destroyed(parent) then is_enabled(parent) else true;
        new_enabled := (.LOCAL_ENABLED & current_entity.flags).(bool) && parent_enabled;
        
        if((.ENABLED & current_entity.flags).(bool) != new_enabled) {
            for child : current_entity.children {
                array_add(*stack, child);
            } 
        }

        if new_enabled && !(.ENABLED & current_entity.flags) { 
            current_entity.flags |= .ENABLED;
        } 
        else if !new_enabled && .ENABLED & current_entity.flags { 
            current_entity.flags = current_entity.flags &~ .ENABLED;
        }
    }
}