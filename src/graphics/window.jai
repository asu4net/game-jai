Window :: struct {
    done       : bool;
    handle     : *Window_Type;
    width      : s32;
    height     : s32;
}

#add_context window: Window;

init_window :: (name :string = "the window", w: s32 = 1280, h: s32 = 720) {
    using context.window;
    
    assert(handle == null);
    
    width  = w;
    height = h;

    handle = create_window(w, h, name); 
    
    if !handle {
        log_error("Failed to create the window.");
        return;
    }

    gl_create_context(handle, 4, 4, compatibility = false, debug = DEBUG);
    gl_load(*gl);
    log("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
    log("GL Version = %\n", to_string(glGetString(GL_VERSION)));
    
    #if DEBUG {
        gl_enable_debug_output( break_on_error = true );
        DumpGLErrors("context");
    }

    set_clear_color(DARK_GRAY);
}

swap_buffers :: () {
    using context.window;

    #if OS == .WINDOWS {
        #import "Windows";
        dc := GetDC(handle);
        SwapBuffers(dc);
    } else #if OS == .LINUX {
        info := find_window_info(handle);
        if (!info) || !info.specific.glx_window {
            log_error("Simp: Attempt to swap_buffers on a previously unseen window!\n");
            return;
        }

        glXSwapBuffers(x_global_display, info.specific.glx_window);
    } else #if OS == .MACOS {
        // On macOS, OpenGL buffer swapping is done on the context, not on the view.
        // So we can only swap for the active window. (And you need to swap before switching to another view).
        NSOpenGLContext.flushBuffer(the_gl_context);
    } else #if OS == .ANDROID {
        // I think it's gonna make more sense for display and surface to be on the specific window info, then
        // we will have to get the window here like Linux does.
        eglSwapBuffers(the_egl_display, the_egl_surface);
    } else {
        assert(false);
    }
} 

deinit_window :: () {
    using context.window;
    assert(handle != null);
}

process_window_events :: () {

    using context.window;
    Input.update_window_events();
    
    resizes := Input.get_window_resizes();
    if resizes.count {
        last := resizes[resizes.count - 1];
        width  = last.width;
        height = last.height;
    }

    for Input.events_this_frame {
        
        if it.type == .QUIT then done = true;

        if it.type == .KEYBOARD {
            
            if it.key_code == .ESCAPE {
                done = true;
            }
        }

        #if IMGUI ImGui.ProcessInputEvents(it);
    }
}

get_time :: () -> float64 {
    one_time_init(*is_get_seconds_initialized, init_get_seconds());
    delta := current_time_monotonic() - get_seconds_base_time;
    return to_float64_seconds(delta);
}

// Some input stuff, this should be in his own module.

Mouse_Button :: enum {
    LEFT;
    RIGHT;
    MIDDLE;
}

get_key_state :: (input : Input.Key_Code) -> Input.Key_Current_State {
    return Input.input_button_states[input];
}

is_key_down :: (input : Input.Key_Code) -> bool {
    return get_key_state(input) == .DOWN;
}

#scope_file

is_get_seconds_initialized: s32;
get_seconds_base_time: Apollo_Time;

init_get_seconds :: () {
    get_seconds_base_time = current_time_monotonic();
}