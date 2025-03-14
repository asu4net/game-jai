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

    set_clear_color(1, 0, 0, 1);

    draw_2d_init(*context.game.draw_2d);

    while keep_window_opened(window) {
        glViewport(0, 0, xx window.width, xx window.height);
        draw_2d_begin();
        draw_quad();
        draw_2d_end();
        glClear(GL_COLOR_BUFFER_BIT);
    }
}

#scope_file

#import "GL" (DUMP_GL_ERRORS = true);
#import "System";
#load "window.jai";
#load "graphics/draw_2d.jai";