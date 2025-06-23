#load "dependencies.jai";

GAME_NAME :: "Game";

main :: () {

    defer report_memory_leaks();
    set_working_directory(path_strip_filename(get_path_of_running_executable()));
    
    process_window_events : Window.PROCESS_EVENTS_PROC;

    #if IMGUI 
    then process_window_events = ImGui.ProcessInputEvents;

    Window.init(GAME_NAME, process_events_proc = process_window_events, vsync = true);
    defer Window.deinit();
    
    Graphics.init_draw2d();
    defer Graphics.deinit_draw2d();
    
    draw_imgui : ImGui.DRAW_PROC;

    #if IMGUI && EDITOR 
    then draw_imgui = draw_editor;

    #if IMGUI
    then ImGui.Init(imgui_draw_proc = draw_editor);
    defer ImGui.Deinit();

    init_entity_storage();
    defer deinit_entity_storage();

    init_entities2d();
    defer deinit_entities2d();

    Graphics.set_clear_color(DARK_GREY);

    start_game();

    while Window.keep_opened() {   

        Graphics.clear_screen();
        Time.time_step();
        if can_update_this_frame()
        then update_game(Time.delta_seconds());
        
        // Draw.
        draw_entities2d();
        #if IMGUI ImGui.Draw(Time.get_time());

        clean_destroyed_entities();
        reset_temporary_storage();
    }
}