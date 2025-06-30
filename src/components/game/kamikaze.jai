KamikazeState :: enum u32{
    IDLE;
    ATTACK;
}

Kamikaze_Skull :: struct @Component @InitOrder(1000) @Max(MAX_PLAYERS) {
    state         : KamikazeState = .IDLE;
    idle_time     : f32;
    attack_target : v3;
    attack_cd     : f32;
    saw_speed     : f32;
}

update_kamikaze :: (kamikaze : Entity) {
    using kamikaze_skull := get_component(Kamikaze_Skull, kamikaze);
    using movement := get_component(Movement2D_Component, kamikaze);
    using transform := get_component(Transform2D_Component, kamikaze);
    
    
    if get_child_at(kamikaze, 0) != NULL_ENTITY {
        saw_transform := get_component(Transform2D_Component, get_child_at(kamikaze, 0));
        saw_transform.ang += Time.delta_seconds() * saw_speed * 100;
        if saw_transform.ang > 360 then saw_transform.ang = 0;
    }
    

    if state == {
        case .IDLE;
            idle_time += Time.delta_seconds();
            if idle_time > attack_cd then {
                idle_time = 0;
                target = get_player_pos();
                state = .ATTACK;
            }
        case .ATTACK;
            has_target = true;
            start = true;
            if pos == target then state = .IDLE;

    }
}

get_player_pos :: () -> v2 {
    view := get_entity_view(Player_Input);
    for view {
        return get_component(Transform2D_Component, it).pos;
    }
    return ZERO_2D;
}
