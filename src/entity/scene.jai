MAX_SCENES         :: 30;
DEF_SCENE_CAPACITY :: 100;

// #TODO_asuarez
// Think about how allocate the strings and the entity children handles. 
// Create a manager or something maybe.

Entity_Procs :: struct {

    GET_AT      :: #type (scene : *Scene(Entity), index : int) -> *Entity;
    CREATE      :: #type (slot : u32, tag : string) -> *Entity;
    DESTR0Y     :: #type (entity : *Entity, recursive : bool);
    INIT        :: #type (entity : *Entity);
    DEINIT      :: #type (entity : *Entity);
    SERIALIZE   :: #type (entity : *Entity) -> string;
    DESERIALIZE :: #type (json   : string) -> *Entity;
    COPY        :: #type (dst : *Entity, src : *Entity);
#if EDITOR {
    DRAW_EDITOR :: #type (entity : *Entity); 
}

    get_at      : GET_AT;
    create      : CREATE;
    destroy     : DESTR0Y;
    init        : INIT;
    deinit      : DEINIT;
    serialize   : SERIALIZE;
    deserialize : DESERIALIZE;
    copy        : COPY; //#REVIEW_asuarez Maybe call this post-clone
#if EDITOR {
    draw_editor : DRAW_EDITOR;
}
}

init :: ($TEntity: Type, procs : *Entity_Procs, init_proc : Entity_Procs.INIT = null, deinit_proc : Entity_Procs.DEINIT = null, copy_proc : Entity_Procs.COPY) {
    assert(procs != null);

    // Automatic procs
    procs.get_at = (scene : *Scene(Entity), index : int) -> *Entity {
        assert(initialized(scene));
        subclassed_scene := scene.(*Scene(TEntity));
        return get_subclassed_entity_at(subclassed_scene, index);
    }
    procs.create = (slot : u32, tag : string) -> *Entity {
        scene := get_scene(slot).(*Scene(TEntity));
        return create_entity(scene, tag);
    };
    procs.destroy = (entity : *Entity, recursive : bool) {
        e := entity.(*TEntity);
        immediate_destroy_subclassed_entity(e, recursive);
    };
    procs.serialize = (entity : *Entity) -> string {
        e := entity.(*TEntity);
        return serialize_subclassed_entity(e);
    };
    procs.deserialize = (json : string) -> *Entity {
        e := deserialize_subclassed_entity(TEntity, json);
        return xx e;
    }
#if EDITOR {
    procs.draw_editor = (entity : *Entity) {
        e := entity.(*TEntity);
        draw_editor(e.tag.data, e, type_info(TEntity));
    }
}

    // User provided procs
    procs.init   = init_proc;
    procs.deinit = deinit_proc;

    if !copy_proc {

        procs.copy = (dst : *Entity, src : *Entity) {
            d := dst.(*TEntity);
            s := src.(*TEntity);
            base := d.entity;
            d.* = s.*;
            d.entity = base;
        }
    } else {
        procs.copy = copy_proc;
    }
}

Scene :: struct($TEntity: Type, capacity : u32 = DEF_SCENE_CAPACITY ) {
    CAPACITY :: capacity;
    entities     : [] TEntity;
    slot         : u32;
    count        : int;
    used_ids     : Sparse_Set;
    free_ids     : Queue(Entity_ID);
    to_clean     : Table(Entity_ID, struct{});
    type         : *Type_Info_Struct;
    tag_to_id    : Table(string, Entity_ID);
    entity_procs : Entity_Procs;
}

#add_context scenes: [MAX_SCENES] *Scene(Entity);

initialized :: (scene : Scene) -> bool {
    return scene.type != null;
}

init :: (scene          : *Scene($TEntity), 
         slot           : u32, 
         init_proc      : Entity_Procs.INIT   = null,
         deinit_proc    : Entity_Procs.DEINIT = null,
         copy_proc      : Entity_Procs.COPY  = null) 
{
    #assert(is_subclass_of_entity(TEntity));
    assert(!initialized(scene));
    add_scene(xx scene, slot);
    scene.type = type_info(TEntity);
    scene.entities = NewArray(Scene(TEntity).CAPACITY + 1, TEntity);
    init(*scene.used_ids, Scene(TEntity).CAPACITY);
    init(*scene.free_ids, Scene(TEntity).CAPACITY + 1);
    
    for i : 1..Scene(TEntity).CAPACITY push_back(*scene.free_ids, xx i);

    init(TEntity, *scene.entity_procs, init_proc, deinit_proc, copy_proc); 
}

get_entity_at :: (scene : *Scene(Entity), index : int) -> *Entity {
    assert(initialized(scene));
    entity := scene.entity_procs.get_at(scene, index);
    return entity;
}

get_subclassed_entity_at :: (scene : *Scene($TEntity), index : int) -> *TEntity {
    #assert(is_subclass_of_entity(TEntity));
    assert(initialized(scene));
    return *scene.entities[index];
}

clean_destroyed_entities :: (scene : *Scene(Entity)) {
    for _, id : scene.to_clean {
        index := search(*scene.used_ids, id);
        assert(index != 0);
        entity := get_entity_at(scene, index);
        scene.entity_procs.destroy(entity, recursive = false);
    }
    table_reset(*scene.to_clean);
}

deinit :: (scene : *Scene($TEntity)) {
    #assert(is_subclass_of_entity(TEntity));

    for i : 1..scene.count {
        e := (*scene.entities[i]).(*Entity2D);
        destroy_entity(e);
    }
    
    clean_destroyed_entities(xx scene);
    
    remove_scene(scene.slot);
    deinit(*scene.used_ids);
    deinit(*scene.free_ids);
    deinit(*scene.tag_to_id);
    deinit(*scene.to_clean);
    array_free(scene.entities);
    scene.* = .{};
}

clean_destroyed_entities :: () {
    for scene : context.scenes {
        if !scene continue;
        clean_destroyed_entities(scene);
    }
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
    return xx scene;
}

add_scene :: (scene : *Scene(Entity), slot : u32) {
    assert(scene != null);
    assert(context.scenes[slot] == null);
    context.scenes[slot] = scene;
    scene.slot = slot;
}

remove_scene :: (slot : u32) {
    current := get_scene(slot);
    context.scenes[slot] = null;
}