#load "dependencies.jai";

GAME_NAME :: "Game";

main :: () {
    defer report_memory_leaks();
    set_working_directory(path_strip_filename(get_path_of_running_executable()));
    
    init_window(GAME_NAME);
    defer deinit_window();
    
    init_draw_2d();
    defer deinit_draw_2d();
    
    #if IMGUI {
        draw_imgui_proc : IMGUI_DRAW_PROC;
        init_imgui();
        defer deinit_imgui();
    }
    
    #if EDITOR {
        draw_imgui_proc = draw_editor;
        init_editor();
        defer deinit_editor();
    }

    while !context.window.done {
        process_window_events();
        clear_screen();
        //#TODO_asuarez draw the game
        #if EDITOR draw_imgui(draw_imgui_proc);
        swap_buffers();
        reset_temporary_storage();
    }
}