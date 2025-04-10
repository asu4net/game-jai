Time :: struct {
    max_delta_time      : f64 = 0.06;
    fixed_delta_seconds : f64 = 0.06;
    delta_seconds       : f32 = 0;
    seconds             : f64 = -1;
    frame_count         : u32 = 0;
    acc_fixed_delta     : f64 = 0;
    last_time           : f64 = 0;
    fixed_update_calls  : u32 = 0;
    scale               : f32 = 1;
}

#add_context time : Time;

time_step :: () {
    using context.time;
    
    // Init
    if seconds < 0 {
        last_time = xx SDL_GetTicks();
        acc_fixed_delta = fixed_delta_seconds;
    }

    current_time : = SDL_GetTicks().(f64);
    frame_count += 1;
    time_between_frames := current_time - last_time;
    last_time = current_time;
    seconds += time_between_frames;
    delta_seconds = xx clamp(time_between_frames, 0, max_delta_time) * scale;
    acc_fixed_delta += xx delta_seconds;
    
    while acc_fixed_delta >= fixed_delta_seconds {
        acc_fixed_delta -= fixed_delta_seconds;
        fixed_update_calls += 1;
    }
}

delta_seconds :: () -> f32 {
    return context.time.delta_seconds;
}