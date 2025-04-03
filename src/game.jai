Game :: struct {
    window  : Window;
    draw_2d : Draw2D_Context;
    alien   : Texture;
    font    : Font;
}

#add_context game: Game;

Sprite :: struct {
    visible  : bool;
    tint     : Vector4;
    rect     : Rect;
    item     : string;
    tiling   : Vector2;
    flip_x   : bool;
    flip_y   : bool;
    autosize : bool;
    blend    : Blend;
}

Entity2D :: struct {
    #as using entity : Entity;
    using sprite : Sprite;

    pos        : Vector2;
    scl        : Vector2;
    ang        : float32;
    size       : Vector2;
}

main :: () {

    defer report_memory_leaks();

    path := path_strip_filename(get_path_of_running_executable());
    set_working_directory(path);
    
    window  := *context.game.window;
    alien   := *context.game.alien;
    font    := *context.game.font;
    draw_2d := *context.game.draw_2d;

    init(window);
    defer deinit(window);

    init(draw_2d);
    defer deinit(draw_2d);

    init(alien, "assets/images/alien.png", mag = .LINEAR, min = .LINEAR);    
    defer deinit(alien);

    init(font, "assets/fonts/AlbertSans-VariableFont_wght.ttf");
    defer deinit(font);
    
    set_clear_color(DARK_GRAY);

    sheet : Spritesheet;
    init(*sheet, src_path = "assets/images");
    defer deinit(*sheet);

    entities_2d : Entity_Array(Entity2D);
    index := entity_array_init(*entities_2d, 0);
    defer entity_array_deinit(*entities_2d);

    {
        a := entity_create(Entity2D);
        a.pos = UP_2D;
        a.visible = true;
        a.tint = WHITE;
        a.scl = ONE_2D;
        a.item = "player"; 
        a.blend = .ALPHA;
        a.size = ONE_2D;
    }

    {
        a := entity_create(Entity2D);
        a.visible = true;
        a.tint = WHITE;
        a.scl = ONE_2D;
        a.item = "alien"; 
        a.blend = .ALPHA;
        a.size = ONE_2D;
    }

    {
        a := entity_create(Entity2D);
        a.pos = RIGHT_2D;
        a.visible = true;
        a.tint = WHITE;
        a.scl = ONE_2D;
        a.item = "kazmikaze_saw"; 
        a.blend = .ALPHA;
        a.size = ONE_2D;
    }

    {
        a := entity_create(Entity2D);
        a.pos = DOWN_2D;
        a.visible = true;
        a.tint = WHITE;
        a.scl = ONE_2D;
        a.blend = .ALPHA;
        a.size = ONE_2D;
    }

    while keep_window_opened(window) {
        
        clear_screen();
        draw_2d_begin(.{window.width, window.height});
        
        for i : 1..entities_2d.used_ids.count {
            
            e := (*entities_2d.data[i]).(*Entity2D);
            if !entity_global_enabled(e) then continue;

            tex   := ifx e.item.count > 0 then *sheet.tex else null;
            flags := ifx e.item.count > 0 then DEFAULT_QUAD_FLAGS | .USE_SUBTEX else DEFAULT_QUAD_FLAGS;

            // try find the item
            if tex && (e.rect.width == 0 || e.rect.height == 0) {
                rect, found := table_find(*sheet.rects, e.item);
                e.rect = ifx found then rect;
            }

            draw_quad(e.pos, e.ang, e.scl, tex, e.tiling, e.size, e.blend, e.rect, e.tint, e.id, flags);
        }
        
        draw_2d_end();

        /*
        draw_2d_begin(.{window.width, window.height});
        {
            {
                rect, found := table_find(*sheet.rects, "player");

                if found then {
                    draw_quad(pos = UP_2D, texture = *sheet.texture, flags = .USE_item | .AUTOSIZE, rect = rect);
                }
            }
            
            draw_quad(sca = .{1, -1}, texture = *font.atlas);
            draw_quad(pos = LEFT_2D, texture = *sheet.texture); 
            draw_text(pos = DOWN_2D * 0.5, text = "Habemos texto", font, 0.125, tint = LIGHT_GREEN);
            draw_circle(pos = RIGHT_2D, tint = LIGHT_BLUE);
            
            {
                rect, found := table_find(*sheet.rects, "alien");

                if found then {
                    draw_gui_quad(pos = .{ 300, 300 }, texture = *sheet.texture, flags = .USE_item, rect = rect);
                }

                draw_gui_text(pos = .{ 100, 100 }, font=font, text= "Some gui text!");
            }
        }
        draw_2d_end();
        */
        reset_temporary_storage();
    }
    //Unmapping_Allocator 
}

#scope_file

#import "Basic"()(MEMORY_DEBUGGER=true);
#import "System";
#import "Compiler";
#import "String";
#import "Hash_Table";
#import "Math";
#import "File";
#import "File_Utilities";

#import "SDL";
#import "GL" (DUMP_GL_ERRORS = true);
#import "stb_image";
#import "stb_truetype";
#import "stb_image_write";
#import "Jaison";

#load "core/constants.jai";
#load "core/math.jai";
#load "core/window.jai";
#load "core/queue.jai";
#load "core/sparse_set.jai";
#load "core/sdl.jai";

#load "entity/entity_array.jai";
#load "entity/entity.jai";

#load "graphics/constants.jai";
#load "graphics/draw_2d.jai";
#load "graphics/api.jai";
#load "graphics/buffer_object.jai";
#load "graphics/shader.jai";
#load "graphics/texture.jai";
#load "graphics/font.jai";
#load "graphics/render_camera.jai";
#load "graphics/spritesheet.jai";

//TODO:
/*
- Usar 0 como valor invalido en el sparse set y en las entidades?
- texture options for sprite_sheet (maybe could be a struct??)
- Optimize the 2d version of make_transform
- Implement a bumb allocator in the renderer. (I think its the pool thing in the modules folder).
- Intentar generalizar un poco más las llamadas de draw, convertir en función el draw header
- Leer shaders de ficheros
- Poder cambiar de shader
- Dumpear errores de OpenGL
- Meter ImGUI
- Implementar frame buffer y renderizar a una textura (Con esto se pueden meter FX de cámara)
- Picking
- Sistema de iluminación: Ambient y Point lights

Spritesheet :: struct {
    textures:   Bucket_Array(*Texture, 8);
    frames:     Bucket_Array(Animation_Frame, 64);
    animations: Bucket_Array(Animation, 64);
    sprites:    Bucket_Array(Sprite, 16);
    index: struct {
        frames:     Table(string, *Animation_Frame);
        animations: Table(string, *Animation);
        sprites:    Table(string, *Sprite);
    }
}

Animation_Frame :: struct {
    id: string;
    rect: UV_Rect;
    texture: *Texture;  @NoSerialize
}
Animation :: struct {
    id: string;
    frame_rate: int;  // in ticks per frame
    frames: [] Animation_Frame;
}
Sprite :: struct {
    id: string;
    animations: [#run enum_highest_value(Direction)+1] *Animation;  // n w s e nw sw se ne
}

*/