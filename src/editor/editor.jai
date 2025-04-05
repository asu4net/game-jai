#if EDITOR {

MENU_DRAW_PROC :: #type (menu : *Menu, name : string);

Menu :: struct {
    name   : string;
    opened : bool;
    draw   : MENU_DRAW_PROC;
}

add_menu :: (name : string, draw : MENU_DRAW_PROC) {
    using context.editor;
    assert(name.count > 0);
    array_add(*menus, .{ name = name, draw = draw });
}

Editor :: struct {
    menus : [..] Menu;
}

#add_context editor : Editor;

ImGuiMenu :: struct {
    show_demo : bool;
}

init_editor :: () {

    add_menu("ImGui", (menu : *Menu, name : string) {
        ImGui.SetNextWindowPos(.{650, 20}, ImGui.Cond.FirstUseEver, .{0,0});
        ImGui.ShowDemoWindow(*menu.opened);
    });

    add_prefab_menu();
}

deinit_editor :: () {
    using context.editor;
    array_reset(*menus);
}

draw_editor :: () {
    using context.editor;

    if ImGui.BeginMenuBar() {
        for *menu : menus {
            if ImGui.BeginMenu(menu.name.data) {
                if menu.draw menu.draw(menu, menu.name);
                ImGui.EndMenu();
            }
        }
        ImGui.EndMenuBar();
    } 
}

} //#if IMGUI