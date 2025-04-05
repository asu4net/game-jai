#if EDITOR {

Editor :: struct {
    menus : [..] Menu;
}

#add_context editor : Editor;

init_editor :: () {
    add_menu("ImGui", draw_imgui_menu);
    add_menu("Prefab", draw_prefab_menu);
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

    draw_demo_screen();
}

} //#if IMGUI