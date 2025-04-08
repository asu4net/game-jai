MAX_SCENES         :: 30;
DEF_SCENE_CAPACITY :: 100;

// #TODO_asuarez
// Think about how allocate the strings and the entity children handles. 
// Create a manager or something maybe.

Entity_Procs :: struct {

    CREATE  :: #type (slot : u32, tag : string) -> *Entity;
    DESTR0Y :: #type (entity : *Entity);
    INIT    :: #type (entity : *Entity);
    DEINIT  :: #type (entity : *Entity);

    create  : CREATE;
    destroy : DESTR0Y;
    init    : INIT;
    deinit  : DEINIT;
}

init :: ($TEntity: Type, procs : *Entity_Procs, init_proc : Entity_Procs.INIT = null, deinit_proc : Entity_Procs.DEINIT = null) {
    assert(procs != null);
    procs.create = (slot : u32, tag : string) -> *Entity {
        scene := get_scene(slot).(*Scene(TEntity));
        return create_entity(scene, tag);
    }
    procs.destroy = (entity : *Entity) {
        e := entity.(*TEntity);
        immediate_destroy_entity(e);
    }
    procs.init   = init_proc;
    procs.deinit = deinit_proc;
}

Scene :: struct($TEntity: Type = Entity) {

    #assert(is_entity(TEntity));
    entities     : [..] TEntity;
    slot         : u32;
    count        : int;
    capacity     : u32;
    used_ids     : Sparse_Set;
    free_ids     : Queue(Entity_ID);
    to_clean     : Table(Entity_ID, struct{});
    type         : *Type_Info_Struct;
    to_serialize : Table(string, Entity_ID);
    entity_procs : Entity_Procs;
}

init :: (scene          : *Scene($TEntity), 
         slot           : u32, 
         init_proc      : Entity_Procs.INIT   = null,
         deinit_proc    : Entity_Procs.DEINIT = null,
         start_capacity : u32 = DEF_SCENE_CAPACITY) 
{
    assert(scene && !initialized(scene));
    add_scene(scene.(*Scene(Entity)), slot);
    array_resize(*scene.entities, start_capacity + 1);
    scene.type     = type_info(TEntity);
    scene.capacity = start_capacity + 1;
    
    init(*scene.used_ids, start_capacity);
    init(*scene.free_ids, start_capacity + 1);
    
    for i : 1..start_capacity push_back(*scene.free_ids, xx i);

    init(TEntity, *scene.entity_procs, init_proc, deinit_proc); 
}

deinit :: (scene: *Scene) {
    assert(scene != null);

    for i : 1..scene.count {
        e := (*scene.entities[i]).(*Entity2D);
        scene.entity_procs.destroy(e);
    }

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

add_scene :: (scene : *Scene, slot : u32) {
    assert(scene != null);
    assert(scene_count < MAX_SCENES); //Tío si has llegado aquí, lo estás haciendo raro.
    assert(scenes[slot] == null);
    scenes[slot] = scene;
    scene.slot = slot;
    scene_count += 1;
}

remove_scene :: (slot : u32) {
    current := get_scene(slot);
    scenes[slot] = null;
    scene_count -= 1;
}