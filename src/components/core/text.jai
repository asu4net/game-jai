Text_Component :: struct @Component @InitOrder(2000)  {
    visible := true;
    text    := "placeholder!";
    blend   := Blend.ALPHA;
    tint    := WHITE; @Color
}

draw_text :: (using transform : Transform2D_Component, using t : Text_Component, font : *Font, id : u32 = 0) {    
    if !visible then return;
    draw_gui_text(pos, ang, scl, text, font, blend, tint, id); 
}

#scope_file