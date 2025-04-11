Entity2D :: struct {
    #as using entity : Entity;
    using transform : Transform2D;
    sprite : Sprite;
    vfx : VFX2D;
}

copy_entity2d :: (dst : *Entity, src : *Entity) {
    d := dst.(*Entity2D); s := src.(*Entity2D);
    base := d.entity;
    d.* = s.*;
    d.sprite.item = copy_string(s.sprite.item);
    d.entity = base;
}

deinit_entity2d :: (e : *Entity) {
    e2d := e.(*Entity2D);
    free(e2d.sprite.item);
}

GUIText :: struct {
    #as using entity : Entity;
    using transform : Transform2D;
    text : Text;
}

copy_guitext :: (dst : *Entity, src : *Entity) {
    d := dst.(*GUIText); s := src.(*GUIText);
    base := d.entity;
    d.* = s.*;
    d.text.text = copy_string(s.text.text);
    d.entity = base;
}

deinit_guitext :: (e : *Entity) {
    e2d := e.(*GUIText);
    free(e2d.text.text);
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
    init(*entities2d, xx Scenes.ENTITIES_2D, deinit_proc = deinit_entity2d, copy_proc = copy_entity2d);
    init(*gui_texts, xx Scenes.GUI_TEXTS, deinit_proc = deinit_guitext, copy_proc = copy_guitext);
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
    using context.window;
    
    draw2d_begin(.{width, height});
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
    draw2d_end();
}