DEF_FONT_PATH :: "assets/fonts/AlbertSans-VariableFont_wght.ttf"; 

Glyph :: struct {
    quad           : AlignedQuad;
    x_pos, y_pos   : f32;
}

Font :: struct {
    path         : string;
    atlas        : Texture;
    glyphs       : Table(u8, Glyph);
    is_init      : bool;
    pixel_height : s32;
}

is_font_init :: (font : *Font) -> bool {
    assert(font != null);
    return font.is_init;
}

init_font :: (font : *Font, path : string = DEF_FONT_PATH) {
    assert(!is_font_init(font));
    #import "StbTrueType";
    
    file, success := File.file_open(path);
    if !success {
        log_error("Could not open file %.\n", path);
        return;
    }

    length := File.file_length(file);
    buffer := cast(*u8) alloc(length);
    defer free(buffer);

    success = File.file_read(file, buffer, length);
    if !success {
        log_error("Could not read from %.\n", path);
        return;
    }

    PIXEL_HEIGHT        :: 64;
    HEIGHT              :: 1024;
    WIDTH               :: 1024;
    CHAR_COUNT          :: 256;
    PIXELS_ALPHA_LENGTH :: HEIGHT * WIDTH;
    PIXELS_RGB_LENGTH   :: PIXELS_ALPHA_LENGTH * 4;
    font.pixel_height = PIXEL_HEIGHT;
    
    array_resize(*font.atlas.pixels, PIXELS_RGB_LENGTH ); //pending free
    pixels_rgb := font.atlas.pixels;

    pixels_alpha := NewArray(PIXELS_ALPHA_LENGTH, u8);
    defer array_free(pixels_alpha);

    baked_char := NewArray(CHAR_COUNT, Bakedchar); //pending free
    defer array_free(baked_char);

    bake_font_bitmap(buffer, 0, PIXEL_HEIGHT, pixels_alpha.data, WIDTH, HEIGHT, 0, CHAR_COUNT, baked_char.data);
    
    curr_index := 0;
    pixels_index := 0;
    for i : 0..PIXELS_RGB_LENGTH - 1 {
        curr_index += 1;
        if curr_index == 4 {
            pixels_rgb[i] = pixels_alpha[pixels_index];
            pixels_index += 1;
            curr_index = 0;
            continue;
        }

        pixels_rgb[i] = 255;
    };

    font.atlas.width  = WIDTH;
    font.atlas.height = HEIGHT;
    font.atlas.channels = 4;
    
    for i : 0..255 {
        x_pos, y_pos : f32;
        glyph : Glyph;
        get_baked_quad(
              baked_char.data
            , xx font.atlas.width
            , xx font.atlas.height
            , xx i
            , *glyph.x_pos
            , *glyph.y_pos
            , *glyph.quad
            , 1
        );
        table_add(*font.glyphs, xx i, glyph);
    }

    upload_texture_to_gpu(*font.atlas);

    font.is_init = true;
}

fill_glyph :: (font : *Font, glyph : *Glyph, c : u8) {
    assert(is_font_init(font));
    assert(table_contains(*font.glyphs, c));
    success := false;
    success, glyph.* = table_find_new(*font.glyphs, c);
    assert(success);
}

deinit_font :: (font : *Font) {
    assert(is_font_init(font));
    deinit_texture(*font.atlas);
    deinit(*font.glyphs);
    font.* = .{};
}