Game :: struct {
    window : Window;
}

#add_context game: Game;

main :: () {

    path := path_strip_filename(get_path_of_running_executable());
    set_working_directory(path);
    
    window := *context.game.window;

    init_window(window);
    defer fini_window(window);

    glClearColor(1, 0, 0, 1);

    while keep_window_opened(window) {

        glViewport(0, 0, xx window.width, xx window.height);
        glClear(GL_COLOR_BUFFER_BIT);
    }
}

#scope_file

#import "GL" (DUMP_GL_ERRORS = true);
#import "System";
#load "window.jai";
#load "graphics/texture.jai";
#load "graphics/shader.jai";