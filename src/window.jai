Window :: struct {
    done    : bool;
    handle  : *SDL_Window;
    width   : s32;
    height  : s32;    
    gl_ctx  : SDL_GLContext;
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
    
    gl_ctx := SDL_GL_CreateContext(window.handle);

    if !gl_ctx {
        log_error("SDL Failed to create the OpenGL context.");
        return;
    }

    window.gl_ctx = gl_ctx;
     
    SDL_GL_MakeCurrent(window.handle, window.gl_ctx);

    gl_load(*gl, xx SDL_GL_GetProcAddress);
    log("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
    log("GL Version = %\n", to_string(glGetString(GL_VERSION)));
    
    set_clear_color(DARK_GRAY);
}

deinit_window :: () {
    handle := context.window.handle;
    assert(handle != null);
    SDL_DestroyWindow(handle);
    SDL_Quit();
}

keep_window_opened :: () -> bool {
    SDL_GL_SwapWindow(context.window.handle);
    process_window_events();
    return !context.window.done;
}

process_window_events :: () {

    window := *context.window;
    event : SDL_Event;
    
    while SDL_PollEvent(*event) {
        
        #if IMGUI then process_imgui_sdl_events(*event);
        
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

is_key_down :: (input : SDL_Scancode) -> bool {
    numkeys : s32;
    state := SDL_GetKeyboardState(*numkeys);
    return state[input];
}

#scope_file

#import "GL" (DUMP_GL_ERRORS = DEBUG);