
//
// This x_global_display stuff is not the right way to do it. We should
// probably wrap the window type such that it contains a display pointer
// and a window pointer, thus is enough to uniquely identify a window.
//
#import "X11";

window_minimized := false;

Saved_Window_Info :: struct {

}

toggle_fullscreen :: (win: Window, desire_fullscreen: bool, saved: *Saved_Window_Info) -> success: bool, width: s32, height: s32 {
    if desire_fullscreen {
        if x_global_net_wm_state && x_global_net_wm_state_fullscreen {
            //
            xev: XEvent;
            xev.type = ClientMessage;
            xev.xclient.window = win;
            xev.xclient.message_type = x_global_net_wm_state;
            xev.xclient.format = 32;
            xev.xclient.data.l[0] = _NET_WM_STATE_ADD;
            xev.xclient.data.l[1] = cast(s64) x_global_net_wm_state_fullscreen;

            display := x_global_display;
            XSendEvent(display, DefaultRootWindow(display), False, SubstructureRedirectMask | SubstructureNotifyMask, *xev);
            XSync(display, False);

            width: u32;
            height: u32;

            // for what ever stupid reason, XGetGeometry crashes if you pass null in for any of its return parameters
            root: Window;
            x, y: s32;
            border_width: u32;
            depth_return: u32;
            // this will return the window's current dimensions, but it seems the server will imediately send a ConfigureNotify event
            // with the new size of the fullscreen window
            XGetGeometry(display, win, *root, *x, *y, *width, *height, *border_width, *depth_return);
            return true, cast(s32) width, cast(s32) height;
        } else {
            // :NoNET_WM_STATE_FULLSCREEN:
            // @TODO typically the window manager should support NET_WM_STATE and NET_WM_STATE_FULLSCREEN
            // however, in the event that it does not, we're supposed to change the window's attributes
            // to enable override_redirect. However, apparently in doing so, this causes the window manager
            // to ignore the window (the window, in essense, is considered as acting as a temporary window manager
            // accoring to the ICCM) requiring more work on our part. The ICCM strongly discourages doing this,
            // but this is the only other way to take control of the screen AFAICT. -josh
            return false, 0, 0;
        }
    } else {
        if x_global_net_wm_state && x_global_net_wm_state_fullscreen {
            xev: XEvent;
            xev.type = ClientMessage;
            xev.xclient.window = win;
            xev.xclient.message_type = x_global_net_wm_state;
            xev.xclient.format = 32;
            xev.xclient.data.l[0] = _NET_WM_STATE_REMOVE;
            xev.xclient.data.l[1] = cast(s64) x_global_net_wm_state_fullscreen;

            display := x_global_display;
            XSendEvent(display, DefaultRootWindow(display), False, SubstructureRedirectMask | SubstructureNotifyMask, *xev);

            width: u32;
            height: u32;

            // for what ever stupid reason, XGetGeometry crashes if you pass null in for any of its return parameters
            root: Window;
            x, y: s32;
            border_width: u32;
            depth_return: u32;
            XGetGeometry(display, win, *root, *x, *y, *width, *height, *border_width, *depth_return);
            return true, cast(s32) width, cast(s32) height;
        } else {
            // :NoNET_WM_STATE_FULLSCREEN:
            return false, 0, 0;
        }
    }
}

