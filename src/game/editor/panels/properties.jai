#if IMGUI && EDITOR {

editor_draw_entity :: (entity : Entity) {
    EntityStorageContext();
        
    ignore_info := editor_should_ignore_struct(state.info_arena.type.info);
        
    if !ignore_info {
        if EDITOR generic_drw_component(state.info_arena.type, entity);
        editor_draw_separator();
        editor_draw_spacing();
    } 

    for state.component_arenas {
        if !generic_has_component(it.type, entity)
        then continue;
        ignore_all := editor_should_ignore_struct(it.type.info);
        if !ignore_all {
            generic_drw_component(it.type, entity);
            editor_draw_separator();
            editor_draw_spacing();
        }
    }

    if editor_draw_centered_button("Add Component") {
        ImGui.OpenPopup("Add Component");
    }

    if ImGui.BeginPopup("Add Component") {
        for state.component_arenas {
            if generic_has_component(it.type, entity)
            then continue;
            if ImGui.MenuItem(to_c_string(it.type.info.name ,,temp)) {
                generic_add_component(it.type, entity);
            }
        }
        ImGui.EndPopup();
    }
}

draw_properties :: (opened : *bool) {
    
    ImGui.Begin("Properties", opened);
    entity := resolve_ref(*context.editor.selected_ref);
    if entity != NULL_ENTITY {
        editor_draw_entity(entity);
    }
    ImGui.End();
}

} //#if IMGUI && EDITOR