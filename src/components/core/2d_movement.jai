Interp_Mode :: enum {
    NONE;
    EASE_IN_EXPO;
}

INTERP_PROC :: #type (x: f32, min: f32, max: f32) -> float;

Movement2D_Component :: struct @Component @InitOrder(100) {
    interp_mode        : Interp_Mode;
    start              : bool;
    speed_min          : f32;
    speed_max          : f32  = 8;
    time_to_max_speed  : f32  = 0.7;
    speed_progress     : f32;
    target             : Vector2;
    has_target         : bool = true;
    dir                : Vector2;
    interp_proc        : INTERP_PROC; @JsonIgnore
}

move_entity :: (entity : Entity) {
    
    using transform  := get_component(Transform2D_Component, entity);
    using movement2d := get_component(Movement2D_Component,  entity);

    if interp_mode == {
        case .NONE;         interp_proc = linear_interp;
        case .EASE_IN_EXPO; interp_proc = ease_in_expo_interp;
    }

    assert(interp_proc != null);

    if !start {
        return;
    }
    
    speed := ifx time_to_max_speed > 0 {
        speed_progress += delta_seconds();
        speed_progress = clamp(speed_progress, 0.0, time_to_max_speed);
        norm_speed_progress := speed_progress / time_to_max_speed;
        interp_proc(norm_speed_progress, speed_min, speed_max);
    } else {
        speed_max;
    }
    
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

move_entities :: () {
    view := get_entity_view(Transform2D_Component, Movement2D_Component);
    for view {
        move_entity(it);
    }
}