#import "SDL";

SDLContext :: struct {
    initialized  := false;
    window_count := 0;
}

sdl_initialized :: () -> bool {
    return context.sdl.initialized;
}

create_sdl_window :: (title: *u8, x: s32, y: s32, w: s32, h: s32, flags: SDL_WindowFlags) -> *SDL_Window {
    InitializeSDL();
    state.window_count += 1;
    return SDL_CreateWindow(title, x, y, xx w, xx h, flags);
}

destroy_sdl_window :: (window: *SDL_Window) {
    assert(window != null);
    InitializeSDL();
    assert(state.window_count > 0);
    state.window_count -= 1;
    if state.window_count == 0 {
        FinishSDL();
    }
}

#scope_file

#import "SDL";

#add_context sdl : SDLContext;

InitializeSDL :: () #expand {

    `state := *context.sdl;
    if state.initialized then return;
    SDL_FLAGS :: SDL_INIT_VIDEO;
    SDL_Init(SDL_FLAGS);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);
    state.initialized = true;
}

FinishSDL :: () #expand {
    `state := *context.sdl;
    state.initialized = false;
    SDL_Quit();
}