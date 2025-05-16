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
    for entity : view {
        draw_sprite_entity(entity, *sheet);
    }
    Graphics.draw2d_end();
}

#scope_file

#import "File";
#import "Math";

Graphics :: #import "Graphics" (DUMP_ERRORS = true);
Window   :: #import "Window_Creation" (DUMP_GL_ERRORS = DEBUG, CLOSE_WITH_SCAPE = EDITOR);


sheet : Graphics.Spritesheet;