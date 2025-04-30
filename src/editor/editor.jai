#if EDITOR {

TEXT_BUFF_SIZE :: 100;

TextBuff :: [TEXT_BUFF_SIZE] u8;

data :: (buff : TextBuff) -> *u8 { 
    return *buff[0];
}

Editor :: struct {
    show_demo                : bool;
    prefab_name              : TextBuff;
    prefab_type              : PrefabEditorType;
    prefab_ref               : Entity_Ref;
    selected_ref             : Entity_Ref;
    show_create_prefab       : bool;
    create_prefab_parent_ref : Entity_Ref;
}

PrefabEditorType :: struct {
    name : string;
    slot : u32;
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
                if prefab {
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
                        if prefab {
                            immediate_destroy_entity(prefab, true);
                            prefab = null;
                            context.editor.prefab_ref = .{};
                            context.editor.selected_ref = .{};
                        }
                        prefab_str, success := read_entire_file(info.full_name ,,temp);
                        assert(success);
                        prefab = deserialize_entity_recursive(prefab_str);
                        context.editor.prefab_ref = make_ref(prefab);
                        context.editor.selected_ref = context.editor.prefab_ref;
                    }
                });
                ImGui.EndMenu();
            }
            if prefab && ImGui.MenuItem("Save") {
                save_prefab();
            }
            if prefab && ImGui.MenuItem("Save and Close") {
                save_prefab_and_close();
            }
            if prefab && ImGui.MenuItem("Close") {
                immediate_destroy_entity(prefab, true);
                prefab = null;
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

        prefab_types : [..] PrefabEditorType;
        
        for scene : context.scenes {
            if !scene continue;
            array_add(*prefab_types, .{ scene.type.name, scene.slot } ,,temp);
        }

        if prefab_type.name.count == 0 {
           prefab_type = prefab_types[0];
        }

        if ImGui.BeginCombo("Type", to_c_string(prefab_type.name ,,temp)) {
            for type, i : prefab_types {
                if ImGui.Selectable(to_c_string(type.name ,,temp)) {
                    prefab_type = type;
                }
            }
            ImGui.EndCombo();
        }
        
        if ImGui.Button("Create") {
            show_create_prefab = false;
            scene := context.scenes[prefab_type.slot];
            prefab := resolve_ref(*prefab_ref);
            parent := resolve_ref(*create_prefab_parent_ref);

            if scene && c_style_strlen(data(prefab_name)) > 0 {
                if !parent && prefab {
                    destroy_entity(prefab);
                    prefab = null;
                    prefab_ref = .{};
                    selected_ref = .{};
                }
                prefab = scene.entity_procs.create(scene.slot, to_string(data(prefab_name)));
                if !parent {
                    prefab_ref = make_ref(prefab);
                }
                selected_ref = prefab_ref;
                if parent {
                    set_parent(prefab, parent);
                }
                create_prefab_parent_ref = .{};
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
            if entity {
                flags : ImGui.TreeNodeFlags;
                if entity.children.count == 0 {
                    flags |= .Leaf;
                }
                enabled := is_enabled(entity);
                if !enabled {
                    ImGui.PushStyleColor(.Text, .{ .5, .5, .5, 1 });
                }
                opened := ImGui.TreeNodeEx(to_c_string(entity.tag ,,temp), flags);
                if !enabled {
                    ImGui.PopStyleColor();
                }
                if opened {
                    if ImGui.BeginDragDropSource() {
                        ImGui.SetDragDropPayload("ENTITY_DRAG", *ref, size_of(Entity_Ref));
                        ImGui.Text("Drag Entity %", ref.id);
                        ImGui.EndDragDropSource();
                    }
                    if ImGui.BeginDragDropTarget() {
                        payload := ImGui.AcceptDragDropPayload("ENTITY_DRAG");
                        if payload {
                            dragged_entity_ref := payload.Data.(*Entity_Ref);
                            dragged_entity := resolve_ref(dragged_entity_ref);
                            if dragged_entity_ref.id != ref.id && dragged_entity_ref.id != dragged_entity.parent.id {
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
                    for child : entity.children {
                        hierarchy(child);
                    }
                    ImGui.TreePop();
                }
            }
        }

        hierarchy(prefab_ref);
        ImGui.End();
    }

    // Properties.
    {
        entity := resolve_ref(*selected_ref);
        if entity {
            ImGui.Begin("Properties");
            scene := get_scene(entity);
            scene.entity_procs.draw_editor(entity);
            ImGui.End();
        }
    }
}

save_prefab_and_close :: () {
    using context.editor;
    save_prefab();
    prefab := resolve_ref(*prefab_ref);
    immediate_destroy_entity(prefab, true);
    ImGui.CloseCurrentPopup();
    prefab = null;
    prefab_ref = .{};
    selected_ref = .{};
}

save_prefab :: () {
    using context.editor;
    prefab := resolve_ref(*prefab_ref);
    assert(prefab != null);
    builder : String_Builder;
    serialize_entity_recursive(prefab, *builder);
    write_entire_file(tprint("assets/prefabs/%.prefab", prefab.tag ,,temp), *builder);
}

} //#if IMGUI