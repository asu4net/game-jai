Damage_Source :: struct @Component {
    damage: u32 = 10;    
}

Damage_Target :: struct @Component {
    max_life: u32 = 100;
    life: s32 = 0;
}

on_damage_target_added :: (entity : Entity, dmg_target : *Damage_Target) {
    if dmg_target.life != 0 
    then return;
    dmg_target.life = xx dmg_target.max_life; 
} @addcomponentcallback

Damage_Event :: struct {
    source: Entity_Ref;
    target: Entity_Ref;
    damage: u32;
}

Damage_Registry :: struct {
    damage_events : [..] Damage_Event;
}

#add_context damage_registry : *Damage_Registry;

init_damage_registry :: () {
    if context.damage_registry != null
    then deinit_damage_registry();
    damage_registry := New(Damage_Registry);
    context.damage_registry = damage_registry;
}

deinit_damage_registry :: () {
    array_reset(*context.damage_registry.damage_events);
    free(context.damage_registry);
    context.damage_registry = null;
}

reset_life :: (entity : Entity) -> bool {
    if !has_component(Damage_Target, entity) {
        return false;
    }
    dmg_target := get_component(Damage_Target, entity);
    dmg_target.life = xx dmg_target.max_life;
    return true; 
}

query_damage_collisions :: () {
    using context.collisions2d;
    using context.damage_registry;
    array_reset_keeping_memory(*damage_events);
    for collision_enter_events {
        source := resolve_ref(*it.source); 
        target := resolve_ref(*it.target); 
        if has_component(Damage_Target, target) && has_component(Damage_Source, source) {
            event : Damage_Event;
            if is_not_destroyed(source) && is_not_destroyed(target) {
                dmg_target := get_component(Damage_Target, target);
                dmg_source := get_component(Damage_Source, source);
                dmg_target.life -= xx dmg_source.damage;
                event.damage = dmg_source.damage;
            }
            event.source = it.source;
            event.target = it.target;
            array_add(*damage_events, event);
        } 
    }
}