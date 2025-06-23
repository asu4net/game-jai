CollisionFlag :: enum_flags u16 {
    NONE;
    PLAYER;
    PLAYER_BULLET;
    ENEMY;
    ENEMY_BULLET;
    PICK_UP;
}

CollisionEventEnter :: struct {
    source : Entity_Ref;
    target : Entity_Ref;
}

CollisionEventExit :: struct {
    source : Entity_Ref;
    target : Entity_Ref;
}

Collisions2D :: struct {
    collisions_in_last_frame : [..] CollisionEventEnter;
    collision_enter_events   : [..] CollisionEventEnter;
    collision_exit_events    : [..] CollisionEventExit;
    collisions_map           : Table(Entity_Ref, Table(Entity_Ref, struct{}));
}

#add_context collisions2d : Collisions2D;

Collider2D_Component :: struct @Component @InitOrder(500) {
    collision_flag   : CollisionFlag;
    collides_with    : CollisionFlag;
    collision_radius : f32;
    collision_tint   : v4;
}



/* 

finish :: (using instance : *Collisions2D) {
    
    array_reset(*collision_enter_events);
    delete(collision_enter_events)
    delete(collision_exit_events)
    
    for _, entity_set in collisions_map {
        delete(entity_set)
    }

    delete(collisions_map)
    delete(collisions_in_last_frame)
}

query_2d_collisions :: () {

    using collisions_2d_instance

    clear(&collision_enter_events)
    clear(&collision_exit_events)
    
    prev_collisions := make([dynamic] CollisionEventEnter, len(collisions_in_last_frame))
    defer delete(prev_collisions)

    copy(prev_collisions[:], collisions_in_last_frame[:])
    clear(&collisions_in_last_frame)

    for i in 0..< entity_count() {
        entity_A := entity_at_index(i);
        if !entity_enabled({entity_A.id}) || !is_collider(entity_A) {
            continue;
        }
        for j in (i + 1) ..< entity_count() {
            entity_B := entity_at_index(j);
            if !entity_enabled({entity_B.id}) || !is_collider(entity_B) {
                continue;
            }
            handle_collision_enter(entity_A, entity_B);
            handle_collision_enter(entity_B, entity_A);
        } 
    }

    // Collision exit handle
    for prev_collision in prev_collisions {
        found : bool
        for curr_collision in collisions_in_last_frame {
            if prev_collision == curr_collision {
                found = true
                break
            }
        }
        
        if found do continue

        exit_event : CollisionEventExit = {
            source = prev_collision.source,
            target = prev_collision.target,
        }
        append_elem(&collision_exit_events, exit_event)
        delete_key(&collisions_map[exit_event.source], exit_event.target)
    }
}

circle_collides :: proc(entity_A : ^Entity, entity_B : ^Entity) -> bool {
    radius_sum := entity_A.collision_radius + entity_B.collision_radius;
    return linalg.vector_length2(entity_A.position - entity_B.position) <= radius_sum * radius_sum
}

handle_collision_enter :: proc(entity_A : ^Entity, entity_B : ^Entity) {
    
    using collisions_2d_instance

    entity_handle_A : Entity_Handle = { id = entity_A.id };
    entity_handle_B : Entity_Handle = { id = entity_B.id };
    if(entity_B.collision_flag in entity_A.collides_with) {
        
        if entity_handle_A not_in collisions_map {
            collisions_map[entity_handle_A] = make(map[Entity_Handle]struct{})
        }

        if(circle_collides(entity_A, entity_B)) {
            
            collision_enter_event : CollisionEventEnter = { entity_handle_A, entity_handle_B }
            append_elem(&collisions_in_last_frame, collision_enter_event)

            if(entity_handle_B not_in collisions_map[entity_handle_A]){
                append_elem(&collision_enter_events, collision_enter_event);
                A_collides_width := &collisions_map[entity_handle_A]
                A_collides_width[entity_handle_B] = {}
            }
        }
    }
}
*/