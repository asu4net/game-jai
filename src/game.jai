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

GAME_NAME :: "Game";

main :: () {

    defer report_memory_leaks();
    
    path := path_strip_filename(get_path_of_running_executable());
    set_working_directory(path);

    init_window(GAME_NAME);
    defer deinit_window();
    
    init_draw_2d();
    defer deinit_draw_2d();

    #if IMGUI then {
        init_imgui();
        defer deinit_imgui();
    }
    
    set_clear_color(DARK_GRAY);

    while !context.window.done {

        process_window_events();
        clear_screen();
        
        //#TODO_asuarez Here draw the game

        #if IMGUI then {
            begin_imgui_draw();
            draw_editor();
            end_imgui_draw();
        } 

        swap_buffers();
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

#load "window.jai";

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