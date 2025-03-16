Game :: struct {
    window  : Window;
    draw_2d : Draw2D_Context;
}

#add_context game: Game;

main :: () {

    path := path_strip_filename(get_path_of_running_executable());
    set_working_directory(path);
    
    window := *context.game.window;

    init_window(window);
    defer fini_window(window);

    set_clear_color(0.5, 0.5, 0, 1);
    draw_2d_init(*context.game.draw_2d);

    while keep_window_opened(window) {
        clear_screen();
        draw_2d_begin(.{ xx window.width, xx window.height });
        draw_quad();
        draw_circle(tint = .{0, 0, 1, 1});
        draw_2d_end();
        reset_temporary_storage();
    }
}

#scope_file

#import "Basic";
#import "System";
#import "String";
#import "Graphics";

#import, file "core/window.jai";