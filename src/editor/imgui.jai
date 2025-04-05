#if IMGUI {

ImGuiManager :: struct {
    ctx : *ImGui.ImGuiContext;
}

#add_context imgui : ImGuiManager;

init_imgui :: () {
    
    using context.imgui;
    assert(ctx == null);
    ctx = ImGui.CreateContext();
    
    io := ImGui.GetIO();
    
    //#REVIEW this font looks ugly for some reason
    /*
    FONT_LOCATION :: "assets/fonts/AlbertSans-VariableFont_wght.ttf";
    FONT_SIZE     :: 20;

    if file_exists(FONT_LOCATION) then io.Fonts.AddFontFromFileTTF(io.Fonts, FONT_LOCATION, FONT_SIZE);
    */

    io.ConfigFlags_ |= .DockingEnable;
    io.ConfigFlags_ |= .ViewportsEnable;

    ImGui.StyleColorsDark();

    using style := ImGui.GetStyle();

    TabBarOverlineSize = 0;
    FrameRounding = 9;
    
    Colors[xx ImGui.Col.DockingEmptyBg]     = .{ 0.000, 0.000, 0.000, 0.000 };
    Colors[xx ImGui.Col.WindowBg]           = .{ 0.192, 0.200, 0.219, 1.000 };
    Colors[xx ImGui.Col.TabUnfocusedActive] = .{ 0.168, 0.176, 0.192, 1.000 };
    Colors[xx ImGui.Col.Tab]                = .{ 0.168, 0.176, 0.192, 1.000 };
    Colors[xx ImGui.Col.TabHovered]         = .{ 0.656, 0.656, 0.656, 1.000 };
    Colors[xx ImGui.Col.TabActive]          = .{ 0.211, 0.215, 0.239, 1.000 };
    Colors[xx ImGui.Col.TitleBg]            = .{ 0.168, 0.176, 0.192, 1.000 };
    Colors[xx ImGui.Col.TitleBgActive]      = .{ 0.100, 0.100, 0.100, 1.000 };
    Colors[xx ImGui.Col.FrameBg]            = .{ 0.100, 0.100, 0.100, 1.000 };
    Colors[xx ImGui.Col.Button]             = .{ 0.356, 0.356, 0.416, 1.000 };
}

begin_imgui_draw :: () {
    assert(context.window.handle != null);
    
    ImGui_ImplSdl_NewFrame(context.window.handle);
    ImGui.NewFrame();
    
    // Dockspace
    {
        viewport := ImGui.GetMainViewport();

        ImGui.SetNextWindowPos(viewport.WorkPos);
        ImGui.SetNextWindowSize(viewport.WorkSize);
        ImGui.SetNextWindowViewport(viewport.ID_);
        ImGui.PushStyleVar(.WindowRounding, 0);
        ImGui.PushStyleVar(.WindowBorderSize, 0);
        ImGui.PushStyleVar(.WindowPadding, ZERO_2D);

        window_flags : ImGui.WindowFlags;
        window_flags |= .NoDocking;
        window_flags |= .MenuBar;
        window_flags |= .NoTitleBar;
        window_flags |= .NoCollapse;
        window_flags |= .NoResize;
        window_flags |= .NoMove;
        window_flags |= .NoBringToFrontOnFocus;
        window_flags |= .NoNavFocus;
        window_flags |= .NoBackground;

        ImGui.Begin("Dockspace Window", null, window_flags);
        
        ImGui.PopStyleVar(3);
        assert(xx ImGui.GetIO().ConfigFlags_ & .DockingEnable);

        ImGui.DockSpace(ImGui.GetID("Dockspace"), size = ZERO_2D);
    }

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

end_imgui_draw :: () {
    ImGui.End(); // Dockspace Window
    ImGui.Render();
    ImGui_ImplSdl_RenderDrawLists(ImGui.GetDrawData());
}

process_imgui_sdl_events :: (event: *SDL_Event) {
    ImGui_ImplSdl_ProcessEvent(event);
}

deinit_imgui :: () {
    assert(context.imgui.ctx != null);
    ImGui_ImplSdl_Shutdown();
    ImGui.DestroyContext(context.imgui.ctx);
}

} // #if IMGUI