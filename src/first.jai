Game :: struct {
    window  : Window;
    draw_2d : Draw2D_Context;
    alien   : Texture;
    font    : Font;
}

#add_context game: Game;

main :: () {

    defer report_memory_leaks();

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
    init_spritesheet(*sheet, src_path = "assets/images");
    defer fini_spritesheet(*sheet);

    while keep_window_opened(window) {
        
        clear_screen();
        
        draw_2d_begin(.{window.width, window.height});
        {
            {
                rect, found := table_find(*sheet.rects, "player");

                if found then {
                    draw_quad(pos = UP_2D, texture = *sheet.texture, flags = .USE_SUBTEX | .AUTOSIZE, rect = rect);
                }
            }
            
            draw_quad(sca = .{1, -1}, texture = *font.atlas);
            draw_quad(pos = LEFT_2D, texture = *sheet.texture); 
            draw_text(pos = DOWN_2D * 0.5, text = "Habemos texto", font, 0.125, tint = LIGHT_GREEN);
            //draw_circle(pos = RIGHT_2D, tint = LIGHT_BLUE);
            
            {
                rect, found := table_find(*sheet.rects, "alien");

                if found then {
                    draw_gui_quad(pos = .{ 100, 100 }, texture = *sheet.texture, flags = .USE_SUBTEX, rect = rect);
                }
            }
        }
        draw_2d_end();

        reset_temporary_storage();
    }

    //Unmapping_Allocator 
}

#scope_file

#import "System";
#import "String";
#import "Basic";
#import "Core";
#import "Graphics";
#import "Math";
#import "Hash_Table";
#import "Basic"()(MEMORY_DEBUGGER=true);