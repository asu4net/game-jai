MAX_SCENES         :: 30;
DEF_SCENE_CAPACITY :: 100;

// #TODO_asuarez
// Think about how allocate the strings and the entity children handles. 
// Create a manager or something maybe.

Entity_Procs :: struct {

    CREATE      :: #type (slot : u32, tag : string) -> *Entity;
    DESTR0Y     :: #type (entity : *Entity);
    INIT        :: #type (entity : *Entity);
    DEINIT      :: #type (entity : *Entity);
    SERIALIZE   :: #type (entity : *Entity) -> string;
    DESERIALIZE :: #type (json : string) -> *Entity;

    create      : CREATE;
    destroy     : DESTR0Y;
    init        : INIT;
    deinit      : DEINIT;
    serialize   : SERIALIZE;
    deserialize : DESERIALIZE;
}

init :: ($TEntity: Type, procs : *Entity_Procs, init_proc : Entity_Procs.INIT = null, deinit_proc : Entity_Procs.DEINIT = null) {
    assert(procs != null);

    // Automatic procs
    procs.create = (slot : u32, tag : string) -> *Entity {
        scene := get_scene(slot).(*Scene(TEntity));
        flags := DEFAULT_ENTITY_FLAGS | .SERIALIZABLE;
        return create_entity(scene, tag, flags);
    };
    procs.destroy = (entity : *Entity) {
        e := entity.(*TEntity);
        immediate_destroy_entity(e);
    };
    procs.serialize = (entity : *Entity) -> string {
        e := entity.(*TEntity);
        return serialize_entity(e);
    };
    procs.deserialize = (json : string) -> *Entity {
        e := deserialize_entity(TEntity, json);
        return xx e;
    }
    
    // User provided procs
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

#add_context scenes: [MAX_SCENES] *Scene;

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
    return context.scenes[slot];
}

get_scene :: (slot : u32) -> *Scene(Entity) {
    assert(slot < MAX_SCENES);
    scene := get_scene_unsafe(slot);
    assert(scene != null);
    return xx context.scenes[slot];
}

add_scene :: (scene : *Scene, slot : u32) {
    assert(scene != null);
    assert(context.scenes[slot] == null);
    context.scenes[slot] = scene;
    scene.slot = slot;
}

remove_scene :: (slot : u32) {
    current := get_scene(slot);
    context.scenes[slot] = null;
}