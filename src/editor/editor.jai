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
                show_create_prefab = true;
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
                prefab := scene.entity_procs.create(scene.slot, to_string(data(prefab_name)));
                //#REVIEW_asuarez Until we have editor we are going to serialize directly the entity
                scene.entity_procs.serialize(prefab);
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

} //#if IMGUI