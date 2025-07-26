Sprite_Component :: struct @Component @InitOrder(1000)  {
    visible  := true;
    item     := "";
    tint     := WHITE;       @Color
    size     := ONE_2D;
    tiling   := ONE_2D;
    blend    := Blend.ALPHA;
    flip_x   := false;
    flip_y   := false;
    autosize := true;
    rect     := Rect.{};     @JsonIgnore @EditorReadOnly 
}

on_copy_sprite_component :: (e : Entity, dst : *Sprite_Component, src : *Sprite_Component) {
    dst.* = src.*;
    dst.item = copy_string(src.item);
} @CopyComponentCallback

on_remove_sprite_component :: (e : Entity, cmp : *Sprite_Component) {
    free(cmp.item);
} @RemoveComponentCallback

draw_sprite_entity :: (entity : Entity, sheet : *Spritesheet) {

    using transform := get_component(Transform2D_Component, entity);
    using sprite    := get_component(Sprite_Component,      entity);
    
    if !visible then return;

    if has_component(Blink_Component, entity)
    then update_blink(get_component(Blink_Component, entity), *tint);
    
    tex := ifx item.count > 0 then *sheet.tex else null;
    flags : QuadFlag;
    if item.count then flags |= .USE_SUBTEX;
    if autosize   then flags |= .AUTOSIZE;
    if flip_x     then flags |= .FLIP_X;
    if flip_y     then flags |= .FLIP_Y;

    // try find the item
    if tex {
        assert(tex.id != 0);
        found, r := table_find_new(*sheet.rects, item);
        if found
        then rect = r;
        else tex = null;
    }
    
    draw_quad(get_matrix(entity), tex, tiling, size, blend, rect, tint, entity, flags);        
}