#load "dependencies.jai";

GAME_NAME :: "Game";

main :: () {
    
    using context.window;
    
    defer report_memory_leaks();
    set_working_directory(path_strip_filename(get_path_of_running_executable()));
    
    init_window(GAME_NAME);
    defer deinit_window();
    
    init_draw2d();
    defer deinit_draw2d();
    
    #if IMGUI {
        #if EDITOR 
        then ImGui.Init(imgui_draw_proc = draw_editor); 
        else ImGui.Init();
        defer ImGui.Deinit();
    }

    init_entity_storage();
    defer deinit_entity_storage();

    init_entities2d();
    defer deinit_entities2d();
    
    while !done {   

        clear_screen();
        time_step();
        process_window_events();
        
        #if EDITOR update_frame_by_frame_mode();
        
        if can_update() {
        }
        
        // Draw.
        draw_entities2d(width, height);
        #if IMGUI ImGui.Draw(get_time());
        swap_buffers();

        clean_destroyed_entities();
        reset_temporary_storage();
    }
}

#scope_file

can_update :: inline () -> bool {
    #if EDITOR 
    then return frame_by_frame_mode.next_frame;
    else return true;
}

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

    if is_key_down(.CTRL) && is_key_down(#char "P" ) {

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
    
    if is_key_down(.CTRL) && is_key_down(.ARROW_RIGHT) {
        if !next_frame_pressed {
            next_frame_pressed = true;
            next_frame = true;
        }
    } else {
        next_frame_pressed = false;
    }
}

} // #if EDITOR