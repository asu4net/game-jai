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


        time_step();
        
        if can_update_this_frame() {
            update_game();
            move_entities();
            query_2d_collisions();
        }
        
        clear_screen();
        draw_entities();

        #if IMGUI {
            ImplOpenGL3_NewFrame();
            ImplSDL3_NewFrame();
            ImGui.NewFrame();
        }

        ImGui.Begin("Random Window");
        ImGui.Text("Hello from random window!");
        ImGui.End();

        ImGui.Render();
        ImplOpenGL3_RenderDrawData(ImGui.GetDrawData());
        
        // Update and Render additional Platform Windows
        // (Platform functions may change the current OpenGL context, so we save/restore it to make it easier to paste this code elsewhere.
        //  For this specific demo app we could also call SDL_GL_MakeCurrent(window, gl_context) directly)
        
        if (ImGui.GetIO().ConfigFlags_ & .ViewportsEnable) {
            backup_current_window := SDL_GL_GetCurrentWindow();
            backup_current_context := SDL_GL_GetCurrentContext();
            ImGui.UpdatePlatformWindows();
            ImGui.RenderPlatformWindowsDefault();
            SDL_GL_MakeCurrent(backup_current_window, backup_current_context);
        }

        SDL_GL_SwapWindow(context.window.handle);
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
#load "game.jai";