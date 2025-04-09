Entity2D_Flag :: enum_flags u16 {
    VISIBLE;
    FLIP_X;
    FLIP_Y;
    AUTOSIZE;
}

Entity2D :: struct {
    #as using entity : Entity;
    
    flags2d : Entity2D_Flag = .VISIBLE | .AUTOSIZE;
    sheet   : *Spritesheet; @JsonIgnore
    rect    : Rect;         @JsonIgnore
    item    : string; 
    pos     : Vector2       = ZERO_2D;
    scl     : Vector2       = ONE_2D;
    ang     : float32       = 0;
    size    : Vector2       = ONE_2D;
    tint    : Vector4       = WHITE;
    blend   : Blend         = .ALPHA;
    tiling  : Vector2       = ONE_2D;
}

#add_context entities2d : Scene(Entity2D);

copy_entity2d :: (dst : *Entity, src : *Entity) {
    s_dst := dst.(*Entity2D);
    s_src := src.(*Entity2D);
    base_entity := s_dst.entity;
    s_dst.* = s_src.*;
    s_dst.entity = base_entity;
}

init_entities2d :: () {
    init(*context.entities2d, xx Scenes.ENTITIES_2D, copy_proc = copy_entity2d);
}

deinit_entities2d :: () {
    deinit(*context.entities2d);
}

draw_entities2d :: () {
    for i : 1..context.entities2d.count {
        e := *context.entities2d.entities[i];
        if !should_update(e) {
            continue;
        }
        draw2d_begin(.{context.window.width, context.window.height});
        draw_entities2d(e);
        draw2d_end();
    }
}

draw_entities2d :: (e : *Entity2D) {
    assert(e != null);
    if !is_enabled(e) || !.VISIBLE & e.flags2d return;
    tex   := ifx e.item.count > 0 then *e.sheet.tex else null;
    flags := ifx e.item.count > 0 then DEFAULT_QUAD_FLAGS | .USE_SUBTEX else DEFAULT_QUAD_FLAGS;
    if .AUTOSIZE & e.flags2d then flags |= .AUTOSIZE;

    // try find the item
    if tex && (e.rect.width == 0 || e.rect.height == 0) {
        rect, found := table_find(*e.sheet.rects, e.item);
        e.rect = ifx found then rect;
    }
    
    draw_quad(e.pos, e.ang, e.scl, tex, e.tiling, e.size, e.blend, e.rect, e.tint, e.id, flags);
}