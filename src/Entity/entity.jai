Entity_ID :: u32;

Entity_Flag :: enum_flags u16 {
    VALID;
    LOCAL_ENABLED;
    ENABLED;
    PREFAB;
}

Entity_Ref :: struct {
    tag   : string;
    slot  : u32;
    id    : Entity_ID; @JsonIgnore
}

hash_entity_ref :: (a : Entity_Ref) -> u32 {
    return xx a.id;
}

Entity_Ref_Set :: Table(Entity_Ref, struct{}, hash_entity_ref, compare_entity_ref);

compare_entity_ref :: (a : Entity_Ref, b : Entity_Ref) -> bool {
    assert(is_not_cleaned(resolve_ref(*a)) && is_not_cleaned(resolve_ref(*b)));
    return a.id == b.id;
}

Entity :: struct {
    tag      : string;
    flags    : Entity_Flag = .VALID | .LOCAL_ENABLED | .ENABLED;
    id       : Entity_ID; @JsonIgnore
    slot     : u32;
    parent   : Entity_Ref;
    children : [..] Entity_Ref; 
}

is_subclass_of_entity :: inline ($T: Type) -> bool {
    return is_subclass_of(type_info(T), type_info(Entity).name);
}

is_not_cleaned :: (entity : *Entity) -> bool {
    assert(entity != null);
    scene := get_scene_unsafe(entity.slot); 
    if scene == null then return false;
    return test(*scene.used_ids, entity.id);   
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

is_prefab :: (entity : *Entity) -> bool {
    assert(is_not_destroyed(entity));
    return (.PREFAB & entity.flags).(bool);   
}

should_update :: (entity : *Entity) -> bool {
    return !is_enabled(entity) || !is_prefab(entity);
}

// #NOTE_asuarez we don't know if the children entities would be the same type as
// the provided so a bit of function pointer mess is required :p.
serialize_entity_recursive :: (entity : *Entity, builder : *String_Builder = null) {
    assert(entity != null);
    scene := get_scene(entity);
    serialized_entity := scene.entity_procs.serialize(entity);
    append(builder, serialized_entity ,,temp);
    for ref : entity.children {
        child := resolve_ref(*ref);
        serialize_entity_recursive(child, builder);        
    }
}

serialize_subclassed_entity :: (entity : *$TEntity) -> string {
    #assert(is_subclass_of_entity(TEntity));
    assert(entity != null && entity.tag.count > 0);
    builder : String_Builder;
    entity_str := json_write_string(entity ,,temp);
    append(*builder, "\n#entity\n" ,,temp);
    append(*builder, entity_str ,,temp);
    return builder_to_string(*builder ,,temp);
}

deserialize_subclassed_entity :: ($TEntity : Type, json : string) -> *TEntity {
    #assert(is_subclass_of_entity(TEntity));
    success, e := json_parse_string(json, TEntity ,,temp);

    if !success {
        log_error("Entity could not be deserialized!");
        return null;
    }
    
    entity := clone_entity(*e, e.tag, deserialization = true);
    return xx entity;
}

deserialize_entity :: (json : string) -> *Entity {
    //#REVIEW_asuarez Currently I'm deserializing the entity twice to get the scene slot.
    // It would be better to have some kind of entity header, but for it is ok for now.
    success, generic_entity := json_parse_string(json, Entity ,,temp);
    if !success {
        return null;
    }
    scene := get_scene(generic_entity.slot);
    if !scene {
        return null;
    }
    specific_entity := scene.entity_procs.deserialize(json);
    return specific_entity;
}

deserialize_entity_recursive :: (json : string) -> *Entity {

    tag_found : bool;
    builder : String_Builder;
    parent_entity : *Entity;

    while 1 {
        line, found := consume_next_line(*json);
        line = trim(line);

        deserialize_section :: (builder : *String_Builder, parent : **Entity) {
            entity := deserialize_entity(builder_to_string(builder ,,temp));
            reset(builder);
            assert(entity != null);
            //#REVIEW_asuarez We expect that the first entity should be the parent.
            if !parent.* parent.* = entity;
        }

        // We asume end of file, so deserialize last entity
        if !found {
            assert(tag_found);
            deserialize_section(*builder, *parent_entity);
            break;
        }

        if contains(line, "#entity") {
            if !tag_found {
                tag_found = true;    
                continue;
            }
            deserialize_section(*builder, *parent_entity);
        } else {
            append(*builder, line);
        }    
    }
    
    return parent_entity;
}

add_tag :: (entity : *Entity, tag : string) {
    assert(is_not_destroyed(entity));
    assert(tag.count > 0);
    assert(entity.tag.count == 0);
    scene := get_scene(entity.slot);
     _, found := table_find(*scene.tag_to_id, tag);
    assert(!found);
    entity.tag = copy_string(tag);
    table_add(*scene.tag_to_id, entity.tag, entity.id);
}

create_entity :: (scene : *Scene($TEntity), tag := "") -> *TEntity {
    #assert(is_subclass_of_entity(TEntity));
    assert(scene.count < Scene(TEntity).CAPACITY);
    
    id := pop_front(*scene.free_ids);
    index := insert_id(*scene.used_ids, id);
    entity := *scene.entities[index];
    entity.slot = scene.slot;
    entity.id = id;
    add_tag(entity, tag);

    scene.count += 1;

    if scene.entity_procs.init {
        scene.entity_procs.init(entity);
    }

    return entity;
}

create_entity :: ($TEntity : Type, slot : u32 = 0, tag := "") -> *TEntity {
    #assert(is_subclass_of_entity(TEntity));
    scene := get_scene(slot).(*Scene(TEntity));
    return create_entity(scene, tag);
}

destroy_entity :: (entity : *Entity) {
    assert(is_not_cleaned(entity));
    
    if !is_not_destroyed(entity) {
        return;
    }
    
    entity.flags = entity.flags &~ .VALID;
    
    for ref : entity.children {
        child := resolve_ref(*ref);    
        destroy_entity(child);
    }

    scene := get_scene(entity);
    table_add(*scene.to_clean, entity.id, .{});
}

immediate_destroy_subclassed_entity :: (entity : *$TEntity, recursive := false) {
    #assert(is_subclass_of_entity(TEntity));
    assert(is_not_cleaned(entity));
    scene := get_scene(entity).(*Scene(TEntity));
    
    if scene.entity_procs.deinit {
        scene.entity_procs.deinit(entity);
    }
    
    parent := resolve_ref(*entity.parent);

    if parent {
        remove_child(parent, entity);
    }

    push_back(*scene.free_ids, entity.id);
    
    if recursive {
        for ref : entity.children {
            child := resolve_ref(*ref);
            child_scene := get_scene(child);
            child_scene.entity_procs.destroy(child, recursive = true);
        }
    }

    array_free(entity.children);

    if entity.tag.count > 0 {
        success, _ := table_remove(*scene.tag_to_id, entity.tag);
        assert(success);
        free(entity.tag);
    }
    deleted, last := remove_id(*scene.used_ids, entity.id);       
    if deleted != last {
        scene.entities[deleted] = scene.entities[last];
        scene.entities[last] = .{};
    } else {
        scene.entities[deleted] = .{};
    }
    scene.count-=1;
}

immediate_destroy_entity :: (entity : *Entity, recursive := false) {
    assert(is_not_cleaned(entity));
    scene := get_scene(entity);
    scene.entity_procs.destroy(entity, recursive);
}

resolve_ref :: (ref : *Entity_Ref) -> *Entity {
    assert(ref != null);
    scene := get_scene(ref.slot);
    
    if ref.id == 0 then {
        if ref.tag.count == 0 {
            return null;
        }

        id, found := table_find(*scene.tag_to_id, ref.tag);
        if found {
            ref.id = id;
        }
    }

    if ref.id == 0 then return null;

    exists := test(*scene.used_ids, ref.id);
    if !exists then return null;
    index := search(*scene.used_ids, ref.id);
    return scene.entity_procs.get_at(scene, index);
}

make_ref :: (entity : *Entity) -> Entity_Ref {
    assert(is_not_destroyed(entity));
    return .{
        id   = entity.id,
        tag  = entity.tag,
        slot = entity.slot,
    };
}

clone_entity :: (template : *Entity, tag := "", deserialization := false) -> *Entity {
    assert(template != null);
    scene := get_scene(template);
    entity := scene.entity_procs.create(template.slot, tag);
    entity.flags = template.flags;

    if deserialization {
        entity.parent = template.parent;
        array_copy(*entity.children, template.children);

    } else {
        for child : template.children {
            cloned_child := clone_entity(resolve_ref(*child));
            set_parent(cloned_child, entity);
        }
    }

    if scene.entity_procs.copy {
       scene.entity_procs.copy(entity, template); 
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