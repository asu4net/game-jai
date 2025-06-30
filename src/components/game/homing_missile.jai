Homing_Missile_Component :: struct @Component @InitOrder(1100) @Max(MAX_ENTITIES)  {
    State :: enum {
        IDLE;
        WAITING;
        ATTACK;
    }

    state              : State;
    attack_dir         : v2;
    wait_timer         : f32;

    distance_to_attack : f32 = 2;
    wait_time          : f32 = 0.5; 
    blink_time         : f32 = 0.5; 
    approach_speed     : f32 = 2; 
    attack_speed       : f32 = 4;
    line_start_color   : v4  = RED;   @Color
    line_end_color     : v4  = WHITE; @Color
}

/*
homing_missile_init :: () {   
    /*
        sprite.item                   = .Kamikaze_Skull;
        collision_radius              = HOMING_MISSILE_RADIUS;
        movement_2d.speed_min         = HOMING_MISSILE_APPROACH_SPEED;
        movement_2d.speed_max         = HOMING_MISSILE_APPROACH_SPEED;
        movement_2d.time_to_max_speed = 1;
        collision_flag                = CollisionFlag.enemy;
        collides_with                 = { .player, .player_bullet };
        collides_with                 = { .player, .player_bullet };
        damage_target.life            = HOMING_MISSILE_LIFE;
        homing_missile_prefab         = handle;
    */

    /*
        sprite.item         = nil; // appear white
        scale.y             = 0.05;
        tint                = entity.homing_missile.line_start_color
        blink.end_tint      = entity.homing_missile.line_end_color;
        blink.duration      = entity.homing_missile.blink_time;
        blink.enabled       = true;
    */
}
*/

update_homing_missile :: (entity : Entity) {

    homing_missile := get_component(Homing_Missile_Component, entity);
    player_position := get_pos(get_player());

    /*
    pointer_data : ^Entity = nil;
    if children.count > 0 && entity_valid(children[0]) { 
        pointer_data = entity_data(children[0]);
        pointer_data.pointer_line.dir = -UP_3D;
    }
    */
    
    if homing_missile.state == {
        case .IDLE; {
            dir := player_position - get_pos(entity);
            distance : f32 = length(dir);
            angle := -(atan2(dir.y, dir.x) * DEG_PER_RAD) - 90;
            
            set_ang(entity, angle);
            if distance <= homing_missile.distance_to_attack {
                homing_missile.state = .WAITING;
            }
            /*
            if entity_valid(children[0]) {
                pointer_data.scale.x = distance;
            }
            */
        }
        case .WAITING; {
            dir := player_position - get_pos(entity);
            angle := -(atan2(dir.y, dir.x) * DEG_PER_RAD) - 90;
            set_ang(entity, angle);

            homing_missile.wait_timer += Time.delta_seconds();
            if homing_missile.wait_timer >= homing_missile.wait_time {
                homing_missile.attack_dir = normalize(player_position - get_pos(entity));
                homing_missile.state = .ATTACK;
            }
            
            /*
            if entity_valid(children[0]) {
                distance : f32 = linalg.vector_length(dir);
                pointer_data.scale.x = distance;
                pointer_data.tint = .RED;
                pointer_data.blink.enabled = false;
            }
            */
        }
        case .ATTACK; {
            delta_pos := homing_missile.attack_dir * homing_missile.attack_speed * Time.delta_seconds();
            set_pos(entity, get_pos(entity) + delta_pos);
            /*
            if entity_valid(children[0]) {
                pointer_data.scale.x = 1000;
                pointer_data.tint = .RED;
                pointer_data.blink.enabled = false;
            }
            */
        }
    }
}