Game :: struct {
    window  : Window;
    draw_2d : Draw2D_Context;
    alien   : Texture;
    font    : Font;
}

#add_context game: Game;

main :: () {

    path := path_strip_filename(get_path_of_running_executable());
    set_working_directory(path);
    
    window  := *context.game.window;
    alien   := *context.game.alien;
    font    := *context.game.font;
    draw_2d := *context.game.draw_2d;

    init_window(window);
    defer fini_window(window);

    set_clear_color(DARK_GRAY);
    draw_2d_init(draw_2d);

    init_texture_from_path(alien, "assets/alien.png", mag = .LINEAR, min = .LINEAR);    
    defer fini_texture(alien);

    init_font(font, "assets/fonts/AlbertSans-VariableFont_wght.ttf");
    defer fini_font(font);

    while keep_window_opened(window) {
        clear_screen();
        update_2d_camera(window.width, window.height);
        draw_quad(texture = alien);
        draw_text(transform = make_transfom(DOWN_3D * 0.5), "Habemos texto", font, 0.125, tint = LIGHT_GREEN);
        draw_circle(transform = make_transfom(RIGHT_3D), tint = LIGHT_BLUE);
        draw_quad(transform = make_transfom(LEFT_3D, ZERO_3D, .{1, -1, 1}), texture = *font.atlas);
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
#import "Math";