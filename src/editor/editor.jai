#if EDITOR {

TEXT_BUFF_SIZE :: 100;

TextBuff :: [TEXT_BUFF_SIZE] u8;

data :: (buff : TextBuff) -> *u8 { 
    return *buff[0];
}

text_is_empty :: (buff : TextBuff) -> bool {
    return buff[0] == #char "\0";
}

text_len :: (buff : TextBuff) -> int {
    len := 0;
    while buff[len] != #char "\0" {
        len+=1;
    }
    return len;
}

Editor :: struct {
    show_demo           : bool;
    prefab_name         : TextBuff;
    prefab_type         : string;
    prefab_type_index   : int;
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
        prefab_types : [..] string;
        
        for scene : scenes {
            if !scene continue;
            array_add(*prefab_types, scene.type.name ,,temp);
        }

        if prefab_type.count == 0 {
           prefab_type = prefab_types[0]; 
        }

        if ImGui.BeginCombo("Type", to_c_string(prefab_type ,,temp)) {
            for type, i : prefab_types {
                if ImGui.Selectable(to_c_string(type ,,temp)) {
                    prefab_type = type;
                    prefab_type_index = i;
                }
            }
            ImGui.EndCombo();
        }
        
        if ImGui.Button("Create") {
            show_create_prefab = false;
            scene := scenes[prefab_type_index];
            
            if scene && !text_is_empty(prefab_name) {
                prefab := scene.make_prefab(scene, to_string(data(prefab_name), text_len(prefab_name)));
                print("%", prefab.tag);
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