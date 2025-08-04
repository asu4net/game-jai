PROCESS_EVENTS_PROC :: #type (event : SDL_Event);

Engine_State :: struct {
    done           : bool;
    window         : *SDL_Window;
    screen_width   : int;
    screen_height  : int;
    process_events : PROCESS_EVENTS_PROC;
    gl_ctx         : SDL_GLContext;
}

#add_context engine: *Engine_State;

#run #if !DEBUG then disable_runtime_console();

engine_run :: (name := DEF_APP_NAME, width := DEF_SCREEN_WIDTH, height := DEF_SCREEN_HEIGHT, process_events_proc : PROCESS_EVENTS_PROC = null) -> bool {
    
    if context.engine then engine_shutdown();
    context.engine = New(Engine_State);
    using state := context.engine;
    
    set_working_directory(String.path_strip_filename(System.get_path_of_running_executable()));
    
    sdl_inited := SDL_Init(SDL_INIT_VIDEO);
    if !sdl_inited {
        log_error("Failed to init SDL.");
        return false;
    }
    
    window = SDL_CreateWindow(name.data, xx width, xx height, SDL_WINDOW_OPENGL);
    
    if !window {
        log_error("Failed to create the window.");
        return false;
    }

    SDL_GL_SetAttribute(.SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
    SDL_GL_SetAttribute(.SDL_GL_CONTEXT_MAJOR_VERSION, OPEN_GL_MAJOR);
    SDL_GL_SetAttribute(.SDL_GL_CONTEXT_MINOR_VERSION, OPEN_GL_MINOR);

    gl_ctx = SDL_GL_CreateContext(window);

    if !gl_ctx {
        log_error("Failed to create the OpenGL context.");
        return false;
    }

    SDL_SetWindowResizable(window, true);
    screen_width   = width;
    screen_height  = height;
    process_events = process_events_proc;
    
    //gl_create_context(win = window, major_version = OPEN_GL_MAJOR, minor_version = OPEN_GL_MINOR, compatibility = false, debug = DEBUG);
    //gl_load(*gl);
    
    SDL_GL_MakeCurrent(window, gl_ctx);
    SDL_GL_SetSwapInterval(1);
    gl_load(*gl, xx SDL_GL_GetProcAddress);

    #if DEBUG {
        log("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
        log("GL Version = %\n", to_string(glGetString(GL_VERSION)));
        gl_enable_debug_output(break_on_error = true);
        DumpGLErrors(tag = "context");
    }

    SDL_GL_SetSwapInterval(1);
    set_clear_color(DARK_GREY);
    #if IMGUI then imgui_init(window, *gl_ctx);
    init_renderer2d();

    return true;
}

engine_shutdown :: () -> bool {
    using state := context.engine;
    if !state then return false;
    context.engine = null;

    assert(window != null);
    SDL_DestroyWindow(window);
    SDL_Quit();
    deinit_renderer2d();
    #if IMGUI then imgui_deinit();
    free(state);

    #if DEBUG {
        report_memory_leaks();
    }
    return true;
}

engine_keep_running :: () -> bool {
    using engine := context.engine;
    flush_renderer2d();
    #if IMGUI then imgui_end_draw();
    SDL_GL_SwapWindow(window);
    time_step();
    event : SDL_Event;

    while SDL_PollEvent(*event) {
        #if IMGUI then imgui_process_events(*event);
        if event.type == {
            
            case xx SDL_EventType.WINDOW_RESIZED;
                screen_width  = event.window.data1;
                screen_height = event.window.data2;

            case xx SDL_EventType.QUIT;
                done = true;

            case xx SDL_EventType.KEY_DOWN;
            #if DEBUG {
                if event.key.key == SDLK_ESCAPE
                then done = true;
            }
            case;
        }
        if process_events then process_events(event);
    }

    camera := *context.renderer2d.camera;
    camera.viewport_w = screen_width;
    camera.viewport_h = screen_height;

    clear_screen();
    #if IMGUI then imgui_begin_draw();
    return !done;
}

is_key_down :: (input : SDL_Scancode) -> bool {
    numkeys : s32;
    state := SDL_GetKeyboardState(*numkeys);
    return state[input];
}

#scope_file

#import "Input";
#import "SDL3";