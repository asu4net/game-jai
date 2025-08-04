MAX_PLAYERS              :: 2;
PLAYER_BULLET_LV1_DAMAGE :: 10;
PLAYER_BULLET_LV1_SPEED  :: 8.0;
PLAYER_BULLET_LV1_RADIUS :: 0.1;
MAX_BULLETS              :: 200;

bullet_pool      : Entity_Pool(MAX_BULLETS);

// TODO: 
// bullet pool 
// minions
// ammo stuff (included in minions ig)
// collision stuff 
// life (is that included in collision stuff?)

Player_Movement :: struct @Component @InitOrder(1000) @Max(2) {
    speed : f32 = 4.0;
    // minion stuff if that time comes
}

Player_Weapon :: struct @Component @InitOrder(1000) @Max(2) {
    firerate         : f32 = 0.1;
    time_since_fired : f32 = 0.0;
    level            : u8  = 1;
    ammo             : u32 = 0;
}

Player_Input :: struct @Component @InitOrder(1000) @Max(2)  {
    axis               : Vector2;
    fire               : bool;
}

init_player :: (player : Entity) {
    init_entity_pool(*bullet_pool, "assets/player_bullet.prefab");
}

update_player :: (player : Entity) {
    
    player_input     := get_component(Player_Input,  player);
    update_input(player_input);

    update_movement(player);
    update_weapons(player);
}

deinit_player :: (player : Entity) { 
    deinit_entity_pool(*bullet_pool);
}

update_input :: (using player_input : *Player_Input) {

    if is_key_down(.W) {
        axis.y = 1;
    } else if is_key_down(.S) {
        axis.y = -1;
    } else {
        axis.y = 0;
    }

    if is_key_down(.A) {
        axis.x = -1;
    } else if is_key_down(.D) {
        axis.x = 1;
    } else {
        axis.x = 0;
    }

    if axis.x != 0 && axis.y != 0 {
        axis = normalize(axis);
    }

    fire = is_key_down(.SPACE);
}

update_movement :: (player : Entity) {
    
    using transform2d     := get_component(Transform2D_Component, player);
    using player_input    := get_component(Player_Input, player);
    using player_movement := get_component(Player_Movement, player);
    pos += axis * speed * delta_seconds();
}

update_weapons :: (player : Entity) {

    if !has_component(Transform2D_Component, player) || !has_component(Player_Input, player) || !has_component(Player_Weapon, player) {
        return;
    }
    using transform2d   := get_component(Transform2D_Component, player);
    using player_input  := get_component(Player_Input, player);
    using player_weapon := get_component(Player_Weapon, player);


    time_since_fired += delta_seconds();
    if (fire && time_since_fired >= firerate) {
        if (level == 1) {
            fire_projectile(pos, UP_2D, PLAYER_BULLET_LV1_DAMAGE, PLAYER_BULLET_LV1_SPEED, PLAYER_BULLET_LV1_RADIUS);
        }
        else if (level == 2 || level == 3) {
            fire_projectile(.{ pos.x - 0.1, pos.y }, UP_2D, PLAYER_BULLET_LV1_DAMAGE, PLAYER_BULLET_LV1_SPEED, PLAYER_BULLET_LV1_RADIUS);
            fire_projectile(.{ pos.x + 0.1, pos.y }, UP_2D, PLAYER_BULLET_LV1_DAMAGE, PLAYER_BULLET_LV1_SPEED, PLAYER_BULLET_LV1_RADIUS);
        }
        time_since_fired = 0;
    }
}

fire_projectile :: (pos : Vector2, dir : Vector2, damage : u32, speed : f32, radius : f32) {

    bullet      := get_pool_element(*bullet_pool);
    transform2d := get_component(Transform2D_Component, bullet);
    movement2d  := get_component(Movement2D_Component, bullet);

    transform2d.pos  = pos; 
    movement2d.dir   = dir;
    movement2d.start = true; 

    start_timer_component(bullet, on_bullet_timer_finished);

    set_enabled(bullet, true);

    /*
    bullet := dlz_entity_from_file("assets/player_bullet.prefab");
    set_pos(bullet, get_pos(get_player()));
    get_component(Timer_Component, bullet).on_end_cbk = (entity : Entity) {
        destroy_entity(entity);
    };
    */
}

Player_Bullet_Component :: struct @Component {
}

process_bullet_collisions :: () {
    using context.collisions2d;
    for collision_enter_events {
        source := resolve_ref(*it.source); 
        success := return_pool_element(*bullet_pool, source);     
        if success
        then set_enabled(source, false);
    }
}

on_bullet_timer_finished :: (bullet : Entity) {
    
    set_enabled(bullet, false);
    return_pool_element(*bullet_pool, bullet);
}

process_player_damage :: () {
    for context.damage_registry.damage_events {
        entity := resolve_ref(*it.target);
        if entity != get_player()
        then continue;
        target := get_component(Damage_Target, resolve_ref(*it.target));
        if target.life <= 0 {
            //#TODO_asuarez Placeholder
            deinit_game();
        }
        break;
    }
    process_bullet_collisions();
}