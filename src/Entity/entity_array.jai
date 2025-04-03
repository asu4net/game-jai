MAX_ENTITY_ARRAYS :: 30;
DEF_ENTITY_ARRAY_CAPACITY :: 100;

// #TODO_asuarez
// Think about how allocate the strings and the entity children handles. 

Entity_Array :: struct($TEntity: Type = Entity) {
    #assert(is_entity(TEntity));
    data         : [] TEntity;
    slot         : u32;
    used_ids     : Sparse_Set;
    count        : int;
    free_ids     : Queue(Entity_ID);
    to_clean     : Table(Entity_ID, struct{});
    capacity     : u32;
    type         : Type;
    to_serialize : Table(string, Entity_ID);
}

array_init :: (array: *Entity_Array($TEntity), slot : u32, capacity: u32 = DEF_ENTITY_ARRAY_CAPACITY) {
    assert(array && !array_initialized(array));
    array_add(array.(*Entity_Array(Entity)), slot, capacity);
    array.data = NewArray(capacity, TEntity);
    array.type = TEntity;
    array.slot = slot;
    init(*array.used_ids, capacity);
    init(*array.free_ids, capacity + 1);
    for i : 0..capacity-1 push_back(*array.free_ids, cast(u32) i);
    pop_front(*array.free_ids); // Pop the invalid id [0].
    array.capacity = capacity;
}

array_deinit :: (array: *Entity_Array) {
    assert(array != null);
    array_remove(array.slot);
    free(array.data.data);
    deinit(*array.used_ids);
    deinit(*array.free_ids);
    deinit(*array.to_serialize);
    array.* = .{};
}

array_get :: (entity : *Entity) -> *Entity_Array(Entity) {
    assert(entity != null);
    array := array_get(entity.slot);
    assert(array_initialized(array)); 
    return array;
}

array_get_unsafe :: (slot : u32) -> *Entity_Array(Entity) {
    assert(slot < MAX_ENTITY_ARRAYS);
    return arrays[slot];
}

array_get :: (slot : u32) -> *Entity_Array(Entity) {
    assert(array_count > 0 && slot < array_count);
    array := array_get_unsafe(slot);
    assert(array != null);
    return xx arrays[slot];
}

arrays: [MAX_ENTITY_ARRAYS] *Entity_Array;
array_count: u32;

array_add :: (array : *Entity_Array, slot : u32, capacity : u32) {
    assert(array != null);
    assert(array_count < MAX_ENTITY_ARRAYS); //Tío si has llegado aquí, lo estás haciendo raro.
    assert(arrays[slot] == null);
    arrays[slot] = array;
    array_count += 1;
}

array_remove :: (slot : u32) {
    current := array_get(slot);
    arrays[slot] = null;
    array_count -= 1;
}