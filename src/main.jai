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

    #if IMGUI {
        #if EDITOR then draw_imgui = draw_editor;
        ImGui.Init(imgui_draw_proc = draw_imgui);
        defer ImGui.Deinit();
    }

    init_entity_storage();
    defer deinit_entity_storage();

    init(*sheet);
    defer deinit(*sheet);

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

        clear_screen();
        time_step();
        
        if can_update_this_frame() {
            update_game();
            move_entities();
            query_2d_collisions();
        }
        
        draw_entities();

        #if IMGUI ImGui.Draw(Time.get_time());

        clean_destroyed_entities();
        reset_temporary_storage();
    }

}

move_entities :: () {
    view := get_entity_view(Transform2D_Component, Movement2D_Component);
    for view {
        if has_component(KeyboardMovement_Component, it) 
        then update_entity_input(it);
        move_entity(it);
    }
}

draw_entities :: () {
    draw2d_begin(.{context.window.width, context.window.height});
    {
        // FlipBook.
        {
            view := get_entity_view(FlipBook_Component);
            for view update_flipbook_entity(it);
        }
        // Sprites.
        {
            view := get_entity_view(Transform2D_Component, Sprite_Component);
            for view draw_sprite_entity(it, *sheet);
        }
        // Collisions.
        {
            view := get_entity_view(Transform2D_Component, Circle_Collider_Component);
            collisions_table := context.collisions2d.collisions_table;
            for view {
                coll := get_component(Circle_Collider_Component, it);
                ref := make_ref(it);
                if table_contains(*collisions_table, ref) {
                    collides_with := table_find_pointer(*collisions_table, ref);
                    if collides_with.count == 0 
                    then draw_circle(pos = get_pos(it), rad = coll.radius, tint = LIGHT_GREEN);
                    else draw_circle(pos = get_pos(it), rad = coll.radius, tint = LIGHT_RED);
                } else {
                    draw_circle(pos = get_pos(it), rad = coll.radius, tint = LIGHT_GREEN);
                }
            }
        }
    }
    draw2d_end();
}

//---------------------------
//:DEPENDENCIES
//---------------------------

#import "Basic"()(MEMORY_DEBUGGER=true);
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
#load "game.jai";