Window :: struct {
    done    : bool;
    handle  : *SDL_Window;
    width   : s32;
    height  : s32;    
    gl_ctx  : SDL_GLContext;
    #if IMGUI imgui_ctx : ImGui.ImGuiContext; 
}

#add_context window: Window;

init_window :: (name :string = "the window", width: s32 = 1280, height: s32 = 720) {
    window := *context.window;
    
    assert(window.handle == null);

    SDL_Init(SDL_INIT_VIDEO);
    handle := SDL_CreateWindow(name.data, width, height, SDL_WINDOW_OPENGL);
    
    if !handle {
        log_error("SDL Failed to create the window.");
        return;
    }

    SDL_SetWindowResizable(handle, true);

    window.handle = handle;
    window.width  = width;
    window.height = height;

    SDL_GL_SetAttribute(.SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
    SDL_GL_SetAttribute(.SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(.SDL_GL_CONTEXT_MINOR_VERSION, 3);

    gl_ctx := SDL_GL_CreateContext(window.handle);

    if !gl_ctx {
        log_error("SDL Failed to create the OpenGL context.");
        return;
    }

    window.gl_ctx = gl_ctx;
    
    SDL_GL_MakeCurrent(window.handle, window.gl_ctx);
    SDL_GL_SetSwapInterval(1);

    gl_load(*gl, xx SDL_GL_GetProcAddress);
    log("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
    log("GL Version = %\n", to_string(glGetString(GL_VERSION)));
    
    #if IMGUI {
        window.imgui_ctx = ImGui.CreateContext();
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

        ImGui.ImplSDL3_InitForOpenGL(window.handle, window.gl_ctx);
        ImGui.ImplOpenGL3_Init();
    }

    set_clear_color(DARK_GRAY);
}

deinit_window :: () {
    #if IMGUI then ImGui.ImplSDL3_Shutdown();
    handle := context.window.handle;
    assert(handle != null);
    SDL_DestroyWindow(handle);
    SDL_Quit();
}

keep_window_opened :: () -> bool {
    SDL_GL_SwapWindow(context.window.handle);
    process_window_events();
    time_step();
    return !context.window.done;
}

process_window_events :: () {

    window := *context.window;
    event : SDL_Event;

    while SDL_PollEvent(*event) {
        
        #if IMGUI then ImGui.ImplSDL3_ProcessEvent(*event);
        
        if event.type == {
            
            case xx SDL_EventType.WINDOW_RESIZED;
                window.width  = event.window.data1;
                window.height = event.window.data2;

            case xx SDL_EventType.QUIT;
                window.done = true;

            case xx SDL_EventType.KEY_DOWN;
            #if DEBUG {
                if event.key.key == SDLK_ESCAPE
                then window.done = true;
            }
            case;
        }
    }
}

#if IMGUI {
    
    begin_draw_imgui :: () {
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
    }
    
    end_draw_imgui :: () {

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
}

is_key_down :: (input : SDL_Scancode) -> bool {
    numkeys : s32;
    state := SDL_GetKeyboardState(*numkeys);
    return state[input];
}

#scope_file

#import "GL" (DUMP_GL_ERRORS = DEBUG);
ImGui :: #import "ImGui";