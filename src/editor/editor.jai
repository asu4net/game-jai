#if IMGUI && EDITOR {

TEXT_BUFF_SIZE :: 100;

TextBuff :: [TEXT_BUFF_SIZE] u8;

data :: (buff : TextBuff) -> *u8 { 
    return *buff[0];
}

Editor :: struct {
    show_demo                : bool;
    show_hierarchy           : bool;
    show_properties          : bool;

    prefab_name              : TextBuff;
    prefab_ref               : Entity_Ref;
    show_create_prefab       : bool;
    create_prefab_parent_ref : Entity_Ref;
    selected_ref             : Entity_Ref;

    clone_pressed            : bool;
}

#add_context editor : Editor;

draw_editor :: () {
    using context.editor;

    update_clone_shortcut();

    if ImGui.BeginMenuBar()  {
        if ImGui.BeginMenu("ImGui") {
            ImGui.Checkbox("Show demo", *show_demo);
            ImGui.EndMenu();
        }
        if ImGui.BeginMenu("Entity") {
            ImGui.Checkbox("Show hierarchy",  *show_hierarchy);
            ImGui.Checkbox("Show properties", *show_properties);
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
                            destroy_entity(prefab);
                            prefab = NULL_ENTITY;
                            context.editor.prefab_ref = .{};
                            context.editor.selected_ref = .{};
                        }
                        prefab = dlz_entity_from_file(info.full_name);
                        assert(prefab != NULL_ENTITY);
                        context.editor.prefab_ref = make_ref(prefab);
                        context.editor.selected_ref = context.editor.prefab_ref;
                        context.editor.show_hierarchy = true;
                        context.editor.show_properties = true;
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
                destroy_entity(prefab);
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

    if show_hierarchy
    then draw_all_entities_hierarchy(*show_hierarchy);
    
    if show_properties
    then draw_properties(*show_properties);

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
                set_name(prefab, to_string(data(prefab_name)));
                if  parent == NULL_ENTITY
                then prefab_ref = make_ref(prefab);
                create_prefab_parent_ref = .{};
                set_parent(prefab, parent);
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
}

save_prefab_and_close :: () {
    using context.editor;
    save_prefab();
    prefab := resolve_ref(*prefab_ref);
    destroy_entity(prefab);
    ImGui.CloseCurrentPopup();
    prefab = NULL_ENTITY;
    prefab_ref = .{};
    selected_ref = .{};
}

save_prefab :: () {
    using context.editor;
    prefab := resolve_ref(*prefab_ref);
    assert(prefab != NULL_ENTITY);
    builder : String_Builder;
    slz_entity(*builder, prefab ,,temp);
    write_entire_file(tprint("assets/%.prefab", get_name(prefab) ,,temp), builder_to_string(*builder, prefab ,,temp));
}

#scope_file

update_clone_shortcut :: () {
    using context.editor;
    if is_key_down(.LCTRL) && is_key_down(#char "D" ) {
        if !clone_pressed {
            entity := resolve_ref(*context.editor.selected_ref);
            if entity != NULL_ENTITY {
                clone_entity(entity);
            }
            clone_pressed = true;
        }
    } else if clone_pressed {
        clone_pressed = false;
    }
}

#load "editor_props.jai";

// Panels
#load "panels/hierarchy.jai";
#load "panels/properties.jai";

} // #if IMGUI && EDITOR