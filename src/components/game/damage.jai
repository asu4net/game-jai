
DamageSource_Component :: struct @Component @InitOrder(1000) @Max(MAX_ENTITIES)  {
    damage  : u32 = 10;
}

DamageTarget_Component :: struct @Component @InitOrder(1000) @Max(MAX_ENTITIES)  {
    max_life : u32 = 100;
    life     : u32 = 100;
}

damage_collision :: (source : Entity, target : Entity) {
    if (!has_component(DamageSource_Component, source) || !has_component(DamageTarget_Component, target)) return;
    using damage_source := get_component(DamageSource_Component, source);
    using damage_target := get_component(DamageTarget_Component, target);

    if (has_component(Player_Input, target)) {
        player_damage_collision(target, source);
        return;
    }

    life = clamp(life - damage, 0, max_life);

    if life == 0 {
        //TODO: this a placeholder, should send dead event
        
        /*
        spawn_ammo({target.position.x + 0.1, target.position.y - 0.05, target.position.z});
        spawn_ammo({target.position.x - 0.1, target.position.y - 0.05, target.position.z});
        spawn_ammo({target.position.x,       target.position.y + 0.05, target.position.z});
        */
        destroy_entity(target);
        log("Oh no! Rip me!");
    }
}