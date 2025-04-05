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
        init_imgui();
        defer deinit_imgui();
    }
    
    while !context.window.done {
        process_window_events();
        clear_screen();
        //#TODO_asuarez draw the game
        #if IMGUI draw_imgui(draw_editor);
        swap_buffers();
        reset_temporary_storage();
    }
}