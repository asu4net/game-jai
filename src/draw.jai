draw_frame :: () {

    //---------------------------
    //:DRAW ENTITIES 2D
    //---------------------------
    
    draw2d_begin(.{context.window.width, context.window.height});
    // FlipBook.
    {
        view := get_entity_view(FlipBook_Component);
        for view update_flipbook_entity(it);
    }
    // Sprites.
    {
        view := get_entity_view(Transform2D_Component, Sprite_Component);
        for view draw_sprite_entity(it, *sheet);
    }
    // Collisions.
    #if EDITOR {
        if is_shortcut_pressed(.TOGGLE_SHOW_COLLIDERS) {
            show_colliders = !show_colliders;   
        }
        if show_colliders {
            view := get_entity_view(Transform2D_Component, Circle_Collider_Component);
            collisions_table := context.collisions2d.collisions_table;
            for view {
                coll := get_component(Circle_Collider_Component, it);
                ref := make_ref(it);
                if table_contains(*collisions_table, ref) {
                    collides_with := table_find_pointer(*collisions_table, ref);
                    if collides_with.count == 0 
                    then draw_circle(pos = get_pos(it), rad = coll.radius, tint = LIGHT_GREEN);
                    else draw_circle(pos = get_pos(it), rad = coll.radius, tint = LIGHT_RED);
                } else {
                    draw_circle(pos = get_pos(it), rad = coll.radius, tint = LIGHT_GREEN);
                }
            }
        }
    }
    draw2d_end();

    //---------------------------
    //:DRAW IMGUI
    //---------------------------

    #if IMGUI {
        begin_draw_imgui();
        draw_editor();
        end_draw_imgui();
    }
}