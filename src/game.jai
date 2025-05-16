#load "dependencies.jai";

GAME_NAME :: "Game";

main :: () {

    defer report_memory_leaks();
    set_working_directory(path_strip_filename(get_path_of_running_executable()));
    
    process_window_events : Window.PROCESS_EVENTS_PROC;

    #if IMGUI 
    then process_window_events = ImGui.ProcessInputEvents;

    Window.init(GAME_NAME, process_events_proc = process_window_events);
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
    
    while Window.keep_opened() {   

        Graphics.clear_screen();
        time_step();
        
        #if EDITOR {
            update_frame_by_frame_mode();
            //if frame_by_frame_mode.next_frame
            //then update logic 
        } else {
            // update logic
        }
        
        // Draw.
        draw_entities2d();
        #if IMGUI ImGui.Draw(get_time());

        clean_destroyed_entities();
        reset_temporary_storage();
    }
}

#scope_file

Graphics :: #import "Graphics" (DUMP_ERRORS = DEBUG);

#if EDITOR {

FrameByFrameMode :: struct {
    frame_by_frame         : bool;
    frame_by_frame_pressed : bool;
    next_frame             : bool;
    next_frame_pressed     : bool;
}

frame_by_frame_mode : FrameByFrameMode;

update_frame_by_frame_mode :: () {

    using frame_by_frame_mode;

    if Input.is_key_down(.CTRL) && Input.is_key_down(#char "P" ) {

    if !frame_by_frame_pressed {
            frame_by_frame_pressed = true;
            frame_by_frame =! frame_by_frame;
        }

    } else {
        frame_by_frame_pressed = false;
    }

    if !frame_by_frame {
        next_frame = true;
        return;
    }

    next_frame = false;
    
    if Input.is_key_down(.CTRL) && Input.is_key_down(.ARROW_RIGHT) {
        if !next_frame_pressed {
            next_frame_pressed = true;
            next_frame = true;
        }
    } else {
        next_frame_pressed = false;
    }
}

} // #if EDITOR