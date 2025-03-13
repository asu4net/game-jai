
Game :: struct {
    window : Window;
}

init_game :: (game : *Game) {
    path := path_strip_filename(get_path_of_running_executable());
    set_working_directory(path);
    init_window(*game.window);
    defer finish_window(*game.window);
    
    glClearColor(1, 0, 0, 1);

    while keep_window_opened(*window) {
        glViewport(0, 0, xx window.width, xx window.height);
        glClear(GL_COLOR_BUFFER_BIT);
    }
}

#scope_file

#load "window.jai"