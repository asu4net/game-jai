Entity2D :: struct {
    #as using entity : Entity;
    using transform : Transform2D;
    sprite : Sprite;
    vfx : VFX2D;
}

GUIText :: struct {
    #as using entity : Entity;
    using transform : Transform2D;
    text : Text;
}

#add_context logic2d : Logic2D;

Logic2D :: struct {
    entities2d : Scene(Entity2D);
    gui_texts  : Scene(GUIText);
    sheet : Spritesheet;
    font  : Font;
}

init_logic2d :: () {
    using context.logic2d;
    init(*sheet);
    init(*font);
    init(*entities2d, xx Scenes.ENTITIES_2D);
    init(*gui_texts, xx Scenes.GUI_TEXTS);
}

deinit_logic2d :: () {
    using context.logic2d;
    deinit(*sheet);
    deinit(*font);
    deinit(*entities2d);
    deinit(*gui_texts);
    context.logic2d = .{};
}

draw_logic2d :: () {
    using context.logic2d;
    
    for i : 1..entities2d.count {
        e := *entities2d.entities[i];
        if should_update(e) {
            update_vfx(*e.vfx, *e.sprite.tint);
            draw_sprite(*e.transform, *e.sprite, *sheet, e.id);
        }
    }

    for i : 1..gui_texts.count {
        e := *gui_texts.entities[i];
        if should_update(e) {
            draw_text(*e.transform, *e.text, *font, e.id);
        }
    }


}