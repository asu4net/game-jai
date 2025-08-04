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

operator== :: (a : CollisionEventEnter, b : CollisionEventEnter) -> bool {
    return a.source == b.source && a.target == a.target;
}

CollisionEventExit :: struct {
    source : Entity_Ref;
    target : Entity_Ref;
}

CollisionTable :: Table(Entity_Ref, Table(Entity_Ref, struct{}, hash_entity_ref), hash_entity_ref);

Collisions2D :: struct {
    collisions_in_last_frame : [..] CollisionEventEnter;
    collision_enter_events   : [..] CollisionEventEnter;
    collision_exit_events    : [..] CollisionEventExit;
    collisions_table         : CollisionTable;
}

#add_context collisions2d : Collisions2D;

Circle_Collider_Component :: struct @Component @InitOrder(500) {
    radius          : f32;
    flag            : CollisionFlag;
    collides_with   : CollisionFlag;
}

init_collisions2d :: () {

    using context.collisions2d;
    init(*collisions_table);
}

deinit_collisions2d :: () {
    using context.collisions2d;
    array_reset(*collision_enter_events);
    array_reset(*collision_exit_events);

    for table, _ : collisions_table {
        deinit(*table);
    }

    deinit(*collisions_table);
    array_reset(*collisions_in_last_frame);
}

query_2d_collisions :: () {

    using context.collisions2d;

    array_reset_keeping_memory(*collision_enter_events);
    array_reset_keeping_memory(*collision_exit_events);
    
    prev_collisions : [..] CollisionEventEnter;
    array_reserve(*prev_collisions, collisions_in_last_frame.count);
    defer array_reset(*prev_collisions);

    array_copy(*prev_collisions, collisions_in_last_frame);
    array_reset_keeping_memory(*collisions_in_last_frame);

    view := get_entity_view(Transform2D_Component, Circle_Collider_Component);

    for entity_A : view {
        if(!is_enabled(entity_A)) then continue;
        
        for entity_B : view {
            if (!is_enabled(entity_B) || entity_A == entity_B) then continue;

            handle_collision_enter(entity_A, entity_B);
            handle_collision_enter(entity_B, entity_A);
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
        
        if found then continue;

        exit_event : CollisionEventExit = .{
            source = prev_collision.source,
            target = prev_collision.target
        };

        array_add(*collision_exit_events, exit_event);
        table_remove(table_find_pointer(*collisions_table, exit_event.source), exit_event.target);
    }  
}

query_circle_collision :: (entity_A : Entity, entity_B : Entity) -> bool {
    radius_sum := get_component(Circle_Collider_Component, entity_A).radius + get_component(Circle_Collider_Component, entity_B).radius;
    return length_squared(get_pos(entity_A) - get_pos(entity_B)) <= radius_sum * radius_sum;
}

handle_collision_enter :: (entity_A : Entity, entity_B : Entity) {
    
    using context.collisions2d;

    col_A := get_component(Circle_Collider_Component, entity_A);
    col_B := get_component(Circle_Collider_Component, entity_B);

    ref_A := make_ref(entity_A);
    ref_B := make_ref(entity_B);

    if col_A.collides_with & col_B.flag != 0 {
        
        // Not sure if this is required.
        // Ferdom: it is required
        
        if !table_contains(*collisions_table, ref_A) {
            table_add(*collisions_table, ref_A, .{});
        }

        if query_circle_collision(entity_A, entity_B) {
            
            collision_enter_event := CollisionEventEnter.{ ref_A, ref_B };
            array_add(*collisions_in_last_frame, collision_enter_event);

            table_A := table_find_pointer(*collisions_table, ref_A);

            if !table_contains(table_A, ref_B) {
                array_add(*collision_enter_events, collision_enter_event);
                table_add(table_A, ref_B, .{});
            }
            
        }
    }
}

#poke_name (#import "Hash_Table") operator==;