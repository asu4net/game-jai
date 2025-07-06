can_update_this_frame :: inline () -> bool {
    #if EDITOR {
    update_frame_by_frame_mode();    
    return frame_by_frame_mode.next_frame;
    } else {
        return true;
    }
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

    if is_key_down(.RSHIFT) && is_key_down(.F10) {
    
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
    
    if is_key_down(.F10) {
        if !next_frame_pressed {
            next_frame_pressed = true;
            next_frame = true;
        }
    } else {
        next_frame_pressed = false;
    }
}

} // #if EDITOR

//#REVIEW_asuarez More commands stuff (maybe this should be in utils or main)
should_update_game :: () -> bool {

    #if EDITOR {
        if !is_key_down(.RSHIFT) && is_key_down(.F5) && !is_game_init() {
            init_game();
        } else if  is_key_down(.RSHIFT) && is_key_down(.F5) && is_game_init() {
            deinit_game();
        }
    }

    return is_game_init();
}