init_entities2d :: () {
    if !Graphics.is_init(*sheet)
    then Graphics.init(*sheet);
}

deinit_entities2d :: () {
    if Graphics.is_init(*sheet)
    then Graphics.deinit(*sheet);
}

draw_entities2d :: () {
    Graphics.draw2d_begin(.{context.window.width, context.window.height});
    view := get_entity_view(Transform2D_Component, Sprite_Component);
    for view draw_sprite_entity(it, *sheet);
    Graphics.draw2d_end();
}

#scope_file

sheet : Graphics.Spritesheet;