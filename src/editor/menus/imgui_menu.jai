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

//----------------------------------------------------

ImGuiMenu :: struct {
    show_demo : bool;
}

imgui_menu : ImGuiMenu;

draw_imgui_menu :: (menu : *Menu, name : string) {
    ImGui.Checkbox("Show demo", *imgui_menu.show_demo);
}

draw_demo_screen :: () {
    if !imgui_menu.show_demo return;
    ImGui.SetNextWindowPos(.{650, 20}, ImGui.Cond.FirstUseEver, .{0,0});
    ImGui.ShowDemoWindow(*imgui_menu.show_demo);
}

} //#if EDITOR