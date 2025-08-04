ImGui_State :: struct {
    ctx: ImGui.ImGuiContext; 
    drawing: bool;
}

#add_context imgui: *ImGui_State;

imgui_init :: (window: *SDL_Window, gl_ctx : *SDL_GLContext) {
    using imgui := context.imgui;
    if imgui then imgui_deinit(); 
    context.imgui = New(ImGui_State);

    ctx = ImGui.CreateContext();
    io := ImGui.GetIO();
    io.ConfigFlags_ |= .NavEnableKeyboard;     // Enable Keyboard Controls
    io.ConfigFlags_ |= .NavEnableGamepad;      // Enable Gamepad Controls
    io.ConfigFlags_ |= .DockingEnable;         // Enable Docking
    io.ConfigFlags_ |= .ViewportsEnable;       // Enable Multi-Viewport / Platform Windows
    style := ImGui.GetStyle();
    frame_bg_col := *style.Colors[ImGui.Col.TabActive]; 
    frame_bg_col.w = 0.2;
    
    if io.ConfigFlags_ & .ViewportsEnable {
        style.WindowRounding = 0.0;
        style.Colors[ImGui.Col.WindowBg].w = 0.5;
        style.Colors[ImGui.Col.DockingEmptyBg] = .{0, 0, 0, 0};
    }
    ImGui.ImplSDL3_InitForOpenGL(window, gl_ctx);
    ImGui.ImplOpenGL3_Init();
}

imgui_deinit :: () {
    using imgui := context.imgui;
    if !imgui then return;
    context.imgui = null;
    ImGui.ImplSDL3_Shutdown();
    free(imgui);
}

imgui_process_events :: inline (event : SDL_Event) {
    ImGui.ImplSDL3_ProcessEvent(*event);
}

imgui_begin_draw :: () {
    ImGui.ImplOpenGL3_NewFrame();
    ImGui.ImplSDL3_NewFrame();
    ImGui.NewFrame();

    //---------------------------
    //:DOCKSPACE
    //---------------------------
    
    if ImGui.GetIO().ConfigFlags_ & .DockingEnable {

        viewport := ImGui.GetMainViewport();
        ImGui.SetNextWindowPos(viewport.WorkPos);
        ImGui.SetNextWindowSize(viewport.WorkSize);
        ImGui.SetNextWindowViewport(viewport.ID_);

        ImGui.PushStyleVar(.WindowRounding, 0);
        ImGui.PushStyleVar(.WindowBorderSize, 0);
        ImGui.PushStyleVar(.WindowPadding, Vector2.{0, 0});

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
        ImGui.DockSpace(ImGui.GetID("Dockspace"), size = .{0, 0});
    }
    context.imgui.drawing = true;
}

imgui_end_draw :: () {
    if !context.imgui.drawing then return;

    if ImGui.GetIO().ConfigFlags_ & .DockingEnable
    then ImGui.End(); // Viewport end.

    ImGui.Render(); 
    ImGui.ImplOpenGL3_RenderDrawData(ImGui.GetDrawData());
        
    // Update and Render additional Platform Windows
    // (Platform functions may change the current OpenGL context, so we save/restore it to make it easier to paste this code elsewhere.
    //  For this specific demo app we could also call SDL_GL_MakeCurrent(window, gl_context) directly)
        
    if (ImGui.GetIO().ConfigFlags_ & .ViewportsEnable) {
        backup_current_window := SDL_GL_GetCurrentWindow();
        backup_current_context := SDL_GL_GetCurrentContext();
        ImGui.UpdatePlatformWindows();
        ImGui.RenderPlatformWindowsDefault();
        SDL_GL_MakeCurrent(backup_current_window, backup_current_context);
    }
}