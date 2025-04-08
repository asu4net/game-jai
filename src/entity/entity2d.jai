Entity2D_Flag :: enum_flags u16 {
    VISIBLE;
    FLIP_X;
    FLIP_Y;
    AUTOSIZE;
    GUI;
}

Entity2D :: struct {
    #as using entity : Entity;

    flags2d    : Entity2D_Flag;
    pos        : Vector2;
    scl        : Vector2;
    ang        : float32;
    size       : Vector2;
    tint       : Vector4;
    blend      : Blend;
}

Sprite :: struct {
    #as using entity2d : Entity2D;
    
    sheet  : *Spritesheet; @JsonIgnore
    rect   : Rect; @JsonIgnore
    item   : string; 
    tiling : Vector2;
    //particles
}

Logic_Sprite :: struct {
    #as using sprite : Sprite;
    //collisions
}

init_2d_entity :: (entity : *Entity) {
    assert(entity != null);
    e := entity.(*Entity2D);
    e.scl      = ONE_2D;
    e.flags2d  = .VISIBLE | .AUTOSIZE;
    e.tint     = WHITE;
    e.blend    = .ALPHA;
}

/*
draw_2d_entities :: (scene : *Scene(Entity2D)) {
    draw_2d_begin(.{context.window.width, context.window.height});
    for i : 1..scene.count {
        e := *scene.entities[i];
        if !should_update(e) continue;
        draw_sprite(e);
    }
    draw_2d_end();
}
*/

draw_sprite :: (e : *Sprite) {
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