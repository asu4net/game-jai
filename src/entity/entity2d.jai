Entity2D_Flag :: enum_flags u16 {
    VISIBLE;
    FLIP_X;
    FLIP_Y;
    AUTOSIZE;
}

Entity2D :: struct {
    #as using entity : Entity;
    
    flags2d : Entity2D_Flag = .VISIBLE | .AUTOSIZE;
    item    : string;
    rect    : Rect;         @JsonIgnore
    pos     : v2       = ZERO_2D;
    scl     : v2       = ONE_2D;
    ang     : f32       = 0;
    size    : v2       = ONE_2D;
    tint    : v4       = WHITE;
    blend   : Blend         = .ALPHA;
    tiling  : v2       = ONE_2D;

    using vfx : VFX2D;
}

#add_context entities2d : Entities2D;

Entities2D :: struct {
    scene : Scene(Entity2D);
    sheet : Spritesheet;
}

copy_entity2d :: (dst : *Entity, src : *Entity) {
    s_dst := dst.(*Entity2D);
    s_src := src.(*Entity2D);
    base_entity := s_dst.entity;
    s_dst.* = s_src.*;
    s_dst.entity = base_entity;
}

init_entities2d :: () {
    using context.entities2d;
    init(*sheet);
    init(*scene, xx Scenes.ENTITIES_2D, copy_proc = copy_entity2d);
}

deinit_entities2d :: () {
    using context.entities2d;
    deinit(*sheet);
    deinit(*scene);
    context.entities2d = .{};
}

draw_entities2d :: () {
    using context.entities2d;
    for i : 1..scene.count {
        e := *scene.entities[i];
        if !should_update(e) {
            continue;
        }
        draw2d_begin(.{context.window.width, context.window.height});
        draw_entity2d(e);
        draw2d_end();
    }
}

draw_entity2d :: (e : *Entity2D) {
    using context.entities2d;
    if !is_enabled(e) || !.VISIBLE & e.flags2d return;

    tex   := ifx e.item.count > 0 then *sheet.tex else null;
    flags := ifx e.item.count > 0 then DEFAULT_QUAD_FLAGS | .USE_SUBTEX else DEFAULT_QUAD_FLAGS;
    if .AUTOSIZE & e.flags2d then flags |= .AUTOSIZE;

    // try find the item
    if tex && (e.rect.width == 0 || e.rect.height == 0) {
        rect, found := table_find(*sheet.rects, e.item);
        if found e.rect = rect;
    }
    
    draw_quad(e.pos, e.ang, e.scl, tex, e.tiling, e.size, e.blend, e.rect, e.tint, e.id, flags);
}