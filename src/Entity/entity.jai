Entity_ID :: u32;
UUID :: u64;

Entity_Flag :: enum_flags u16 {
    VALID;
    ENABLED;
    GLOBAL_ENABLED;
}

Entity_Ref :: struct {
    slot  : u32;
    id    : Entity_ID;
    uuid  : UUID;
}

Entity :: struct {
    tag      : string;
    flags    : Entity_Flag;
    uuid     : UUID;
    id       : Entity_ID;
    slot     : u32;
    parent   : Entity_Ref;
    children : [..] Entity_Ref; 
}

ENTITY_TYPE_NAME :: #run -> string {
    info := type_info(Entity);
    assert(info.type == .STRUCT);
    info_struct : *Type_Info_Struct = xx info;
    return info_struct.name; 
}

is_entity :: ($T: Type) -> bool {
    info := type_info(T);
    return type_info(Entity) == info || is_subclass_of(info, ENTITY_TYPE_NAME);
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

//#TODO_asuarez entity_make_ref & entity_resolve_ref 

entity_create :: (slot : u32 = 0, tag := "", flags := Entity_Flag) -> *Entity {
    array := entity_array_get(slot);
    assert(array.used_ids.count <= array.capacity);
    id := queue_pop_front(*array.free_ids);
    index := sparse_insert(*array.used_ids, id);
    entity := *array.data[index];
    entity.id = id;

    //Default values
    entity.tag   = tag;
    entity.flags = .VALID | .ENABLED | .GLOBAL_ENABLED;

    return entity;
}