Window :: struct {
    handle      : *SDL_Window;
    gl_context  : SDL_GLContext;
    title       : string;
    width       : s32;
    height      : s32;
    initialized : bool;
    keep_opened : bool;
    
    //#REVIEW_asuarez I don't like this being part of the window struct.
    // Maybe I should remove SDL events from here..?
    // Detach this completly from the window class mybe it is a good idea. 
    #if IMGUI {
        imgui_ctx : *ImGui.ImGuiContext;
        show_demo_window := true;
    }
}

init :: (window : *Window, title := "Game", width := 1280, height := 720, v_sync := true) -> bool {

    assert(!is_window_init(window));
    
    WINDOW_POS   :: SDL_WINDOWPOS_UNDEFINED;
    WINDOW_FLAGS :: SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE;
    
    window.handle = create_sdl_window(title.data, WINDOW_POS, WINDOW_POS, xx width, xx height, WINDOW_FLAGS);

    if window.handle == null {
        log("Could not create window: %\n", to_string(SDL_GetError()));
        assert(false);
        return false;
    }

    window.title  = title;
    window.width  = xx width;
    window.height = xx height;

    window.gl_context = SDL_GL_CreateContext(window.handle);

    if window.gl_context == null {
        log_error("Could not create OpenGL context: %\n", to_string(SDL_GetError()));
        assert(false);
        return false;
    }

    gl_load(*gl, SDL_GL_GetProcAddress);

    log ("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
    log ("GL Version = %\n", to_string(glGetString(GL_VERSION)));

    window.initialized = true;
    window.keep_opened = true;

    #if IMGUI {
        imgui_context := ImGui.CreateContext();
        io := ImGui.GetIO();
        io.ConfigFlags_ |= ImGui.ConfigFlags.DockingEnable;
    }

    return true;
}

is_window_init :: (window : *Window) -> bool {
    assert(window != null);
    return window.initialized;
}

close_window :: (window : *Window) {
    assert(is_window_init(window));
    window.keep_opened = false;
}

keep_window_opened :: (window : *Window) -> bool {
    assert(is_window_init(window));
    SDL_GL_MakeCurrent(window.handle, window.gl_context);
    SDL_GL_SwapWindow(window.handle);
    poll_events(window);
    //#TODO_asuarez Time stuff.
    return window.keep_opened;
}

draw_imgui :: (window : *Window) {
    assert(is_window_init(window));
    
    #if IMGUI {

        ImGui_ImplSdl_NewFrame(window.handle);
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
    
        // 3. Show the ImGui demo window. Most of the sample code is in ImGui.ShowDemoWindow().
        if window.show_demo_window {
            ImGui.SetNextWindowPos(.{650, 20}, ImGui.Cond.FirstUseEver, .{0,0}); // Normally user code doesn't need/want to call this because positions are saved in .ini file anyway. Here we just want to make the demo initial state a bit more friendly!
            ImGui.ShowDemoWindow(*window.show_demo_window);
        }

        // Rendering
        ImGui.Render();
        ImGui_ImplSdl_RenderDrawLists(ImGui.GetDrawData());
    }
}

deinit :: (window : *Window) {
    assert(is_window_init(window));
    
    #if IMGUI {
        ImGui_ImplSdl_Shutdown();
        ImGui.DestroyContext(window.imgui_ctx);
    }
    
    destroy_sdl_window(window);
    window.* = .{};
}

#scope_file

poll_events :: (window : *Window) {
    assert(is_window_init(window));
    event : SDL_Event;
    while SDL_PollEvent(*event) {
        ImGui_ImplSdl_ProcessEvent(*event);
        if event.type == {
            case SDL_KEYUP;
                if event.key.keysym.sym == SDLK_ESCAPE window.keep_opened = false;
            case SDL_WINDOWEVENT;
                if event.window.event == SDL_WINDOWEVENT_CLOSE {
                    window.keep_opened = false;
                }
                if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED {
                    window.width  = event.window.data1;
                    window.height = event.window.data2;
                }
        }
    }
}