HomingState :: enum {
    IDLE;
    WAITING;
    ATTACK;
}

HomingMissile :: struct {
    state              : HomingState;
    attack_dir         : v3;
    wait_timer         : f32;

    distance_to_attack : f32 = 2;
    wait_time          : f32 = 0.5; 
    blink_time         : f32 = 0.5; 
    approach_speed     : f32 = 2; 
    attack_speed       : f32 = 4;
    line_start_color   : v4  = RED;
    line_end_color     : v4  = WHITE;
}

homing_missile_prefab  : Entity_Handle;
homing_missile_spawner : Spawner; 

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



update_homing_missile :: (entity : Entity) {

        player_position := entity_data(game.player.entity).position;

        pointer_data : ^Entity = nil;
        if len(children) > 0 && entity_valid(children[0]) { 
            pointer_data = entity_data(children[0]);
            pointer_data.pointer_line.dir = -UP_3D;
        }
        
        switch homing_missile.state {
            case HomingState.IDLE: {
                movement_2d.start = true;
                movement_2d.target = entity_data(game.player.entity).position;
                
                dir := player_position - position;
                distance : f32 = linalg.vector_length(dir);
                angle := -math.to_degrees(linalg.atan2(dir.y, dir.x)) - 90;
                
                rotation.z = angle;
                if distance <= homing_missile.distance_to_attack { 
                    homing_missile.state = HomingState.WAITING;
                }

                if entity_valid(children[0]) {
                    pointer_data.scale.x = distance;
                }
            }
            case HomingState.WAITING: {
                movement_2d.start = false;

                dir := player_position - position;
                angle := -math.to_degrees(linalg.atan2(dir.y, dir.x)) - 90;
                rotation.z = angle;
                
                homing_missile.wait_timer += delta_seconds();
                if homing_missile.wait_timer >= homing_missile.wait_time {
                    homing_missile.attack_dir = linalg.vector_normalize(player_position - transform.position);
                    homing_missile.state = HomingState.ATTACK;
                }
                
                if entity_valid(children[0]) {
                    distance : f32 = linalg.vector_length(dir);
                    
                    pointer_data.scale.x       = distance;
                    pointer_data.tint          = color.RED;
                    pointer_data.blink.enabled = false;
                }
                
            }
            case HomingState.ATTACK: {
                position += homing_missile.attack_dir * homing_missile.attack_speed * delta_seconds();

                if entity_valid(children[0]) {
                    pointer_data.scale.x       = 1000;
                    pointer_data.tint          = color.RED;
                    pointer_data.blink.enabled = false;
                }
            }
    }
}