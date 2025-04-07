#if EDITOR {

TEXT_BUFFER_SIZE :: 100;

Editor :: struct {
    show_demo           : bool;
    prefab_name         : string;
    prefab_name_buff    : [TEXT_BUFFER_SIZE] u8;
    show_create_prefab  : bool;
}

#add_context editor : Editor;

init_editor :: () {
    using context.editor;
    prefab_name.data  = prefab_name_buff.data;
    prefab_name.count = TEXT_BUFFER_SIZE;
}

deinit_editor :: () {
}

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
    if ImGui.BeginPopupModal("Create Prefab", flags = .NoResize | .NoMove)  {
        ImGui.InputText("Name", prefab_name.data, xx prefab_name.count);
        if ImGui.Button("Create") {
            show_create_prefab = false;
            ImGui.CloseCurrentPopup();
        }
        ImGui.EndPopup();
    }
    ImGui.PopStyleColor();

}

} //#if IMGUI