Input :: #import "Input";

PROCESS_EVENTS_PROC :: #type (event : Input.Event);

WindowState :: struct {
    done           : bool;
    handle         : *Window_Type;
    width          : s32;
    height         : s32;
    process_events : PROCESS_EVENTS_PROC;    
}

#add_context window: WindowState;

init :: (name: string = "the window", w: s32 = 1280, h: s32 = 720, process_events_proc : PROCESS_EVENTS_PROC = null) {
    using context.window;
    
    assert(handle == null);
    
    width  = w;
    height = h;
    process_events = process_events_proc;

    handle = create_window(w, h, name); 
    
    if !handle {
        log_error("Failed to create the window.");
        return;
    }

    gl_create_context(handle, 4, 4, compatibility = false, debug = DUMP_GL_ERRORS);
    gl_load(*gl);
    log("GL Vendor = %\n", to_string(glGetString(GL_VENDOR)));
    log("GL Version = %\n", to_string(glGetString(GL_VERSION)));
    
    #if DUMP_GL_ERRORS {
        gl_enable_debug_output( break_on_error = true );
        DumpGLErrors("context");
    }
}

deinit :: () {
    using context.window;
    assert(handle != null);
}

keep_opened :: () -> bool {

    using context.window;
    Input.update_window_events();
    
    resizes := Input.get_window_resizes();
    
    if resizes.count {
        last := resizes[resizes.count - 1];
        width  = last.width;
        height = last.height;
    }

    for Input.events_this_frame {
        
        if it.type == .QUIT 
        then done = true;

        #if CLOSE_WITH_SCAPE {
            if it.type == .KEYBOARD && it.key_code == .ESCAPE
            then done = true;
        }

        if process_events 
        then process_events(it);
    }
    
    swap_buffers();
    return !done;
}

#scope_module

#import "GL" (DUMP_GL_ERRORS = DUMP_GL_ERRORS);

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