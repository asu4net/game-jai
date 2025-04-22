Tag_Component :: struct @Component @Max(MAX_ENTITIES) {
    text : string;
}

on_copy_tag_component :: (e : Entity, dst : *Tag_Component, src : *Tag_Component) {
    dst.* = src.*;
    dst.text = copy_string(src.text);
} @CopyComponentCallback

on_remove_tag_component :: (e : Entity, cmp : *Tag_Component) {
    free(cmp.text);
} @RemoveComponentCallback

// ------------------------------------------------

Transform2D_Component :: struct @Component @Max(100) {
    pos := ZERO_2D;
    scl := ONE_2D;
    ang := (0.0).(f32);
}

// ------------------------------------------------

Sprite_Component :: struct @Component @Max(100) {
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

draw_sprite :: (using transform : Transform2D_Component, using sprite : *Sprite_Component, sheet : *Spritesheet, id : u32 = 0) {
    
    if !visible then return;

    tex := ifx item.count > 0 then *sheet.tex else null;
    flags := ifx item.count > 0 then DEFAULT_QUAD_FLAGS | .USE_SUBTEX else DEFAULT_QUAD_FLAGS;
    
    if autosize then flags |= .AUTOSIZE;
    if flip_x   then flags |= .FLIP_X;
    if flip_y   then flags |= .FLIP_Y;

    // try find the item
    if tex && (rect.width == 0 || rect.height == 0) {
        r, found := table_find(*sheet.rects, item);
        if found rect = r;
    }
    
    draw_quad(pos, ang, scl, tex, tiling, size, blend, rect, tint, id, flags);        
}

// ------------------------------------------------

Text_Component :: struct @Component @Max(100) {
    visible := true;
    text    := "placeholder!";
    blend   := Blend.ALPHA;
    tint    := WHITE;          @Color
}

draw_text :: (using transform : Transform2D_Component, using t : Text_Component, font : *Font, id : u32 = 0) {
    
    if !visible then return;
    draw_gui_text(pos, ang, scl, text, font, blend, tint, id); 
}

// ------------------------------------------------

Blink_Component :: struct @Component @Max(100) {
    enabled    := false;
    start_tint := WHITE;        @Color
    end_tint   := RED;          @Color
    duration   := (0.5).(f32);
    progress   := (0.0).(f32);
}

update_blink :: (using blink : *Blink_Component, tint : *v4) {

    if enabled && tint {

        progress += delta_seconds();
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