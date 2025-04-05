#if EDITOR {

Editor :: struct {
    show_demo_window   := true;
    show_prefab_window := false;
}

#add_context editor : Editor;

draw_editor :: () {
    
    using context.editor;
    
    if ImGui.BeginMenuBar() then {
        ImGui.EndMenuBar();
    }

    if show_demo_window then {
        ImGui.SetNextWindowPos(.{650, 20}, ImGui.Cond.FirstUseEver, .{0,0});
        ImGui.ShowDemoWindow(*show_demo_window);
    }
}

}