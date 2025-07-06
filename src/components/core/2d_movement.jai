Movement2D_Component :: struct @Component @InitOrder(100) @Max(MAX_ENTITIES) {
    start              : bool;
    speed_min          : f32;
    speed_max          : f32  = 8;
    time_to_max_speed  : f32  = 0.7;
    speed_progress     : f32;
    target             : Vector2;
    has_target         : bool = true;

    // direction used if there's no target
    dir     : v2;
}

move_entity :: (entity : Entity) {
    
    using transform  := get_component(Transform2D_Component, entity);
    using movement2d := get_component(Movement2D_Component,  entity);

    if !start {
        return;
    }
    
    speed_progress += delta_seconds();
    speed_progress = clamp(speed_progress, 0.0, time_to_max_speed);
    norm_speed_progress := speed_progress / time_to_max_speed;
    speed :=  ease_in_expo_interp(norm_speed_progress, speed_min, speed_max);
    delta_traslation := speed * delta_seconds();

    if has_target {
        distance_sqrd := distance_squared(target, transform.pos);

        if delta_traslation * delta_traslation >= distance_sqrd {
            transform.pos = target;
        } else {
            dir = normalize(target - transform.pos);
            transform.pos += dir * delta_traslation;
        }
        
        if transform.pos == target {
            speed_progress = 0;
            speed = 0;
            start = false;
        }
    } else {
        transform.pos += dir * delta_traslation;
    }
    
}