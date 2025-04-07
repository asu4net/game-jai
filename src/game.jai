#load "dependencies.jai";

GAME_NAME :: "Game";

Scenes :: enum {
    ENTITIES_2D;
}

Game :: struct {
    entities2d : Scene(Entity2D);
} 

#add_context game : Game;

main :: () {
    using context.game;

    defer report_memory_leaks();
    set_working_directory(path_strip_filename(get_path_of_running_executable()));
    
    init_window(GAME_NAME);
    defer deinit_window();
    
    init_draw_2d();
    defer deinit_draw_2d();
    
    init(*entities2d, init_proc = init_2d_entity, slot = xx Scenes.ENTITIES_2D);
    defer deinit(*entities2d);

    #if IMGUI {
        draw_imgui_proc : IMGUI_DRAW_PROC;
        init_imgui();
        defer deinit_imgui();
    }
    
    #if EDITOR {
        draw_imgui_proc = draw_editor;
    }

    entities2d.make_prefab(xx *entities2d);

    while !context.window.done {
        process_window_events();
        clear_screen();
        draw_2d_entities(*entities2d);
        //#if EDITOR draw_imgui(draw_imgui_proc);
        swap_buffers();
        reset_temporary_storage();
    }
}