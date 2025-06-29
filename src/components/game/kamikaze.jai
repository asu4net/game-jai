KamikazeState :: enum u32{
    IDLE;
    ATTACK;
}

Kamikaze_Skull :: struct @Component @InitOrder(1000) @Max(MAX_PLAYERS) {
    state         : KamikazeState = .IDLE;
    idle_time     : f32;
    attack_target : v3;
    attack_cd     : f32;
}

kamikaze_update :: (kamikaze : Entity) {
    using kamikaze_skull := get_component(Kamikaze_Skull, kamikaze);
    using movement := get_component(Movement2D_Component, kamikaze);
    using transform := get_component(Transform2D_Component, kamikaze);

    if state == {
        case .IDLE;
            idle_time += Time.delta_seconds();
            if idle_time > attack_cd then {
                idle_time = 0;
                state = .ATTACK;
            }
        case .ATTACK;
            target.x = -1;
            target.y = -0.4;
            has_target = true;
            start = true;
            if pos == target then state = .IDLE;

    }
}
