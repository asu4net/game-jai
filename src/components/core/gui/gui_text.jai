GUI_Text_Component :: struct @Component {
    visible := true;
    text    := "";
    blend   := Blend.ALPHA;
    tint    := WHITE; @Color
}

on_cpy_gui_text_component :: (entity : Entity, s : *GUI_Text_Component, d : *GUI_Text_Component) {
   d.* = s.*;
   d.text = copy_string(s.text);
} @CopyComponentCallback

on_rem_gui_text_component :: (entity : Entity, c : *GUI_Text_Component) {
    free(c.text);
} @RemoveComponentCallback

draw_text_entity :: (entity : Entity, font : *Font, id : u32 = 0) {    
    using t := get_component(GUI_Text_Component, entity);
    using transform := get_component(Transform2D_Component, entity);
    if !visible then return;
    draw_gui_text(pos, ang, scl, text, font, blend, tint, id); 
}