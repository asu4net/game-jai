// #TODO_asuarez
// - texture options for sprite_sheet (maybe could be a struct??)
// - Optimize the 2d version of make_transform
// - Implement a bumb allocator in the renderer. (I think its the pool thing in the modules folder).
// - Intentar generalizar un poco más las llamadas de draw, convertir en función el draw header
// - Leer shaders de ficheros
// - Poder cambiar de shader
// - Dumpear errores de OpenGL
// - Implementar frame buffer y renderizar a una textura (Con esto se pueden meter FX de cámara)
// - Picking
// - Sistema de iluminación: Ambient y Point lights

Game :: struct {
    done       : bool;
    window     : *SDL_Window;
    gl_ctx     : SDL_GLContext;
    draw_2d    : Draw2D_Context;
    viewport_w : s32 = 1920;
    viewport_h : s32 = 1080;    
}

#add_context game: Game;

main :: () {
    
    using context.game;
    
    defer report_memory_leaks();

    path := path_strip_filename(get_path_of_running_executable());
    set_working_directory(path);

    SDL_Init(SDL_INIT_VIDEO);
    defer SDL_Quit();
    
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, xx SDL_GL_CONTEXT_PROFILE_CORE);
    WINDOW_POS :: SDL_WINDOWPOS_UNDEFINED;
    window = SDL_CreateWindow("game", WINDOW_POS, WINDOW_POS, viewport_w, viewport_h, SDL_WINDOW_OPENGL);
    
    if !window {
        log_error("SDL Failed to create the window.");
        return;
    }

    defer SDL_DestroyWindow(window);
    
    gl_ctx = SDL_GL_CreateContext(window);

    if !gl_ctx {
        log_error("SDL Failed to create the OpenGL context.");
        return;
    }

    SDL_GL_MakeCurrent(window, gl_ctx);

    gl_load(*gl, SDL_GL_GetProcAddress);
    log("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
    log("GL Version = %\n", to_string(glGetString(GL_VERSION)));

    #if IMGUI then {
        init_imgui();
        defer deinit_imgui();
    }

    init(*draw_2d);
    defer deinit(*draw_2d);
    
    set_clear_color(DARK_GRAY);

    while !done {

        // Poll the window events
        {
            event : SDL_Event;
        
            while SDL_PollEvent(*event) {
                
                #if IMGUI then process_imgui_sdl_events(*event);
                
                if event.type == {
                    case SDL_KEYUP;
                        if event.key.keysym.sym == SDLK_ESCAPE then {
                            done = true;
                        }
                    case SDL_WINDOWEVENT;
                        if event.window.event == SDL_WINDOWEVENT_CLOSE then {
                            done = true;
                        }
                        else if event.window.event == SDL_WINDOWEVENT_SIZE_CHANGED then {
                            viewport_w = event.window.data1;
                            viewport_h = event.window.data2;
                        }
                }
            }
        }

        clear_screen();

        //#TODO_asuarez Here draw the game
        
        #if IMGUI then {
            begin_imgui_draw(window);
            draw_editor();
            end_imgui_draw();
        } 

        SDL_GL_SwapWindow(window);
        reset_temporary_storage();
    }
}

// Modules
#import "Basic"()(MEMORY_DEBUGGER=true);
#import "System";
#import "Compiler";
#import "String";
#import "Hash_Table";
#import "Math";
#import "File";
#import "File_Utilities";

// Vendor Modules
#import "SDL";
#import "GL" (DUMP_GL_ERRORS = true);
#import "stb_image";
#import "stb_truetype";
#import "stb_image_write";
#import "Jaison";

#if IMGUI then {
    ImGui :: #import "ImGui";
}

// Utils
#load "utils/constants.jai";
#load "utils/math.jai";
#load "utils/queue.jai";
#load "utils/sparse_set.jai";

// Editor
#if EDITOR then {
    #load "editor/editor.jai";
}

#if IMGUI then {
    #load "editor/imgui_sdl_gl.jai";
    #load "editor/imgui.jai";
}

// Entity
#load "entity/scene.jai";
#load "entity/entity.jai";

// Graphics
#load "graphics/constants.jai";
#load "graphics/draw_2d.jai";
#load "graphics/api.jai";
#load "graphics/buffer_object.jai";
#load "graphics/shader.jai";
#load "graphics/texture.jai";
#load "graphics/font.jai";
#load "graphics/render_camera.jai";
#load "graphics/spritesheet.jai";