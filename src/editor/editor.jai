#if EDITOR {

TEXT_BUFF_SIZE :: 100;

TextBuff :: [TEXT_BUFF_SIZE] u8;

data :: (buff : TextBuff) -> *u8 { 
    return *buff[0];
}

Editor :: struct {
    show_demo                : bool;
    prefab_name              : TextBuff;
    prefab_ref               : Entity_Ref;
    show_create_prefab       : bool;
    create_prefab_parent_ref : Entity_Ref;
    selected_ref             : Entity_Ref;
}

#add_context editor : Editor;

draw_editor :: () {
    using context.editor;

    if ImGui.BeginMenuBar()  {
        if ImGui.BeginMenu("ImGui") {
            ImGui.Checkbox("Show demo", *show_demo);
            ImGui.EndMenu();
        }
        if ImGui.BeginMenu("Prefab")  {
            prefab := resolve_ref(*prefab_ref);
            if ImGui.MenuItem("New") {
                if prefab != NULL_ENTITY {
                    save_prefab_and_close();
                }
                show_create_prefab = true;
            }
            if ImGui.BeginMenu("Load") {
                // Load all the prefabs
                visit_files("assets", true, null, (info: *File_Visit_Info, *void) {
                    path, basename, ext := path_decomp(info.full_name ,,temp);
                    if ext != "prefab" {
                        return;
                    }
                    if ImGui.MenuItem(to_c_string(basename ,,temp)) {
                        prefab := resolve_ref(*context.editor.prefab_ref);
                        if prefab != NULL_ENTITY{
                            immediate_destroy_entity(prefab);
                            prefab = NULL_ENTITY;
                            context.editor.prefab_ref = .{};
                            context.editor.selected_ref = .{};
                        }
                        prefab_str, success := read_entire_file(info.full_name ,,temp);
                        assert(success);
                        prefab = deserialize_entity(prefab_str);
                        context.editor.prefab_ref = make_ref(prefab);
                        context.editor.selected_ref = context.editor.prefab_ref;
                    }
                });
                ImGui.EndMenu();
            }
            if prefab != NULL_ENTITY && ImGui.MenuItem("Save") {
                save_prefab();
            }
            if prefab != NULL_ENTITY && ImGui.MenuItem("Save and Close") {
                save_prefab_and_close();
            }
            if prefab != NULL_ENTITY && ImGui.MenuItem("Close") {
                immediate_destroy_entity(prefab);
                prefab = NULL_ENTITY;
                prefab_ref = .{};
                selected_ref = .{};
            }
            ImGui.EndMenu();
        }
        ImGui.EndMenuBar();
    }

    if show_demo {
        ImGui.SetNextWindowPos(.{650, 20}, ImGui.Cond.FirstUseEver, .{0,0});
        ImGui.ShowDemoWindow(*show_demo);
    }
    
    if show_create_prefab {
        ImGui.OpenPopup("Create Prefab");
    }
    
    ImGui.PushStyleColor(.PopupBg, .{0.0, 0.0, 0.0, 1});
    viewpor_size := ImGui.GetMainViewport().WorkSize;
    ImGui.SetNextWindowPos(viewpor_size / 2, .Appearing, .{0.5, 0.5});

    if ImGui.BeginPopupModal("Create Prefab", flags = .AlwaysAutoResize | .NoMove)  {
        ImGui.InputText("Name", data(prefab_name), TEXT_BUFF_SIZE);
        
        if ImGui.Button("Create") {
            show_create_prefab = false;

            prefab := resolve_ref(*prefab_ref);
            parent := resolve_ref(*create_prefab_parent_ref);
            
            if c_style_strlen(data(prefab_name)) > 0 {

                if !parent && prefab {
                    destroy_entity(prefab);
                    prefab = NULL_ENTITY;
                    prefab_ref = .{};
                    selected_ref = .{};
                }

                prefab = create_entity();
                tag := add_component(Tag_Component, prefab);
                tag.text = copy_string(to_string(data(prefab_name)));
                if parent == NULL_ENTITY
                then prefab_ref = make_ref(prefab);
                create_prefab_parent_ref = .{};
                add_child(parent, prefab);
                ImGui.CloseCurrentPopup();
            }
        }

        ImGui.SameLine();
        if ImGui.Button("Cancel") {
            show_create_prefab = false;
            ImGui.CloseCurrentPopup();
        }
        ImGui.EndPopup();
    }
    ImGui.PopStyleColor();

    // Hierarchy.
    {
        ImGui.Begin("Hierarchy");
        
        hierarchy :: (ref : Entity_Ref) {
            entity := resolve_ref(*ref);
            if entity != NULL_ENTITY {
                flags : ImGui.TreeNodeFlags;
                if has_component(Node_Component, entity) {
                    entity_node := get_component(Node_Component, entity);
                    if entity_node.children.count == 0 {
                        flags |= .Leaf;
                    }
                } else {
                    flags |= .Leaf;
                }
                
                enabled := is_enabled(entity);
                if !enabled {
                    ImGui.PushStyleColor(.Text, .{ .5, .5, .5, 1 });
                }
                tag : string;
                if has_component(Tag_Component, entity)
                then tag = get_component(Tag_Component, entity).text;
                else tag = tprint("%", entity ,,temp);

                opened := ImGui.TreeNodeEx(to_c_string(tag ,,temp), flags);
                if !enabled {
                    ImGui.PopStyleColor();
                }
                if opened {
                    if ImGui.BeginDragDropSource() {
                        ImGui.SetDragDropPayload("ENTITY_DRAG", *ref, size_of(Entity_Ref));
                        ImGui.Text("Drag Entity %", ref.entity);
                        ImGui.EndDragDropSource();
                    }
                    if ImGui.BeginDragDropTarget() {
                        payload := ImGui.AcceptDragDropPayload("ENTITY_DRAG");
                        if payload {
                            dragged_entity_ref := payload.Data.(*Entity_Ref);
                            dragged_entity := resolve_ref(dragged_entity_ref);
                            dragged_entity_node := get_component(Node_Component, dragged_entity);
                            if dragged_entity_ref.entity != ref.entity && dragged_entity_ref.entity != dragged_entity_node.parent.entity {
                                set_parent(dragged_entity, entity);
                            }
                        }
                        ImGui.EndDragDropTarget();
                    }
                    if ImGui.BeginPopupContextItem() {
                        if ImGui.MenuItem("Add Child") {
                            context.editor.show_create_prefab = true;
                            context.editor.create_prefab_parent_ref = context.editor.selected_ref;
                        }
                        ImGui.EndPopup();
                    }
                    if ImGui.IsItemClicked() {
                        context.editor.selected_ref = ref;
                    }
                    if has_component(Node_Component, entity) {
                        for child : get_component(Node_Component, entity).children {
                            hierarchy(child);
                        }
                    }
                    
                    ImGui.TreePop();
                }
            }
        }

        hierarchy(prefab_ref);
        ImGui.End();
    }

    entity := resolve_ref(*selected_ref);
    if entity != NULL_ENTITY {
        ImGui.Begin("Properties");
        editor_draw_entity(entity);
        ImGui.End();
    }
}

