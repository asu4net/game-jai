#load "dependencies.jai";

GAME_NAME :: "Game";

Scenes :: enum {
    AI_ENTITIES_2D;
    COLLISIONS_2D;
}

Game :: struct {
    ai_entities : Scene(AIEntity2D);

    //enemies -> Logic_Sprite
    //projectiles -> Logic_Sprite
    //player -> Logic_Sprite

    // Lo único que tienen en común el player, los enemigos, los proyectiles LAS COLISIONES

    //props -> Sprite / Logic_Sprite
    //gui -> Sprite / Text / Circle
}

// Vamos a tener 1 loop de colisiones

#add_context game : Game;

main :: () {
    using context.game;

    defer report_memory_leaks();
    set_working_directory(path_strip_filename(get_path_of_running_executable()));
    
    init_window(GAME_NAME);
    defer deinit_window();
    
    init_draw2d();
    defer deinit_draw2d();
    
    //init(*entities2d, init_proc = init_2d_entity, slot = xx Scenes.ENTITIES_2D);
    //defer deinit(*entities2d);

    init_collisions2d();
    defer deinit_collisions2d();

    init_sprites();
    defer deinit_sprites();

    #if IMGUI {
        draw_imgui_proc : IMGUI_DRAW_PROC;
        init_imgui();
        defer deinit_imgui();
    }
    
    #if EDITOR {
        draw_imgui_proc = draw_editor;
    }

    while !context.window.done {
        process_window_events();
        clear_screen();
        query_collisions2d();
        draw_sprites();
        #if EDITOR draw_imgui(draw_imgui_proc);
        swap_buffers();
        clean_destroyed_entities();
        reset_temporary_storage();
    }
}