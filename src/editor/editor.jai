#if EDITOR {

TEXT_BUFF_SIZE :: 100;

TextBuff :: [TEXT_BUFF_SIZE] u8;

data :: (buff : TextBuff) -> *u8 { 
    return *buff[0];
}

Editor :: struct {
    show_demo           : bool;
    prefab_name         : TextBuff;
    prefab_type         : PrefabEditorType;
    prefab              : *Entity;
    show_create_prefab  : bool;
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
                        if context.editor.prefab {
                            immediate_destroy_entity(context.editor.prefab, true);
                            context.editor.prefab = null;
                        }
                        prefab_str, success := read_entire_file(info.full_name ,,temp);
                        assert(success);
                        context.editor.prefab = deserialize_entity_recursive(prefab_str);
                    }
                });
                ImGui.EndMenu();
            }
            if prefab && ImGui.MenuItem("Save and Close") {
                save_prefab_and_close();
            }
            if prefab && ImGui.MenuItem("Close") {
                immediate_destroy_entity(prefab, true);
                prefab = null;
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
            
            if scene && c_style_strlen(data(prefab_name)) > 0 {
                if prefab {
                    destroy_entity(prefab);
                    prefab = null;
                }
                prefab = scene.entity_procs.create(scene.slot, to_string(data(prefab_name)));
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
    assert(prefab != null);
    builder : String_Builder;
    serialize_entity_recursive(prefab, *builder);
    write_entire_file(tprint("assets/%.prefab", prefab.tag ,,temp), *builder);
    immediate_destroy_entity(prefab, true);
    ImGui.CloseCurrentPopup();
    prefab = null;
}

} //#if IMGUI