create_window :: (width: int, height: int, window_name: string, window_x := 0, window_y := 0, parent: Window_Type = None, background_color_rgb := DEFAULT_WINDOW_CREATION_COLOR, wanted_msaa: s32 = DEFAULT_MSAA) -> Window {
    if !x_global_display
        init_global_display();

    d := x_global_display;

    XLockDisplay(d);
    root := DefaultRootWindow(d);
    if parent == None then parent = root;

    screen := DefaultScreen(d);

    // These attributes must match the attibutes we use to create the GL context. :GlContextAttributes
    //        -rluba, 2021-11-30
    attr := s32.[
        GLX_RGBA,
        GLX_DEPTH_SIZE, 24,
        GLX_DOUBLEBUFFER,
        GLX_RED_SIZE, 8,
        GLX_GREEN_SIZE, 8,
        GLX_BLUE_SIZE, 8,
        GLX_STENCIL_SIZE, 8,
        GLX_SAMPLE_BUFFERS, cast(s32) ifx wanted_msaa then 1 else 0,
        GLX_SAMPLES,        wanted_msaa,
        None
    ];

    vi := glXChooseVisual(d, screen, attr.data);
    // log("XVisualInfo: %", <<vi);
    cmap := XCreateColormap(d, parent, vi.visual, AllocNone);

    to_u16 :: (f: float) -> u16 #expand {
        u := clamp(cast(s32)(f * 65535), 0, 65535);
        return cast(u16) u;
    }

    background_color: XColor;
    background_color.flags |= DoRed | DoGreen | DoBlue;
    background_color.red     = to_u16(background_color_rgb[0]);
    background_color.green   = to_u16(background_color_rgb[1]);
    background_color.blue    = to_u16(background_color_rgb[2]);
    XAllocColor(d, cmap, *background_color);


    swa: XSetWindowAttributes;
    swa.colormap = cmap;
    swa.event_mask = ExposureMask | KeyPressMask | KeyReleaseMask | ButtonPressMask | ButtonReleaseMask | StructureNotifyMask | FocusChangeMask | EnterWindowMask | LeaveWindowMask | PointerMotionHintMask | PointerMotionMask;
    swa.background_pixel = background_color.pixel;
    win := XCreateWindow(d, parent, xx window_x, xx window_y, xx width, xx height, 0, vi.depth, InputOutput, vi.visual, cast(u64) (CWColormap | CWEventMask), *swa);

//    XSetWindowBackground(d, win, background_color.pixel);

    win_name := temp_c_string(window_name);
    if window_name then XStoreName(d, win, win_name);

    class_hints := XAllocClassHint();
    if class_hints {
        // this changes the application name for now (not the window title)
        // unset, gnome3 will just display "Unknown" in the activity bar and the dock
        if window_name {
            class_hints.res_name = win_name;
            class_hints.res_class = win_name;
        } else {
            class_hints.res_name = "jai-application";
            class_hints.res_class = "JAI-Application";
        }
        XSetClassHint(d, win, class_hints);
    }

    XMapWindow(d, win);

    XSetWMProtocols(d, win, *x_global_wm_delete_window, 1);
    
    x_global_input_context = XCreateIC(
        x_global_input_method,
        XNClientWindow, win,
        XNFocusWindow, win,
        XNInputStyle, XIMPreeditNothing | XIMStatusNothing,
        null,
    );

    if !x_global_input_context {
        log_error("Could not create X11 input context\n");
    }


    array_add(*x_global_windows, win);

    XUnlockDisplay(d);
    return win;
}

get_dimensions :: (win: Window, right_handed: bool) -> (x: s32, y: s32, width: s32, height: s32, success := true) {
    xwa: XWindowAttributes;
    XGetWindowAttributes(x_global_display, win, *xwa);

    y := ifx right_handed then xwa.y+xwa.height else xwa.y;
    return xwa.x, y, xwa.width, xwa.height;
}

get_mouse_pointer_position :: (dpy: *Display, win: Window, right_handed: bool) -> x: int, y: int, success: bool {
    root_x, root_y: s32;
    win_x, win_y: s32;
    root, child: Window;
    modifier_mask: u32;

    // @TODO XQueryPointer is a round trip to the X server, which means this could be very slow.
    // It may be more desirable to update a global mouse state by capturing mouse events in X11_Input.jai:update_x11_window_events()
    ok := XQueryPointer(dpy, win, *root, *child, *root_x, *root_y, *win_x, *win_y, *modifier_mask);

    if right_handed {
        xwa: XWindowAttributes;
        XGetWindowAttributes(dpy, win, *xwa);
        win_y = xwa.height - win_y;
    }
    return win_x, win_y, ok == True;
}

get_mouse_pointer_position :: (win: Window, right_handed: bool) -> x: int, y: int, success: bool {
    x, y, success := get_mouse_pointer_position(x_global_display, win, right_handed);
    return x, y, success;
}

get_mouse_pointer_position :: inline (right_handed := false) -> x: int, y: int, success: bool {
    dpy := x_global_display;
    if !dpy return 0, 0, false;
    win: Window;
    revert: s32;
    XGetInputFocus(dpy, *win, *revert);
    x, y, success := get_mouse_pointer_position(dpy, win, right_handed);
    return x, y, success;
}


//#scope_file

// libc :: #system_library "libc";
