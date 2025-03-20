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

    init_draw_2d(draw_2d);
    defer fini_draw_2d();

    init_texture_from_path(alien, "assets/images/alien.png", mag = .LINEAR, min = .LINEAR);    
    defer fini_texture(alien);

    init_font(font, "assets/fonts/AlbertSans-VariableFont_wght.ttf");
    defer fini_font(font);
    
    set_clear_color(DARK_GRAY);

    sheet : Spritesheet;
    generate_spritesheet("test_sheet", "assets/images/", "assets", 1024, *sheet);

    while keep_window_opened(window) {
        clear_screen();
        update_2d_camera(window.width, window.height);
        draw_quad(texture = alien);
        //draw_quad(transform = make_transfom(LEFT_3D, ZERO_3D, .{1, -1, 1}), texture = *font.atlas);
        draw_quad(transform = make_transfom(LEFT_3D, ZERO_3D, .{1, -1, 1}), texture = *sheet.texture);
        draw_text(transform = make_transfom(DOWN_3D * 0.5), "Habemos texto", font, 0.125, tint = LIGHT_GREEN);
        draw_circle(transform = make_transfom(RIGHT_3D), tint = LIGHT_BLUE);
        submit_drawings();
        reset_temporary_storage();
    }

    //Unmapping_Allocator 
    report_memory_leaks();
}

#scope_file

#import "System";
#import "String";
#import "Basic";
#import "Core";
#import "Graphics";
#import "Math";
#import "Basic"()(MEMORY_DEBUGGER=true);