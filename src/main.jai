main :: () {

    //---------------------------
    //:INITIALIZATION
    //---------------------------

    defer report_memory_leaks();
    set_working_directory(path_strip_filename(get_path_of_running_executable()));
    
    process_window_events : Window.PROCESS_EVENTS_PROC;

    #if IMGUI 
    then process_window_events = ImGui.ProcessInputEvents;

    Window.init("Game", process_events_proc = process_window_events, vsync = true);
    defer Window.deinit();
    
    Graphics.init_draw2d();
    defer Graphics.deinit_draw2d();
    
    draw_imgui : ImGui.DRAW_PROC;

    #if IMGUI && EDITOR 
    then draw_imgui = draw_editor;

    #if IMGUI
    then ImGui.Init(imgui_draw_proc = draw_imgui);
    defer ImGui.Deinit();

    init_entity_storage();
    defer deinit_entity_storage();

    Graphics.init(*sheet);
    defer Graphics.deinit(*sheet);

    Graphics.set_clear_color(DARK_GREY);

    create_player();

    //---------------------------
    //:MAIN LOOP
    //---------------------------

    while Window.keep_opened() {   

        Graphics.clear_screen();
        Time.time_step();

        if can_update_this_frame() {
            move_entities();
        }
        
        draw_entities();

        #if IMGUI ImGui.Draw(Time.get_time());

        clean_destroyed_entities();
        reset_temporary_storage();
    }

}

//---------------------------
//:GAME (split in files later if needed)
//---------------------------

sheet   : Graphics.Spritesheet;
moveplc : Entity;

create_player :: () {
    moveplc = dlz_entity(read_entire_file("assets/moveplaceholder.prefab",,temp));
    get_component(Movement2D_Component, moveplc).start = true;
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
    Graphics.draw2d_begin(.{context.window.width, context.window.height});
    {
        view := get_entity_view(Transform2D_Component, Sprite_Component);
        for view draw_sprite_entity(it, *sheet);
    }
    Graphics.draw2d_end();
}

//---------------------------
//:DEPENDENCIES
//---------------------------

#import "Basic"()(MEMORY_DEBUGGER=true);
#import "System";
#import "Hash_Table";
#import "File";

#import "Entity" (EDIT_MODE = EDITOR, MAX_ENTITIES = MAX_ENTITIES);

Graphics :: #import "Graphics" (DUMP_ERRORS = DEBUG);
Time     :: #import "Time";
Window   :: #import "Window_Creation" (DUMP_GL_ERRORS = DEBUG, CLOSE_WITH_SCAPE = EDITOR);
Input    :: #import "Input";

#if IMGUI then {
    ImGui :: #import "ImGui";
}

// Editor
#if EDITOR then {
    #load "editor/editor.jai";
}

#load "utils.jai";

#load "components/game/keyboard_movement.jai";
#load "components/game/2d_movement.jai";
#load "components/core/2d_transform.jai";
#load "components/core/blink.jai";
#load "components/core/sprite.jai";
#load "components/core/text.jai";