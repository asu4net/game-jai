#load "dependencies.jai";

GAME_NAME :: "Game";

Scenes :: enum {
    ENTITIES_2D;
    COLLISIONS_2D;
}

main :: () {

    defer report_memory_leaks();
    set_working_directory(path_strip_filename(get_path_of_running_executable()));
    
    init_window(GAME_NAME);
    defer deinit_window();
    
    init_draw2d();
    defer deinit_draw2d();
    
    init_collisions2d();
    defer deinit_collisions2d();

    init_entities2d();
    defer deinit_entities2d();

    #if IMGUI {
        draw_imgui_proc : IMGUI_DRAW_PROC;
        init_imgui();
        defer deinit_imgui();
    }
    
    #if EDITOR {
        draw_imgui_proc = draw_editor;
    }
    
    while !context.window.done {
        time_step();
        process_window_events();
        clear_screen();
        query_collisions2d();
        draw_entities2d();
        #if EDITOR draw_imgui(draw_imgui_proc);
        swap_buffers();
        clean_destroyed_entities();
        reset_temporary_storage();
    }
}