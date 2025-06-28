MAX_PLAYERS              :: 2;
PLAYER_BULLET_LV1_DAMAGE :: 10;
PLAYER_BULLET_LV1_SPEED  :: 8.0;
PLAYER_BULLET_LV1_RADIUS :: 0.1;


Player_Movement :: struct @Component @InitOrder(1000) @Max(MAX_PLAYERS) {
    speed : f32 = 4.0;
    // minion stuff if that time comes
}

Player_Weapon :: struct @Component @InitOrder(1000) @Max(MAX_PLAYERS) {
    firerate         : f32 = 0.1;
    time_since_fired : f32 = 0.0;
    level            : u8  = 1;
    ammo             : u32 = 0;
}

Player_Input :: struct @Component @InitOrder(1000) @Max(MAX_PLAYERS)  {
    axis               : v2;
    fire               : bool;
}

player_update :: (player : Entity) {
    
    player_input     := get_component(Player_Input,  player);
    input_update(player_input);

    movement_update(player);
    weapons_update(player);
}

input_update :: (using player_input : *Player_Input) {

    if Input.is_key_down(#char "W") {
        axis.y = 1;
    } else if Input.is_key_down(#char "S") {
        axis.y = -1;
    } else {
        axis.y = 0;
    }

    if Input.is_key_down(#char "A") {
        axis.x = -1;
    } else if Input.is_key_down(#char "D") {
        axis.x = 1;
    } else {
        axis.x = 0;
    }

    if axis.x != 0 && axis.y != 0 {
        axis = normalize(axis);
    }

    fire = Input.is_key_down(.BACKSPACE);
}

movement_update :: (player : Entity) {
    
    using transform2d     := get_component(Transform2D_Component, player);
    using player_input    := get_component(Player_Input, player);
    using player_movement := get_component(Player_Movement, player);
    pos += axis * speed * Time.delta_seconds();
}

weapons_update :: (player : Entity) {

    using transform2d     := get_component(Transform2D_Component, player);
    using player_input    := get_component(Player_Input, player);
    using player_weapon   := get_component(Player_Weapon, player);

    time_since_fired += Time.delta_seconds();
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

    log("Beep, firing bullet, remember to make that bullet pool, beep");
}