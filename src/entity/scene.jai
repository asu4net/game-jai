MAX_SCENES         :: 30;
DEF_SCENE_CAPACITY :: 100;

// #TODO_asuarez
// Think about how allocate the strings and the entity children handles. 
// Create a manager or something maybe.

MAKE_PREFAB_PROC :: #type (*Scene(Entity)) -> *Entity;
INIT_ENTITY_PROC :: #type (*Entity);

Scene :: struct($TEntity: Type = Entity) {

    #assert(is_entity(TEntity));
    entities     : [] TEntity;
    slot         : u32;
    used_ids     : Sparse_Set;
    count        : int;
    free_ids     : Queue(Entity_ID);
    to_clean     : Table(Entity_ID, struct{});
    capacity     : u32;
    type         : *Type_Info_Struct;
    to_serialize : Table(string, Entity_ID);
    make_prefab  : MAKE_PREFAB_PROC;
    init_entity  : INIT_ENTITY_PROC;
}

init :: (scene: *Scene($TEntity), slot : u32, init_proc : INIT_ENTITY_PROC = null, capacity: u32 = DEF_SCENE_CAPACITY) {
    assert(scene && !initialized(scene));
    add_scene(scene.(*Scene(Entity)), slot, capacity);
    scene.entities = NewArray(capacity, TEntity);
    scene.type = type_info(TEntity);
    scene.slot = slot;
    init(*scene.used_ids, capacity);
    init(*scene.free_ids, capacity + 1);
    for i : 0..capacity-1 push_back(*scene.free_ids, cast(u32) i);
    pop_front(*scene.free_ids); // Pop the invalid id [0].
    scene.capacity = capacity;
    scene.make_prefab = (scene : *Scene(Entity)) -> *Entity {
        //#TODO_asuarez Mark the entity as prefab.
        return create_entity(TEntity, scene.slot);
    };
    scene.init_entity = init_proc;
}

deinit :: (scene: *Scene) {
    assert(scene != null);
    remove_scene(scene.slot);
    free(scene.entities.data);
    deinit(*scene.used_ids);
    deinit(*scene.free_ids);
    deinit(*scene.to_serialize);
    scene.* = .{};
}

get_scene :: (entity : *Entity) -> *Scene(Entity) {
    assert(entity != null);
    scene := get_scene(entity.slot);
    assert(initialized(scene)); 
    return scene;
}

get_scene_unsafe :: (slot : u32) -> *Scene(Entity) {
    assert(slot < MAX_SCENES);
    return scenes[slot];
}

get_scene :: (slot : u32) -> *Scene(Entity) {
    assert(scene_count > 0 && slot < scene_count);
    scene := get_scene_unsafe(slot);
    assert(scene != null);
    return xx scenes[slot];
}

scenes: [MAX_SCENES] *Scene;
scene_count: u32;

add_scene :: (scene : *Scene, slot : u32, capacity : u32) {
    assert(scene != null);
    assert(scene_count < MAX_SCENES); //Tío si has llegado aquí, lo estás haciendo raro.
    assert(scenes[slot] == null);
    scenes[slot] = scene;
    scene_count += 1;
}

remove_scene :: (slot : u32) {
    current := get_scene(slot);
    scenes[slot] = null;
    scene_count -= 1;
}