Sprite :: struct {
    visible  : bool;
    tint     : Vector4;
    rect     : Rect;
    item     : string;
    tiling   : Vector2;
    flip_x   : bool;
    flip_y   : bool;
    autosize : bool;
    blend    : Blend;
}

Entity2D :: struct {
    #as using entity : Entity;
    using sprite : Sprite;

    pos        : Vector2;
    scl        : Vector2;
    ang        : float32;
    size       : Vector2;
}

draw_2d_entities :: (scene : *Scene(Entity2D)) {

    draw_2d_begin(.{window.width, window.height});
    
    for i : 1..scene.used_ids.count {
            
        e := (*scene.entities[i]).(*Entity2D);
        if !is_enabled(e) || !e.visible then continue;
        
        tex   := ifx e.item.count > 0 then *sheet.tex else null;
        flags := ifx e.item.count > 0 then DEFAULT_QUAD_FLAGS | .USE_SUBTEX else DEFAULT_QUAD_FLAGS;

        // try find the item
        if tex && (e.rect.width == 0 || e.rect.height == 0) {
            rect, found := table_find(*sheet.rects, e.item);
            e.rect = ifx found then rect;
        }
            
        draw_quad(e.pos, e.ang, e.scl, tex, e.tiling, e.size, e.blend, e.rect, e.tint, e.id, flags);
    }
    
    draw_2d_end();
}