GET_ENTITY_POOL_ELEMENT_CBK    :: #type (Entity);
REMOVE_ENTITY_POOL_ELEMENT_CBK :: #type (Entity);

Entity_Pool :: struct($N : s64, get_cbk : GET_ENTITY_POOL_ELEMENT_CBK = null, remove_cbk : REMOVE_ENTITY_POOL_ELEMENT_CBK  = null) {
    prefab        : Entity;
    pool_size     : s64 = N;
    elements      : [N] Entity;
    available_ids : Queue(u32);

    get_element_cbk    := get_cbk;
    remove_element_cbk := remove_cbk;
}

init_entity_pool :: (entity_pool : *Entity_Pool, prefab_path : string){
    init_queue(*entity_pool.available_ids, entity_pool.pool_size);

    for i : 0..entity_pool.pool_size - 1 {
        push_back(*entity_pool.available_ids, xx i);
    }

    entity_pool.prefab = dlz_entity_from_file(prefab_path);
    set_enabled(entity_pool.prefab, false);

    for entity_pool.elements {
        entity_pool.elements[it_index] = clone_entity(entity_pool.prefab);
        set_enabled(entity_pool.elements[it_index], false);
    }
}

deinit_entity_pool :: (entity_pool : *Entity_Pool) {
    deinit_queue(*entity_pool.available_ids);
    destroy_entity(entity_pool.prefab);
    for entity_pool.elements {
        destroy_entity(entity_pool.elements[it_index]);
    }
}

get_pool_element :: (entity_pool : *Entity_Pool) -> Entity {
    index := pop_front(*entity_pool.available_ids);
    if(entity_pool.get_element_cbk) {
        entity_pool.get_element_cbk(entity_pool.elements[index]);
    }
    return entity_pool.elements[index];
}

return_pool_element :: (entity_pool : *Entity_Pool, entity : Entity) -> bool {
    index := 0;
    found := false;
    for entity_pool.elements {
        found = entity_pool.elements[it_index] == entity;
        if (found) {
            index = it_index;
            break;
        }
    }
    if(!found) return false;

    if(entity_pool.remove_element_cbk) {
        entity_pool.remove_element_cbk(entity);
    }
    push_back(*entity_pool.available_ids, xx index);
    return true;
}