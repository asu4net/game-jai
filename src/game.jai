GAME_NAME :: "Game";

main :: () {

    defer report_memory_leaks();
    set_working_directory(path_strip_filename(get_path_of_running_executable()));
    
    process_window_events : Window.PROCESS_EVENTS_PROC;

    #if IMGUI 
    then process_window_events = ImGui.ProcessInputEvents;

    Window.init(GAME_NAME, process_events_proc = process_window_events, vsync = true);
    defer Window.deinit();
    
    Graphics.init_draw2d();
    defer Graphics.deinit_draw2d();
    
    draw_imgui : ImGui.DRAW_PROC;

    #if IMGUI && EDITOR 
    then draw_imgui = draw_editor;

    #if IMGUI
    then ImGui.Init(imgui_draw_proc = draw_editor);
    defer ImGui.Deinit();

    init_entity_storage();
    defer deinit_entity_storage();

    init_entities2d();
    defer deinit_entities2d();

    Graphics.set_clear_color(DARK_GREY);

    start_game();

    while Window.keep_opened() {   

        Graphics.clear_screen();
        Time.time_step();
        if can_update_this_frame()
        then update_game(Time.delta_seconds());
        
        // Draw.
        draw_entities2d();
        #if IMGUI ImGui.Draw(Time.get_time());

        clean_destroyed_entities();
        reset_temporary_storage();
    }
}

// --------------------------------

// Game flow. This will be moved eventually to another file

player : Entity;
moveplc : Entity;

start_game :: () {
    player = dlz_entity(read_entire_file("assets/player.prefab" ,,temp));
    moveplc = dlz_entity(read_entire_file("assets/moveplaceholder.prefab",,temp));
    
}

update_game :: (delta_seconds : f32) {
    get_component(Transform2D_Component, player).pos += RIGHT_2D * 0.5 * delta_seconds;

    get_component(Movement2D_Component, moveplc).start = true;
    get_component(Movement2D_Component, moveplc).target = get_component(Transform2D_Component, player).pos;

    movement := get_entity_view(Transform2D_Component, Movement2D_Component);
    for entity : movement {
        if has_component(KeyboardMovement_Component, entity) then input_update(entity);
        update_movement(entity);
    } 
}

// --------------------------------

#scope_file

#import "Basic"()(MEMORY_DEBUGGER=true);
#import "System";

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

// Entity
#load "game_systems.jai";
#load "game_components.jai";
#import "Entity" (EDIT_MODE = EDITOR, MAX_ENTITIES = MAX_ENTITIES);

#load "utils.jai";