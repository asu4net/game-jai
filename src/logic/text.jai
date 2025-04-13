Text :: struct {
    visible : bool   = true;
    text    : string = "placeholder!";
    blend   : Blend  = .ALPHA;
    tint    : v4     = WHITE; @Color
}

draw_text :: (using transform : Transform2D, using t : Text, font : *Font, id : u32 = 0) {
    
    if !visible then return;
    draw_gui_text(pos, ang, scl, text, font, blend, tint, id); 
}