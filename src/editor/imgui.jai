#if IMGUI {

show_imgui_demo_window := false;

create_imgui_context :: () -> *ImGui.ImGuiContext {
    c  := ImGui.CreateContext();
    io := ImGui.GetIO();
    io.ConfigFlags_ |= ImGui.ConfigFlags.DockingEnable;
    return c;
}

imgui_begin :: (window : *SDL_Window) {
    assert(window != null);
    ImGui_ImplSdl_NewFrame(window);
    ImGui.NewFrame();
            
    if ImGui.GetMouseCursor() == {
        case .Arrow;         SDL_SetCursor(cursor_arrow);
        case .TextInput;     SDL_SetCursor(cursor_text_input);
        case .Hand;          SDL_SetCursor(cursor_move);
        case .ResizeNS;      SDL_SetCursor(cursor_resize_ns);
        case .ResizeEW;      SDL_SetCursor(cursor_resize_ew);
        case .ResizeNESW;    SDL_SetCursor(cursor_resize_nesw);
        case .ResizeNWSE;    SDL_SetCursor(cursor_resize_nwse);
    }
}

imgui_end :: () {
    
    if show_imgui_demo_window then {
        ImGui.SetNextWindowPos(.{650, 20}, ImGui.Cond.FirstUseEver, .{0,0});
        ImGui.ShowDemoWindow(*show_imgui_demo_window);
    }

    // Rendering
    ImGui.Render();
    ImGui_ImplSdl_RenderDrawLists(ImGui.GetDrawData());
}

destroy_imgui_context :: (c : *ImGui.ImGuiContext) {
    assert(c != null);
    ImGui_ImplSdl_Shutdown();
    ImGui.DestroyContext(c);
}

}