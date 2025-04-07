Window :: struct {
    done    : bool;
    handle  : *SDL_Window;
    width   : s32;
    height  : s32;    
    gl_ctx  : SDL_GLContext;
}

#add_context window: Window;

init_window :: (name :string = "the window", w: s32 = 1920, h: s32 = 1080) {
    using context.window;
    assert(handle == null);
    
    width  = w;
    height = h;

    SDL_Init(SDL_INIT_VIDEO);
    
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);
    WINDOW_POS :: SDL_WINDOWPOS_UNDEFINED;
    handle = SDL_CreateWindow(name.data, WINDOW_POS, WINDOW_POS, width, height, SDL_WINDOW_OPENGL | SDL_WINDOW_RESIZABLE);
    
    if !handle {
        log_error("SDL Failed to create the window.");
        return;
    }

    gl_ctx = SDL_GL_CreateContext(handle);

    if !gl_ctx {
        log_error("SDL Failed to create the OpenGL context.");
        return;
    }

    SDL_GL_MakeCurrent(handle, gl_ctx);

    gl_load(*gl, SDL_GL_GetProcAddress);
    log("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
    log("GL Version = %\n", to_string(glGetString(GL_VERSION)));
    
    set_clear_color(DARK_GRAY);
}

swap_buffers :: () {
    using context.window;
    SDL_GL_SwapWindow(handle);
} 

deinit_window :: () {
    using context.window;
    assert(handle != null);
    SDL_DestroyWindow(handle);
    SDL_Quit();
}

process_window_events :: () {

    using context.window;
    event : SDL_Event;
    
    while SDL_PollEvent(*event) {
        
        #if IMGUI then process_imgui_sdl_events(*event);
        
        if event.type == {
            
            case SDL_KEYUP;
            {
                if event.key.keysym.sym == SDLK_ESCAPE then {
                    done = true;
                }
            }
            
            case SDL_WINDOWEVENT;
            {
                if event.window.event == SDL_WINDOWEVENT_CLOSE then {
                    done = true;
                }
                else if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED then {
                    width  = event.window.data1;
                    height = event.window.data2;
                }
            }
        }
    }
}