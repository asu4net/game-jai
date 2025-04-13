VFX2D :: struct {
    blink : Blink;     
}

Blink :: struct {
    enabled    : bool;
    start_tint : v4; @Color
    end_tint   : v4 = RED; @Color
    duration   : f32 = 0.5;
    progress   : f32;
}

update_vfx :: (vfx : *VFX2D, tint : *v4) {

    // Blink
    {
        using vfx.blink;

        if enabled && tint {

            progress += delta_seconds();
            progress = clamp(progress, 0.0, duration);
            normalized_progress := progress / duration;
            tint.* = linear_interp(normalized_progress, start_tint, end_tint); 
            
            if normalized_progress == 1 {
                
                new_target := start_tint;
                start_tint = end_tint;
                end_tint   = new_target;
                progress   = 0;
            }
        }      
    }
}