// ------------------------------------------------

Node_Component :: struct @Component @InitOrder(-1000000) @Max(100) {
    parent   : Entity_Ref;
    children : [..] Entity_Ref;
}

on_rem_node_component :: (entity : Entity, cmp : *Node_Component) {
    array_reset(*cmp.children);
} @RemoveComponentCallback

set_parent :: (entity : Entity, parent : Entity) {

    entity_node := ifx has_component(Node_Component, entity) 
        then get_component(Node_Component, entity) 
        else add_component(Node_Component, entity);
    
    current_parent := resolve_ref(*entity_node.parent);
    
    if is_not_cleaned(current_parent) && is_not_destroyed(current_parent) {
        
        remove_child :: (entity : Entity, child : Entity) {    
            entity_node := get_component(Node_Component, entity);
            index := -1;
            found := false;
            for current_child, index : entity_node.children { 
                if entity == current_child.entity then { 
                    found = true;
                    break; 
                }
            }
            if found then array_unordered_remove_by_index(*entity_node.children, index);
            compute_enabled_iterative(make_ref(child));
            //#TODO_asuarez Remove the Node_Component if it is not being used.
        }
        
        remove_child(parent, entity);
    }

    entity_node.parent = make_ref(parent);

    add_child :: (entity : Entity, child : Entity) {
    
        entity_node := ifx has_component(Node_Component, entity) 
            then get_component(Node_Component, entity) 
            else add_component(Node_Component, entity);

        if !has_component(Node_Component,  child)
        then add_component(Node_Component, child);

        for ref : entity_node.children {
            current_child := resolve_ref(*ref);
            if current_child == child 
            then return;
        }

        child_ref := make_ref(child);
        array_add(*entity_node.children, child_ref);
        compute_enabled_iterative(child_ref);
    }

    add_child(parent, entity);
}

compute_enabled_iterative :: (ref : Entity_Ref) { 
    stack : [..] Entity_Ref;
    array_add(*stack, ref ,,temp);

    while stack.count > 0 {
        current_ref := pop(*stack);
        current_entity := resolve_ref(*current_ref);
        current_entity_node := get_component(Node_Component, current_entity);
        parent_ref := current_entity_node.parent;

        parent := resolve_ref(*parent_ref);
        parent_enabled := ifx is_not_cleaned(parent) && is_not_destroyed(parent) then is_enabled(parent) else true;
        current_entity_info := get_info(current_entity);
        new_enabled := (.LOCAL_ENABLED & current_entity_info.flags).(bool) && parent_enabled;
        
        if((.ENABLED & current_entity_info.flags).(bool) != new_enabled) {
            for child : current_entity_node.children {
                array_add(*stack, child);
            } 
        }

        if new_enabled && !(.ENABLED & current_entity_info.flags) { 
            current_entity_info.flags |= .ENABLED;
        } 
        else if !new_enabled && .ENABLED & current_entity_info.flags { 
            current_entity_info.flags = current_entity_info.flags &~ .ENABLED;
        }
    }
}

// ------------------------------------------------

Transform2D_Component :: struct @Component @InitOrder(-900000) @Max(100) {
    pos := ZERO_2D;
    scl := ONE_2D;
    ang := (0.0).(f32);
}

// ------------------------------------------------

Tag_Component :: struct @Component @InitOrder(-450000) @Max(MAX_ENTITIES) {
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

on_copy_sprite_component :: (e : Entity, dst : *Sprite_Component, src : *Sprite_Component) {
    dst.* = src.*;
    dst.item = copy_string(src.item);
} @CopyComponentCallback

on_remove_sprite_component :: (e : Entity, cmp : *Sprite_Component) {
    free(cmp.item);
} @RemoveComponentCallback

draw_sprite :: (using transform : Transform2D_Component, using sprite : *Sprite_Component, sheet : *Spritesheet, id : u32 = 0) {
    if !visible then return;

    tex := ifx item.count > 0 then *sheet.tex else null;
    flags := ifx item.count > 0 then DEFAULT_QUAD_FLAGS | .USE_SUBTEX else DEFAULT_QUAD_FLAGS;
    
    if autosize then flags |= .AUTOSIZE;
    if flip_x   then flags |= .FLIP_X;
    if flip_y   then flags |= .FLIP_Y;

    // try find the item
    if tex && (rect.width == 0 || rect.height == 0) {
        assert(tex.id != 0);
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