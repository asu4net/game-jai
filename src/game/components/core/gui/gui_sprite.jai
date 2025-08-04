GUI_Sprite_Component :: struct @Component {
    visible  := true;
    image    := Atlas_Image.COUNT;
    tint     := WHITE;       @Color
    size     := ONE_2D;
    tiling   := ONE_2D;
    blend    := Blend.ALPHA;
    flip_x   := false;
    flip_y   := false;
    autosize := true;
    rect     := Rect.{};     @JsonIgnore @EditorReadOnly 
}

draw_gui_sprite_entity :: (entity : Entity) {

    using transform := get_component(Transform2D_Component, entity);
    using sprite    := get_component(GUI_Sprite_Component, entity);
    
    if !visible then return;

    if has_component(Blink_Component, entity)
    then update_blink(get_component(Blink_Component, entity), *tint);
    
    flags: GUIQuadFlag;
    if image != .COUNT then flags |= GUIQuadFlag.USE_SUBTEX;
    if flip_x          then flags |= .FLIP_X;
    if flip_y          then flags |= .FLIP_Y;

    draw_atlas_gui_quad(get_matrix(entity), image, tiling, size, blend, tint, entity, flags);
}