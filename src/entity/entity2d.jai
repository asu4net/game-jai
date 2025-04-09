Entity2D_Flag :: enum_flags u16 {
    VISIBLE;
    FLIP_X;
    FLIP_Y;
    AUTOSIZE;
    GUI;
}

Entity2D :: struct {
    #as using entity : Entity;

    flags2d    : Entity2D_Flag = .VISIBLE | .AUTOSIZE;
    pos        : Vector2       = ZERO_2D;
    scl        : Vector2       = ONE_2D;
    ang        : float32       = 0;
    size       : Vector2       = ONE_2D;
    tint       : Vector4       = WHITE;
    blend      : Blend         = .ALPHA;
}

Sprite :: struct {
    #as using entity2d : Entity2D;
    
    sheet  : *Spritesheet; @JsonIgnore
    rect   : Rect; @JsonIgnore
    item   : string; 
    tiling : Vector2;
    //particles
}

AIEntity2D :: struct {
    #as using sprite : Sprite;
    //collisions
}

#add_context sprites : Scene(Sprite);

copy_sprite :: (dst : *Entity, src : *Entity) {
    s_dst := dst.(*Sprite);
    s_src := src.(*Sprite);
    base_entity := s_dst.entity;
    s_dst.* = s_src.*;
    s_dst.entity = base_entity;
}

init_sprites :: () {
    init(*context.sprites, 0, copy_proc = copy_sprite);
}

deinit_sprites :: () {
    deinit(*context.sprites);
}

draw_sprites :: () {
    for i : 1..context.sprites.count {
        sprite := *context.sprites.entities[i];
        if !should_update(sprite) continue;
        draw2d_begin(.{context.window.width, context.window.height});
        draw_sprite(sprite);
        draw2d_end();
    }
}

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