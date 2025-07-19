sheet : Spritesheet;
font : Font;

main :: () {
    //---------------------------
    //:INITIALIZATION
    //---------------------------

    defer report_memory_leaks();
    set_working_directory(path_strip_filename(get_path_of_running_executable()));
    
    init_window("Game");
    defer deinit_window();
    
    init_draw2d();
    defer deinit_draw2d();

    init_entity_storage();
    defer deinit_entity_storage();

    init_spritesheet(*sheet);
    defer deinit_spritesheet(*sheet);

    init_font(*font);
    defer deinit_font(*font);
    
    set_clear_color(DARK_GREY);

    #if !EDITOR
    then init_game();
    defer if is_game_init() then deinit_game();

    //---------------------------
    //:MAIN LOOP
    //---------------------------

    while keep_window_opened() {   

        if can_update_this_frame()
        then update_game();
        
        clear_screen();
        draw_frame();

        clean_destroyed_entities();
        reset_temporary_storage();
    }
}

//---------------------------
//:DEPENDENCIES
//---------------------------

#import "Basic"()(MEMORY_DEBUGGER = DEBUG);
#import "System";
#import "Hash_Table";
#import "File";
#import "File_Utilities";
#import "Math";
#import "String";
#import "Input";
#import "Random";
#import "Text_File_Handler";
#import "Enumerated_Array";

#import "Queue";
#import "Jaison";
#import "SDL3";
#if IMGUI ImGui :: #import "ImGui";

#import "Graphics" (DUMP_ERRORS = DEBUG);
#import "Time";
#import "Sparse_Set";
#import "Queue";

#load "editor/editor.jai";

#load "components/core/all.jai";
#load "components/game/all.jai";
#load "entity/entity_storage.jai";
#load "entity/entity_pool.jai";

#load "window.jai";
#load "draw.jai";
#load "game.jai";