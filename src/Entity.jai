Entity_ID :: u32;
UUID :: u64;

DEF_ENTITY_ARRAY_CAPACITY :: 100;
MAX_ENTITY_ARRAYS :: 30;  

Entity_Flag :: enum_flags u16 {
    VALID;
    ENABLED;
    GLOBAL_ENABLED;
    VISIBLE;
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
    pos      : Vector2;
    ang      : float32;
    size     : Vector2;
    tint     : Vector4;
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

Entity_Array :: struct($TEntity: Type = Entity) {
    #assert(is_entity(TEntity));
    data     : [] TEntity;
    used_ids : Sparse_Set;
    free_ids : Queue(u32);
    to_clean : Table(Entity_ID, struct{});
    capacity : u32;
}

entity_array_init :: (array: *Entity_Array($TEntity), slot : u32, capacity: u32 = DEF_ENTITY_ARRAY_CAPACITY) {
    assert(array && !entity_array_initialized(array));
    entity_array_add(array, slot, capacity);
    array.data = NewArray(capacity, TEntity);
    sparse_init(*array.used_ids, capacity);
    queue_init(*array.free_ids, capacity + 1);
    for i : 0..capacity-1 queue_push_back(*array.free_ids, cast(u32) i);
    queue_pop_front(*array.free_ids); // Pop the invalid id [0]
    array.capacity = capacity;
}

entity_array_initialized :: (array : *Entity_Array) -> bool {
    assert(array != null);
    return array.data.data != null;
}

entity_array_get :: (entity : *Entity) -> *Entity_Array(Entity) {
    assert(entity != null);
    array := entity_array_get(entity.slot);
    assert(entity_array_initialized(array)); 
    return array;
}

entity_exists :: (entity : *Entity) -> bool {
    assert(entity != null);
    if entity_arrays[entity.slot] == null then return false;
    array := entity_array_get(entity);
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
    entity_id : Entity_ID = queue_pop_front(*array.free_ids);
    index := sparse_insert(*array.used_ids, entity_id);
    entity := *array.data[index];
    entity.id = entity_id;

    //Default values
    entity.size  = ONE_2D;
    entity.tint  = WHITE;
    entity.tag   = tag;
    entity.flags = .VALID | .ENABLED | .GLOBAL_ENABLED | .VISIBLE;

    return entity;
}

entity_array_deinit :: (array: *Entity_Array) {
    assert(array != null);
    entity_array_remove(array);
    free(array.data.data);
    sparse_deinit(*array.used_ids);
    queue_deinit(*array.free_ids);
    array.* = .{};
}

#scope_module

#import "Hash_Table";
#import "Math";
#import "Core";
#import "Basic";
#import "Compiler";

//#NOTE_asuarez Shitty manager, but I don't care.

entity_arrays: [MAX_ENTITY_ARRAYS] *Entity_Array;
entity_array_count: u32;
entity_array_current: *Entity_Array;

entity_array_add :: (array : *Entity_Array, slot : u32, capacity : u32) {
    assert(array != null);
    assert(entity_array_count < MAX_ENTITY_ARRAYS); //Tío si has llegado aquí, lo estás haciendo raro.
    assert(entity_arrays[slot] == null);
    entity_arrays[slot] = array;
    entity_array_count += 1;
    entity_array_current = ifx entity_array_current == null then array;
}

entity_array_get :: (slot : u32) -> *Entity_Array(Entity) {
    assert(entity_array_count > 0 && slot < entity_array_count);
    assert(entity_arrays[slot] != null);
    return xx entity_arrays[slot];
}

entity_array_bind :: (slot : u32) {
    current := entity_array_get(slot);
    entity_array_current = current;
}

entity_array_remove :: (slot : u32) {
    current := entity_array_get(slot);
    entity_array_current = ifx entity_array_current == current then null;
    entity_arrays[slot] = null;
    entity_array_count -= 1;
}