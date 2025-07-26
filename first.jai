sheet : Spritesheet;
font : Font;

main :: () {
    //---------------------------
    //:INITIALIZATION
    //---------------------------

    Tuki.run("Game");
    defer Tuki.shutdown();

    init_entity_storage();
    defer deinit_entity_storage();

    init_spritesheet(*sheet);
    defer deinit_spritesheet(*sheet);

    init_font(*font);
    defer deinit_font(*font);
    
    #if !EDITOR
    then init_game();
    defer if is_game_init() then deinit_game();

    //---------------------------
    //:MAIN LOOP
    //---------------------------

    while Tuki.keep_running() {   

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


#import "Sparse_Set";
#import "Queue";

Tuki :: #import "Tuki" (DEBUG = DEBUG, IMGUI = IMGUI);
        #import "Tuki" (DEBUG = DEBUG, IMGUI = IMGUI);

#load "src/editor/editor.jai";

#load "src/components/core/all.jai";
#load "src/components/game/all.jai";
#load "src/entity/entity_storage.jai";
#load "src/entity/entity_pool.jai";

#load "src/draw.jai";
#load "src/game.jai";