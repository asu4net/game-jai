//#TODO_asuarez Improve the impl procs here.

DRAW_PROC :: #type ();

ImGuiManager :: struct {
    draw_proc : DRAW_PROC;
}

#add_context imgui : ImGuiManager;

Init :: (imgui_draw_proc : DRAW_PROC = null) {
    
    using context.imgui;
    draw_proc = imgui_draw_proc;

    Impl_CreateContext();
    
    io := GetIO();

    FONT_LOCATION :: "assets/fonts/OpenSans-BoldItalic.ttf";
    FONT_SIZE     :: 20;

    if file_exists(FONT_LOCATION) then io.Fonts.AddFontFromFileTTF(io.Fonts, FONT_LOCATION, FONT_SIZE);

    io.ConfigFlags_ |= .DockingEnable;
    io.ConfigFlags_ |= .ViewportsEnable;

    
    StyleColorsDark();

    using style := GetStyle();

    TabBarOverlineSize = 0;
    FrameRounding = 9;
    
    Colors[xx Col.DockingEmptyBg]     = .{ 0.000, 0.000, 0.000, 0.000 };
    
    Colors[xx Col.WindowBg]           = .{ 0.192, 0.200, 0.219, 1.000 };
    Colors[xx Col.TabUnfocusedActive] = .{ 0.168, 0.176, 0.192, 1.000 };
    Colors[xx Col.Tab]                = .{ 0.168, 0.176, 0.192, 1.000 };
    Colors[xx Col.TabHovered]         = .{ 0.656, 0.656, 0.656, 1.000 };
    Colors[xx Col.TabActive]          = .{ 0.211, 0.215, 0.239, 1.000 };
    Colors[xx Col.TitleBg]            = .{ 0.168, 0.176, 0.192, 1.000 };
    Colors[xx Col.TitleBgActive]      = .{ 0.100, 0.100, 0.100, 1.000 };
    Colors[xx Col.FrameBg]            = .{ 0.100, 0.100, 0.100, 1.000 };
    Colors[xx Col.Button]             = .{ 0.356, 0.356, 0.416, 1.000 };
    //Colors[xx Col.ModalWindowDimBg]   = .{ 0.000, 0.000, 0.000, 0.000 };
    
    Impl_Init();
}

ProcessInputEvents :: inline (event : Input.Event) {
    Impl_ProcessEvent(event);
}   

Draw :: (time : float64) {
    using context.imgui;
    Impl_NewFrame(context.window.width, context.window.height, time);
    
    // Dockspace
    {
        viewport := GetMainViewport();

        SetNextWindowPos(viewport.WorkPos);
        SetNextWindowSize(viewport.WorkSize);
        SetNextWindowViewport(viewport.ID_);
        PushStyleVar(.WindowRounding, 0);
        PushStyleVar(.WindowBorderSize, 0);
        PushStyleVar(.WindowPadding, Vector2.{0, 0});

        window_flags : WindowFlags;
        window_flags |= .NoDocking;
        window_flags |= .MenuBar;
        window_flags |= .NoTitleBar;
        window_flags |= .NoCollapse;
        window_flags |= .NoResize;
        window_flags |= .NoMove;
        window_flags |= .NoBringToFrontOnFocus;
        window_flags |= .NoNavFocus;
        window_flags |= .NoBackground;

        Begin("Dockspace Window", null, window_flags);
        
        PopStyleVar(3);
        assert(xx GetIO().ConfigFlags_ & .DockingEnable);
        DockSpace(GetID("Dockspace"), size = .{0, 0});
    }    
    
    if context.imgui.draw_proc
    then context.imgui.draw_proc();
    
    End(); // Dockspace Window
    Render();
    Impl_RenderDrawData();
}

Deinit :: () {
    Impl_Shutdown();
}