#load "src/engine.jai";
#load "src/game.jai";

main :: () {
    engine_run(app_name = "Game");
    defer engine_shutdown();

    init_entity_storage();
    defer deinit_entity_storage();

    init_font(*font);
    defer deinit_font(*font);
    
    #if !EDITOR
    then init_game();
    defer if is_game_init() then deinit_game();

    while engine_keep_running() {   
        if can_update_this_frame()
        then update_game();
        draw_game_frame();
        clean_destroyed_entities();
        reset_temporary_storage();
    }
}