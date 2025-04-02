MAX_ENTITY_ARRAYS :: 30;
DEF_ENTITY_ARRAY_CAPACITY :: 100;

Entity_Array :: struct($TEntity: Type = Entity) {
    #assert(is_entity(TEntity));
    data         : [] TEntity;
    used_ids     : Sparse_Set;
    free_ids     : Queue(Entity_ID);
    to_clean     : Table(Entity_ID, struct{});
    capacity     : u32;
    type         : Type;
    to_serialize : Table(string, Entity_ID);
}

entity_array_init :: (array: *Entity_Array($TEntity), slot : u32, capacity: u32 = DEF_ENTITY_ARRAY_CAPACITY) {
    assert(array && !entity_array_initialized(array));
    entity_array_add(array, slot, capacity);
    array.data = NewArray(capacity, TEntity);
    array.type = TEntity;
    sparse_init(*array.used_ids, capacity);
    queue_init(*array.free_ids, capacity + 1);
    for i : 0..capacity-1 queue_push_back(*array.free_ids, cast(u32) i);
    queue_pop_front(*array.free_ids); // Pop the invalid id [0]
    array.capacity = capacity;
}

entity_array_deinit :: (array: *Entity_Array) {
    assert(array != null);
    entity_array_remove(array);
    free(array.data.data);
    sparse_deinit(*array.used_ids);
    queue_deinit(*array.free_ids);
    deinit(*array.to_serialize);
    array.* = .{};
}

entity_array_get :: (entity : *Entity) -> *Entity_Array(Entity) {
    assert(entity != null);
    array := entity_array_get(entity.slot);
    assert(entity_array_initialized(array)); 
    return array;
}

entity_array_get_unsafe :: (slot : u32) -> *Entity_Array(Entity) {
    assert(slot < MAX_ENTITY_ARRAYS);
    return entity_arrays[slot];
}

entity_array_get :: (slot : u32) -> *Entity_Array(Entity) {
    assert(entity_array_count > 0 && slot < entity_array_count);
    array := entity_array_get_unsafe(slot);
    assert(array != null);
    return xx entity_arrays[slot];
}

entity_array_bind :: (slot : u32) {
    current := entity_array_get(slot);
    entity_array_current = current;
}

#scope_file

entity_arrays: [MAX_ENTITY_ARRAYS] *Entity_Array;
entity_array_count: u32;

entity_array_add :: (array : *Entity_Array, slot : u32, capacity : u32) {
    assert(array != null);
    assert(entity_array_count < MAX_ENTITY_ARRAYS); //Tío si has llegado aquí, lo estás haciendo raro.
    assert(entity_arrays[slot] == null);
    entity_arrays[slot] = array;
    entity_array_count += 1;
}

entity_array_remove :: (slot : u32) {
    current := entity_array_get(slot);
    entity_arrays[slot] = null;
    entity_array_count -= 1;
}