CollisionFlag :: enum_flags u16 {
    NONE;
    PLAYER;
    PLAYER_PROJECTILE;
    ENEMY;
    ENEMY_PROJECTILE;
}

CollisionEventEnter :: struct {
    source : Entity_Ref;
    target : Entity_Ref;
}

CollisionEventExit :: struct {
    source : Entity_Ref;
    target : Entity_Ref;
}

CollisionsMap :: Table(Entity_Ref, Table(Entity_Ref, struct{}, hash_entity_ref, compare_entity_ref), hash_entity_ref, compare_entity_ref);

Collisions2D :: struct {
    scene                    : Scene(Collider2D);
    collisions_in_last_frame : [..] CollisionEventEnter;
    collision_enter_events   : [..] CollisionEventEnter;
    collision_exit_events    : [..] CollisionEventExit;
    collisions_map           : CollisionsMap;
}

Collider2D :: struct {
    #as using entity : Entity;
    source_flag  : CollisionFlag;
    target_flags : CollisionFlag;
    radius       : float32;

    #if DEBUG then tint : Vector4;
}

init_collider_2d :: (e : *Entity) {
    assert(e != null);
    using collider := e.(*Collider2D);
    radius = 0.5;
    #if DEBUG then tint = LIGHT_GREEN;
}

#add_context collisions2d : Collisions2D;

collisions2d_initialized :: () -> bool {
    using context.collisions2d;
    return initialized(scene);
}

init_collisions2d :: () {
    using context.collisions2d;
    assert(!collisions2d_initialized());
    init(*scene, xx Scenes.COLLISIONS_2D);
}

deinit_collisions2d :: () {
    using context.collisions2d;
    assert(collisions2d_initialized());
    array_reset(*collision_enter_events);
    array_reset(*collision_exit_events);
    array_reset(*collisions_in_last_frame);
    
    for entity_set, _: collisions_map {
        deinit(*entity_set);    
    }

    deinit(*scene);
    context.collisions2d = .{};
}