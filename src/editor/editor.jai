#if EDITOR {

Editor :: struct {
    show_demo        : bool;
    prefab_name      : string;
    prefab_name_buff : [100] u8;
}

#add_context editor : Editor;

init_editor :: () {
    using context.editor;
    prefab_name.data  = prefab_name_buff.data;
    prefab_name.count = 100;
}

deinit_editor :: () {
}

draw_editor :: () {
    using context.editor;

    if ImGui.BeginMenuBar() 
    {
        if ImGui.BeginMenu("ImGui")
        {
            ImGui.Checkbox("Show demo", *show_demo);
            ImGui.EndMenu();
        }
        if ImGui.BeginMenu("Prefab") 
        {
            if ImGui.MenuItem("New") 
            {
                
            }
            ImGui.EndMenu();
        }
        ImGui.EndMenuBar();
    }

    if show_demo {
        ImGui.OpenPopup("Create Prefab");
        //ImGui.SetNextWindowPos(.{650, 20}, ImGui.Cond.FirstUseEver, .{0,0});
        //ImGui.ShowDemoWindow(*show_demo);
    }
    
    ImGui.PushStyleColor(.ImGuiCol_PopupBg, .{ 0.192, 0.2, 0.219, 1 });
    if ImGui.BeginPopupModal("Create Prefab") 
    {
        ImGui.InputText("Name", prefab_name.data, xx prefab_name.count);
        if ImGui.Button("Create") 
        {
            // vamos a ir por todos los miembros del enum de scenes 
            // y comprobando si tienen un array de entidades asociado.
        }
        ImGui.EndPopup();
    }
    ImGui.PopStyleColor();
}

} //#if IMGUI