init_entities2d :: () {
    if !is_init(*sheet)
    then init(*sheet);
}

deinit_entities2d :: () {
    if is_init(*sheet)
    then deinit(*sheet);
}

draw_entities2d :: (window_width : s32, window_height : s32) {
    draw2d_begin(.{window_width, window_height});
    view := get_entity_view(Transform2D_Component, Sprite_Component);
    for entity : view {
        draw_sprite_entity(entity, *sheet);
    }
    draw2d_end();
}

#scope_file

sheet : Spritesheet;