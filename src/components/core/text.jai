Text_Component :: struct @Component @InitOrder(2000) @Max(MAX_ENTITIES) {
    visible := true;
    text    := "placeholder!";
    blend   := Graphics.Blend.ALPHA;
    tint    := WHITE;          @Color
}

draw_text :: (using transform : Transform2D_Component, using t : Text_Component, font : *Graphics.Font, id : u32 = 0) {    
    if !visible then return;
    Graphics.draw_gui_text(pos, ang, scl, text, font, blend, tint, id); 
}

#scope_file