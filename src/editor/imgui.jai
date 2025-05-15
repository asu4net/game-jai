#if IMGUI {

ImGuiManager :: struct {
    draw_proc : IMGUI_DRAW_PROC;
}

#add_context imgui : ImGuiManager;

init_imgui :: (imgui_draw_proc : IMGUI_DRAW_PROC = null) {
    
    using context.imgui;
    draw_proc = imgui_draw_proc;

    ImGui_Impl_CreateContext();
    
    io := ImGui.GetIO();

    FONT_LOCATION :: "assets/fonts/OpenSans-BoldItalic.ttf";
    FONT_SIZE     :: 20;

    if file_exists(FONT_LOCATION) then io.Fonts.AddFontFromFileTTF(io.Fonts, FONT_LOCATION, FONT_SIZE);

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
    //Colors[xx ImGui.Col.ModalWindowDimBg]   = .{ 0.000, 0.000, 0.000, 0.000 };

    ImGui_Impl_Init(context.window.handle);
}

IMGUI_DRAW_PROC :: #type ();

process_imgui_events :: inline (event : Input.Event) {
    ImGui_Impl_ProcessEvent(event);
}   

draw_imgui :: () {
    assert(context.window.handle != null);
    using context.imgui;
    ImGui_Impl_NewFrame(context.window.width, context.window.height);
    
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
    
    if context.imgui.draw_proc
    then context.imgui.draw_proc();
    
    ImGui.End(); // Dockspace Window
    ImGui.Render();
    ImGui_Impl_RenderDrawData();
}

deinit_imgui :: () {
    ImGui_Impl_Shutdown();
}

} // #if IMGUI