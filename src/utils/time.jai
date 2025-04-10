Time :: struct {
    max_delta_time      : f64;
    fixed_delta_seconds : f64;
    delta_seconds       : f32;
    seconds             : f64;
    frame_count         : u32;
    acc_fixed_delta     : f64;
    last_time           : f64;
    fixed_update_calls  : u32;
    scale               : f32;
}