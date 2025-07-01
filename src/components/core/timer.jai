ON_TIMER_FINISHED_CBK :: #type (Entity);

Timer_Component :: struct @Component @InitOrder(1000) @Max(MAX_ENTITIES) {
    started                : bool = false;
    time_to_uuuh_something : f32;
    current_time           : f32  = 0;
    on_timer_finished_cbk  : ON_TIMER_FINISHED_CBK; @JsonIgnore @EditorIgnore
}

// not init
start_timer_component :: (entity : Entity, finished_cbk : ON_TIMER_FINISHED_CBK) {

    using timer := get_component(Timer_Component, entity);
    started               = true;
    current_time          = 0;
    on_timer_finished_cbk = finished_cbk;
}

update_timer_component :: (entity : Entity) {

    using timer  := get_component(Timer_Component, entity);

    if (!started) { return; }

    current_time += Time.delta_seconds();
    if (current_time > time_to_uuuh_something) {
        started = false;
        on_timer_finished_cbk(entity);
    }
}
