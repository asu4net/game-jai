// @Info:
// @InitOrder Range here: 10100 - 30000
Transform2D_Component :: struct @Component @InitOrder(0) @Max(MAX_ENTITIES) {
    pos := ZERO_2D;
    scl := ONE_2D;
    ang := (0.0).(f32);
}

get_matrix :: (entity : Entity) -> m4 {
    
    transform := get_component(Transform2D_Component, entity);
    child_matrix := make_transform(transform.pos, transform.ang, transform.scl);
    
    if !is_not_destroyed(entity)
    then return child_matrix;

    parent := get_parent(entity);

    child_pos := transform.pos;
    child_ang := transform.ang;
    child_scl := transform.scl;

    current_entity := entity;

    while is_not_destroyed(get_parent(current_entity)) {
        parent = get_parent(current_entity);
        
        if !has_component(Transform2D_Component, parent)
        then continue;

        parent_transform := get_component(Transform2D_Component, parent);
        child_pos += parent_transform.pos;
        
        child_pos = rotate_around(parent_transform.pos, parent_transform.ang, child_pos);

        child_ang += parent_transform.ang;
        child_scl *= parent_transform.scl;

        current_entity = parent;
    }

    return make_transform(child_pos, child_ang, child_scl);
}

Sprite_Component :: struct @Component @InitOrder(1000) @Max(MAX_ENTITIES) {
    visible  := true;
    item     := "";
    tint     := WHITE;       @Color
    size     := ONE_2D;
    tiling   := ONE_2D;
    blend    := Graphics.Blend.ALPHA;
    flip_x   := false;
    flip_y   := false;
    autosize := true;
    rect     := Graphics.Rect.{};     @JsonIgnore @EditorReadOnly 
}

on_copy_sprite_component :: (e : Entity, dst : *Sprite_Component, src : *Sprite_Component) {
    dst.* = src.*;
    dst.item = copy_string(src.item);
} @CopyComponentCallback

on_remove_sprite_component :: (e : Entity, cmp : *Sprite_Component) {
    free(cmp.item);
} @RemoveComponentCallback

draw_sprite_entity :: (entity : Entity, sheet : *Graphics.Spritesheet) {

    using transform := get_component(Transform2D_Component, entity);
    using sprite    := get_component(Sprite_Component,      entity);
    
    if !visible then return;

    if has_component(Blink_Component, entity)
    then update_blink(get_component(Blink_Component, entity), *tint);
    
    tex := ifx item.count > 0 then *sheet.tex else null;
    flags := ifx item.count > 0 then Graphics.DEFAULT_QUAD_FLAGS | .USE_SUBTEX else Graphics.DEFAULT_QUAD_FLAGS;
    
    if autosize then flags |= .AUTOSIZE;
    if flip_x   then flags |= .FLIP_X;
    if flip_y   then flags |= .FLIP_Y;

    // try find the item
    if tex && (rect.width == 0 || rect.height == 0) {
        assert(tex.id != 0);
        found, r := table_find_new(*sheet.rects, item);
        if found rect = r;
    }
    
    Graphics.draw_quad(get_matrix(entity), tex, tiling, size, blend, rect, tint, entity, flags);        
}

// ------------------------------------------------

Text_Component :: struct @Component @InitOrder(2000) @Max(MAX_ENTITIES) {
    visible := true;
    text    := "placeholder!";
    blend   := Graphics.Blend.ALPHA;
    tint    := WHITE;          @Color
}

draw_text :: (using transform : Transform2D_Component, using t : Text_Component, font : *Graphics.Font, id : u32 = 0) {    
    if !visible then return;
    Graphics.draw_gui_text(pos, ang, scl, text, font, blend, tint, id); 
}

// ------------------------------------------------

Blink_Component :: struct @Component @InitOrder(10300) @Max(MAX_ENTITIES) {
    enabled    := false;
    start_tint := WHITE;        @Color
    end_tint   := RED;          @Color
    duration   := (0.5).(f32);
    progress   := (0.0).(f32);
}

update_blink :: (using blink : *Blink_Component, tint : *v4) {
    if enabled && tint {

        progress += Time.delta_seconds();
        progress = clamp(progress, 0.0, duration);
        normalized_progress := progress / duration;
        tint.* = linear_interp(normalized_progress, start_tint, end_tint); 
            
        if normalized_progress == 1 {
                
            new_target := start_tint;
            start_tint = end_tint;
            end_tint   = new_target;
            progress   = 0;
        }
    } 
}

#scope_file

Graphics :: #import "Graphics" (DUMP_ERRORS = DEBUG);
Time :: #import "Time";
#import "Hash_Table";