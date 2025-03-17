Game :: struct {
    window  : Window;
    draw_2d : Draw2D_Context;
    alien   : Texture;
}

#add_context game: Game;

main :: () {

    path := path_strip_filename(get_path_of_running_executable());
    set_working_directory(path);
    
    window := *context.game.window;
    alien  := *context.game.alien;

    init_window(window);
    defer fini_window(window);

    set_clear_color(1, 0.5, 0, 1);
    draw_2d_init(*context.game.draw_2d);

    init_texture_from_path(alien, "assets/alien.png", mag = .LINEAR, min = .LINEAR);    
    defer fini_texture(alien);

    while keep_window_opened(window) {
        clear_screen();
        draw_2d_begin(.{ xx window.width, xx window.height });
        draw_quad(texture = alien);
        draw_circle(transform = transfom(RIGHT_3D), tint = .{0, 0, 1, 1});
        draw_2d_end();
        reset_temporary_storage();
    }
}

#scope_file

#import "System";
#import "String";
#import "Basic";
#import "Core";
#import "Graphics";