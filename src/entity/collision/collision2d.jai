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

operator == :: (a : CollisionEventEnter, b : CollisionEventEnter) -> bool {
    return compare_entity_ref(a.source, b.source) && compare_entity_ref(a.target, b.target);
}

CollisionEventExit :: struct {
    source : Entity_Ref;
    target : Entity_Ref;
}


CollisionsMap :: Table(Entity_Ref, Entity_Ref_Set, hash_entity_ref, compare_entity_ref);

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

    #if DEBUG then tint : Vector4; @JsonIgnore
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
    return scene.entities.data != null;
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

query_collisions2d :: () {
    using context.collisions2d;

    array_reset(*collision_enter_events);
    array_reset(*collision_exit_events);
    
    prev_collisions : [..] CollisionEventEnter;
    array_resize(*prev_collisions, collisions_in_last_frame.count);
    defer array_free(prev_collisions);

    array_copy(*prev_collisions, collisions_in_last_frame);
    array_reset(*collisions_in_last_frame);

    for i : 1..scene.count {
        
        entity_A := scene.entities[i];
        if !should_update(entity_A) {
            continue;
        }
        for j : (i + 1)..scene.count {
            entity_B := scene.entities[i];
            if !should_update(entity_B) {
                continue;
            }
            handle_collision_enter(*entity_A, *entity_B);
            handle_collision_enter(*entity_B, *entity_A);
        } 
    }

    // Collision exit handle
    for prev_collision : prev_collisions {
        found : bool;
        for curr_collision : collisions_in_last_frame {
            if prev_collision == curr_collision {
                found = true;
                break;
            }
        }
        
        if found continue;

        exit_event : CollisionEventExit = .{
            source = prev_collision.source,
            target = prev_collision.target,
        };
        array_add(*collision_exit_events, exit_event);
        entity_set, table_found := table_find(*collisions_map, exit_event.source);
        assert(table_found);
        table_remove(*entity_set, exit_event.target);
    }
}

circle_collides :: (entity_A : *Collider2D, entity_B : *Collider2D) -> bool {
    radius_sum := entity_A.radius + entity_B.radius;
    parent_A := (resolve_ref(*entity_A.parent)).(*Entity2D);
    parent_B := (resolve_ref(*entity_B.parent)).(*Entity2D);
    return length(parent_A.pos - parent_B.pos) <= radius_sum * radius_sum;
}

handle_collision_enter :: (entity_A : *Collider2D, entity_B : *Collider2D) {
    
    using context.collisions2d;

    if(entity_B.source_flag & entity_A.target_flags) {
        
        if !table_contains(*collisions_map, make_ref(entity_A)) {
            table_add(*collisions_map, make_ref(entity_A), Entity_Ref_Set.{});
        }

        if(circle_collides(entity_A, entity_B)) {
            
            collision_enter_event : CollisionEventEnter = .{ make_ref(entity_A), make_ref(entity_B) };
            array_add(*collisions_in_last_frame, collision_enter_event);

            if !table_contains(*collisions_map, make_ref(entity_B)) {
                array_add(*collision_enter_events, collision_enter_event);
                A_collides_width, found := table_find(*collisions_map, make_ref(entity_A));
                table_set(*A_collides_width, make_ref(entity_B), .{});
            }
        }
    }
}