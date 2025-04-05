#if EDITOR {

MENU_DRAW_PROC :: #type ();

Menu :: struct {
    opened : bool;
    draw   : MENU_DRAW_PROC;
}

add_menu :: (name : string, draw : MENU_DRAW_PROC) {
    using context.editor;
    assert(name.count > 0);
    table_add(*menus, name, .{ draw = draw });
}

Editor :: struct {
    menus : Table(string, Menu);
}

#add_context editor : Editor;

init_editor :: () {

}

deinit_editor :: () {
    using context.editor;
    deinit(*menus);
}

draw_editor :: () {
    using context.editor;
    /*  
    if ImGui.BeginMenuBar() {
        if ImGui.BeginMenu("ImGui") {
            ImGui.Checkbox("Show demo window", *show_demo_window);
            ImGui.EndMenu();
        }
        if ImGui.BeginMenu("Prefabs") {
            ImGui.Checkbox("Show demo window", *show_demo_window);
            ImGui.EndMenu();
        }
        ImGui.EndMenuBar();
    }

    if show_demo_window {
        ImGui.SetNextWindowPos(.{650, 20}, ImGui.Cond.FirstUseEver, .{0,0});
        ImGui.ShowDemoWindow(*show_demo_window);
    }
    */
}

} //#if IMGUI