VFX2D :: struct {
    blink : Blink;     
}

Blink :: struct {
    enabled    : bool;
    start_tint : Vector4;
    end_tint   : Vector4 = RED;
    duration   : f32 = 0.25;
    progress   : f32;
}

update_vfx :: (vfx : *VFX2D, tint : *Vector4) {
    
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