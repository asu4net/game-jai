Window :: struct {
    handle      : *SDL_Window;
    gl_context  : SDL_GLContext;
    title       : string;
    width       : s32;
    height      : s32;
    initialized : bool;
    keep_opened : bool;
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
        log("Could not create OpenGL context: %\n", to_string(SDL_GetError()));
        assert(false);
        return false;
    }

    gl_load(*gl, SDL_GL_GetProcAddress);

    log ("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
    log ("GL Version = %\n", to_string(glGetString(GL_VERSION)));

    window.initialized = true;
    window.keep_opened = true;

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
    //TODO: Time
    return window.keep_opened;
}

deinit :: (window : *Window) {
    assert(is_window_init(window));
    destroy_sdl_window(window);
    window.* = .{};
}

#scope_file

poll_events :: (window : *Window) {
    assert(is_window_init(window));
    event : SDL_Event;
    while SDL_PollEvent(*event) {
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