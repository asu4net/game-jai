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
        last_time = get_time();
        acc_fixed_delta = fixed_delta_seconds;
        seconds = 0;
    }

    current_time : = get_time();
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

get_time :: () -> float64 {
    one_time_init(*is_get_seconds_initialized, init_get_seconds());
    delta := current_time_monotonic() - get_seconds_base_time;
    return to_float64_seconds(delta);
}

#scope_module

#import "Math";
#import "Basic";

is_get_seconds_initialized: s32;
get_seconds_base_time: Apollo_Time;

init_get_seconds :: () {
    get_seconds_base_time = current_time_monotonic();
}