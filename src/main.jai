sheet : Spritesheet;

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

    set_clear_color(DARK_GREY);

    init_collisions2d();
    defer deinit_collisions2d();

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

#import "SDL3";
#if IMGUI ImGui :: #import "ImGui";

#import "Entity"   (EDIT_MODE = EDITOR, MAX_ENTITIES = MAX_ENTITIES);
#import "Graphics" (DUMP_ERRORS = DEBUG);
#import "Time";

#import "Input";

// Game files
#if EDITOR #load "editor/editor.jai";
#load "components/core/2d_movement.jai";
#load "components/core/2d_transform.jai";
#load "components/core/2d_collider.jai";
#load "components/core/blink.jai";
#load "components/core/sprite.jai";
#load "components/core/text.jai";
#load "components/core/flipbook.jai";

#load "window.jai";
#load "utils.jai";
#load "draw.jai";
#load "game.jai";