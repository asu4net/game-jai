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

Input :: #import "Input";

} // #if EDITOR