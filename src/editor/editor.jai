#if EDITOR {

TEXT_BUFF_SIZE :: 100;

TextBuff :: [TEXT_BUFF_SIZE] u8;

data :: (buff : TextBuff) -> *u8 { 
    return *buff[0];
}

Editor :: struct {
    show_demo           : bool;
    prefab_name         : TextBuff;
    prefab              : Entity = NULL_ENTITY;
    show_create_prefab  : bool;
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
                        if context.editor.prefab {
                            immediate_destroy_entity(context.editor.prefab);
                            context.editor.prefab = NULL_ENTITY;
                        }
                        prefab_str, success := read_entire_file(info.full_name ,,temp);
                        assert(success);
                        //context.editor.prefab = deserialize_entity_recursive(prefab_str);
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
            
            if c_style_strlen(data(prefab_name)) > 0 {
                if prefab != NULL_ENTITY {
                    destroy_entity(prefab);
                    prefab = NULL_ENTITY;
                }
                prefab = create_entity();
                tag := add_component(Tag_Component, prefab);
                tag.text = to_string(data(prefab_name));
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

    if prefab {
        ImGui.Begin("Properties");
        //scene.entity_procs.draw_editor(prefab);
        ImGui.End();
    }
}

save_prefab_and_close :: () {
    using context.editor;
    save_prefab();
    immediate_destroy_entity(prefab);
    ImGui.CloseCurrentPopup();
    prefab = NULL_ENTITY;
}

save_prefab :: () {
    using context.editor;
    assert(prefab != NULL_ENTITY);
    tag := get_component(Tag_Component, prefab);
    write_entire_file(tprint("assets/%.prefab", tag.text ,,temp), serialize_entity(prefab ,,temp));
}

} //#if IMGUI