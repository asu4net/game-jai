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
    index := init(*entities_2d, 0);
    defer deinit(*entities_2d);

    {
        a := create_entity(Entity2D);
        a.pos = UP_2D;
        a.visible = true;
        a.tint = WHITE;
        a.scl = ONE_2D;
        a.item = "player"; 
        a.blend = .ALPHA;
        a.size = ONE_2D;
    }

    {
        a := create_entity(Entity2D);
        a.visible = true;
        a.tint = WHITE;
        a.scl = ONE_2D;
        a.item = "alien"; 
        a.blend = .ALPHA;
        a.size = ONE_2D;
    }

    {
        a := create_entity(Entity2D);
        a.pos = RIGHT_2D;
        a.visible = true;
        a.tint = WHITE;
        a.scl = ONE_2D;
        a.item = "kazmikaze_saw"; 
        a.blend = .ALPHA;
        a.size = ONE_2D;
    }

    {
        a := create_entity(Entity2D);
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
            if !is_enabled(e) then continue;

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

        draw_imgui(window);
        
        reset_temporary_storage();
    }
}

// Modules
#import "Basic"()(MEMORY_DEBUGGER=true);
#import "System";
#import "Compiler";
#import "String";
#import "Hash_Table";
#import "Math";
#import "File";
#import "File_Utilities";

// Vendor Modules
#import "SDL";
#import "GL" (DUMP_GL_ERRORS = true);
#import "stb_image";
#import "stb_truetype";
#import "stb_image_write";
#import "Jaison";
ImGui :: #import "ImGui";

// Core
#load "core/constants.jai";
#load "core/math.jai";
#load "core/window.jai";
#load "core/queue.jai";
#load "core/sparse_set.jai";
#load "core/sdl.jai";
#load "core/imgui_sdl_gl.jai";

// Entity
#load "entity/entity_array.jai";
#load "entity/entity.jai";

// Graphics
#load "graphics/constants.jai";
#load "graphics/draw_2d.jai";
#load "graphics/api.jai";
#load "graphics/buffer_object.jai";
#load "graphics/shader.jai";
#load "graphics/texture.jai";
#load "graphics/font.jai";
#load "graphics/render_camera.jai";
#load "graphics/spritesheet.jai";

//#TODO_asuarez
/*
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
*/