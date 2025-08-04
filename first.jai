font : Font;

main :: () {
    //---------------------------
    //:INITIALIZATION
    //---------------------------

    engine_run("Game");
    defer engine_shutdown();

    init_entity_storage();
    defer deinit_entity_storage();

    init_font(*font);
    defer deinit_font(*font);
    
    #if !EDITOR
    then init_game();
    defer if is_game_init() then deinit_game();

    //---------------------------
    //:MAIN LOOP
    //---------------------------

    while engine_keep_running() {   

        if can_update_this_frame()
        then update_game();
        
        clear_screen();
        draw_game_frame();

        clean_destroyed_entities();
        reset_temporary_storage();
    }
}

//---------------------------
//:DEPENDENCIES
//---------------------------

#load "src/engine.jai";
#load "src/game.jai";

#import "Random";
#import "Text_File_Handler";
#import "Enumerated_Array";
#import "Sparse_Set";
#import "Queue";