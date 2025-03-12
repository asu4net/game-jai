my_window: Window_Type;
window_width  : s32 = 1920;
window_height : s32 = 1080;

main :: () {

    WANTED_MSAA :: 8;
    // On Linux, we need to pass the MSAA value to create_window
    my_window = create_window(window_width, window_height, "A Window", wanted_msaa = WANTED_MSAA);

    // On other operating systems, the MSAA value needs to be passed to *_create_context, so we
    // need to have an extra step here if you want MSAA.
    msaa := Simp.prepare_window(my_window, wanted_msaa = WANTED_MSAA);
    log("Wanted MSAA: %\nChosen MSAA: %", WANTED_MSAA, msaa);

    // Actual render size in pixels can be different from the window dimensions we specified above (for example on high-resolution displays on macOS/iOS).
    window_width, window_height = Simp.get_render_dimensions(my_window);

    Simp.set_render_target(my_window, .LEFT_HANDED);
    Simp.set_projection_type(.ORTHO_SCREEN);

    my_init_fonts();

    quit := false;


    while !quit {
        Input.update_window_events();

        for Input.get_window_resizes() {
            Simp.update_window(it.window);  // Simp will do nothing if it doesn't care about this window.

            if it.window == my_window {
                should_reinit := (it.width != window_width) || (it.height != window_height);

                window_width  = it.width;
                window_height = it.height;

                if should_reinit my_init_fonts();  // Resize the font for the new window size.
            }
        }

        for Input.events_this_frame {
            if it.type == .QUIT then quit = true;

            if it.type == {
              case .KEYBOARD;
                if it.key_pressed && it.key_code == .ESCAPE {
                    quit = true;
                }
            }
        }

        draw_one_frame();
        sleep_milliseconds(10);
        reset_temporary_storage();
    }
}

draw_one_frame :: () {
    Simp.clear_render_target(.15, .08, .08, 1);
    Simp.set_shader_for_color();
    time := seconds_since_init();

    // This is our own code to set up a rotating square:
    {
        b := cast(float) window_height / 10;
        p: Vector2;
        p.x = cast(float) (window_width  / 2);
        p.y = cast(float) (window_height / 2);
        
        p -= .{0, 200};

        w := Vector2.{b, 0};  // Solo afecta la X
        h := Vector2.{0, b};  // Solo afecta la Y

        p0 := p - w - h;  // Esquina superior izquierda
        p1 := p + w - h;  // Esquina superior derecha
        p2 := p + w + h;  // Esquina inferior derecha
        p3 := p - w + h;  // Esquina inferior izquierda

        Simp.immediate_quad(p0, p1, p2, p3, Vector4.{1, 0, 0, 1});
    }

    // Draw some text.
    {
        text := "Simp!";

        text_width := Simp.prepare_text(my_font, text);

        text_x := (window_width - text_width) / 2;
        text_y := window_height/2 + my_font.character_height/4;

        Simp.draw_prepared_text(my_font, text_x, text_y);
    }

    Simp.swap_buffers(my_window);
}

my_init_fonts :: () {

    if !working_directory_set {
        path := path_strip_filename(get_path_of_running_executable());
        set_working_directory(path);
        working_directory_set = true;
    }

    pixel_height := window_height / 24;
    my_font = Simp.get_font_at_size(".", "OpenSans-BoldItalic.ttf", pixel_height);
    assert(my_font != null);
}

#scope_file

working_directory_set := false;
my_font: *Simp.Dynamic_Font;

Simp  :: #import "Simp";
Input :: #import "Input";

#import "Window_Creation";
#import "Basic";
#import "Math";
#import "System";  // For get_path_of_running_executable. @Cleanup.
#import "String";  // For path_strip_filename. @Cleanup.