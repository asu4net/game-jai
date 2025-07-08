ON_END_CBK :: #type (Entity);

Timer_Component :: struct @Component @InitOrder(1000) @Max(MAX_ENTITIES) {
    started      : bool = false;
    time         : f32;
    current_time : f32  = 0; @JsonIgnore
    on_end_cbk   : ON_END_CBK; @JsonIgnore @EditorIgnore
}

// not init
start_timer_component :: (entity : Entity, finished_cbk : ON_END_CBK) {

    using timer := get_component(Timer_Component, entity);
    started               = true;
    current_time          = 0;
    on_end_cbk = finished_cbk;
}

update_timer_component :: (entity : Entity) {

    using timer  := get_component(Timer_Component, entity);

    if (!started) { return; }

    current_time += delta_seconds();
    if (current_time > time) {
        started = false;
        on_end_cbk(entity);
    }
}