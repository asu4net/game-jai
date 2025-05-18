#if EDITOR && IMGUI {

draw_entity_hierarchy :: (entity : Entity) {

    if entity == NULL_ENTITY
    then return;

    // Node style ------------------------------------------------

    flags : ImGui.TreeNodeFlags;

    if get_children(entity).count == 0 {
        flags |= .Leaf;
    }
    
    if entity == resolve_ref(*context.editor.selected_ref) {
        flags |= .Selected;
    }

    enabled := is_enabled(entity);
    
    if !enabled
    then ImGui.PushStyleColor(.Text, .{ .5, .5, .5, 1 });
    
    name := get_name(entity);

    if  !name.count
    then name = tprint("%", entity ,,temp);

    // Tree node start -------------------------------------------------    
    
    opened := ImGui.TreeNodeEx(to_c_string(name ,,temp), flags);

    if !enabled
    then ImGui.PopStyleColor();

    if opened {
        // Children move ----------------------------------------------------

        if ImGui.BeginDragDropSource() {
            ImGui.SetDragDropPayload("ENTITY_DRAG", *entity, size_of(Entity));
            ImGui.Text("Drag Entity %", entity);
            ImGui.EndDragDropSource();
        }
        
        if ImGui.BeginDragDropTarget() {
            payload := ImGui.AcceptDragDropPayload("ENTITY_DRAG");
            if payload {
                dragged_entity := payload.Data.(*Entity);
                if dragged_entity.* != entity && dragged_entity.* != get_parent(entity) {
                    set_parent(dragged_entity.*, entity);
                }
            }
            ImGui.EndDragDropTarget();
        }

        // Child entity create -----------------------------------------------------
        
        if ImGui.BeginPopupContextItem() {
            selected := resolve_ref(*context.editor.selected_ref);
            if ImGui.MenuItem("Create Child Entity") {
                entity := create_entity();
                if selected != NULL_ENTITY 
                then set_parent(entity, selected);
                context.editor.selected_ref = make_ref(entity);
            }
            ImGui.EndPopup();
        }

        // Selection management ---------------------------------------------
        
        if ImGui.IsItemClicked(.Left) {
            context.editor.selected_ref = make_ref(entity);
        }
        
        // Recursive call ---------------------------------------------------
        
        for child : get_children(entity) {
            draw_entity_hierarchy(resolve_ref(*child));
        }
        
        ImGui.TreePop();
    }

    if ImGui.IsWindowHovered(.AllowWhenBlockedByPopup) && ImGui.IsMouseClicked(.Left) && !ImGui.IsAnyItemHovered()
    {
        context.editor.selected_ref = .{};
    }
}

draw_all_entities_hierarchy :: (opened : *bool) {
    
    ImGui.Begin("Entity Hierarchy", opened);

    // Draw entities -----------------------------------------------------
    
    all_entities := get_entity_view(Entity_Info);
    for entity : all_entities {
        if get_parent(entity) != NULL_ENTITY
        then continue;
        draw_entity_hierarchy(entity);
    }
    
    // Entity create -----------------------------------------------------
    
    selected := resolve_ref(*context.editor.selected_ref);
    if selected == NULL_ENTITY {
        if ImGui.BeginPopupContextWindow() {
            if ImGui.MenuItem("Create Empty Entity") {
                entity := create_entity();
                context.editor.selected_ref = make_ref(entity);
            }
            ImGui.EndPopup();
        } 
    }

    ImGui.End();

}

#scope_file

ImGui :: #import "ImGui";

} //#if EDITOR && IMGUI