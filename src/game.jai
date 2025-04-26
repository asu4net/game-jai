#load "dependencies.jai";

GAME_NAME :: "Game";

sheet : Spritesheet;

main :: () {
    
    using context.window;
    defer report_memory_leaks();
    set_working_directory(path_strip_filename(get_path_of_running_executable()));
    
    init_window(GAME_NAME);
    defer deinit_window();

    init_draw2d();
    defer deinit_draw2d();
    
    #if IMGUI {
        draw_imgui_proc : IMGUI_DRAW_PROC;
        init_imgui();
        defer deinit_imgui();
    }
    
    #if EDITOR {
        draw_imgui_proc = draw_editor;
    }

    init_entity_storage();
    defer deinit_entity_storage();
    
    init(*sheet);
    deinit(*sheet);

    while !done {
        time_step();
        process_window_events();
        clear_screen();
        #if EDITOR draw_imgui(draw_imgui_proc);
        draw2d_begin(.{width, height});
        view := get_entity_view(Transform2D_Component, Sprite_Component);
        for entity : view {
            draw_sprite(get_component(Transform2D_Component, entity), get_component(Sprite_Component, entity), *sheet);
        }
        draw2d_end();
        swap_buffers();
        clean_destroyed_entities();
        reset_temporary_storage();
    }
}