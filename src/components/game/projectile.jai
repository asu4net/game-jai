Projectile_Component :: struct @Component {
}

process_projectile_collisions :: () {
    using context.collisions2d;
    for collision_enter_events {
        source := resolve_ref(*it.source); 
        if is_not_destroyed(source) && has_component(Projectile_Component, source)
        then destroy_entity(source);
    }
}