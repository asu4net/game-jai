Transform2D :: struct {
    pos : v2  = ZERO_2D;
    scl : v2  = ONE_2D;
    ang : f32 = 0;
}

Sprite :: struct {
    visible  : bool   = true;
    item     : string;
    tint     : v4     = WHITE;
    size     : v2     = ONE_2D;
    tiling   : v2     = ONE_2D;
    blend    : Blend  = .ALPHA;
    flip_x   : bool;
    flip_y   : bool;
    autosize : bool   = true;
    rect     : Rect; @JsonIgnore
}

draw_sprite :: (using transform : *Transform2D, using sprite : *Sprite, id : u32 = 0) {
    
    if !visible then return;

    tex := ifx item.count > 0 then *context.entities2d.sheet.tex else null;
    flags := ifx item.count > 0 then DEFAULT_QUAD_FLAGS | .USE_SUBTEX else DEFAULT_QUAD_FLAGS;
    
    if autosize then flags |= .AUTOSIZE;
    if flip_x   then flags |= .FLIP_X;
    if flip_y   then flags |= .FLIP_Y;

    // try find the item
    if tex && (rect.width == 0 || rect.height == 0) {
        r, found := table_find(*context.entities2d.sheet.rects, item);
        if found rect = r;
    }
    
    draw_quad(pos, ang, scl, tex, tiling, size, blend, rect, tint, id, flags);        
}