save_prefab_and_close :: () {
    using context.editor;
    save_prefab();
    prefab := resolve_ref(*prefab_ref);
    immediate_destroy_entity(prefab);
    ImGui.CloseCurrentPopup();
    prefab = NULL_ENTITY;
    prefab_ref = .{};
    selected_ref = .{};
}

save_prefab :: () {
    using context.editor;
    prefab := resolve_ref(*prefab_ref);
    assert(prefab != NULL_ENTITY);
    tag := get_component(Tag_Component, prefab);
    write_entire_file(tprint("assets/%.prefab", tag.text ,,temp), serialize_entity(prefab ,,temp));
}

editor_draw_entity :: (entity : Entity) {
        EntityStorageContext();
        
        for state.component_arenas {
            if !it.has(entity)
            then continue;
            it.drw(entity);
            editor_draw_separator();
            editor_draw_spacing();
        }

        if editor_draw_centered_button("Add Component") {
            ImGui.OpenPopup("Add Component");
        }

        if ImGui.BeginPopup("Add Component") {
            for state.component_arenas {
                if it.has(entity)
                then continue;
                if ImGui.MenuItem(to_c_string(it.type.name ,,temp)) {
                    it.add(entity);
                }
            }
            ImGui.EndPopup();
        }
    }

} //#if IMGUI