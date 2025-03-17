Glyph :: struct {
    x0, y0, s0, t0 : float32; // top-left
    x1, y1, s1, t1 : float32; // bottom-right
    x_pos, y_pos   : float32;
}

Font :: struct {
    path       : string;
    is_init    : bool;
    baked_char : [] Bakedchar;
    atlas      : Texture;
}

font_is_init :: (font : *Font) -> bool {
    assert(font != null);
    return font.is_init;
}

init_font :: (font : *Font, path : string) {
    assert(!font_is_init(font));
    
    file, success := file_open(path);
    if !success {
        log_error("Could not open file %.\n", path);
        return;
    }

    length := file_length(file);
    buffer := cast(*u8) alloc(length);
    defer free(buffer);

    success = file_read(file, buffer, length);
    if !success {
        log_error("Could not read from %.\n", path);
        return;
    }

    PIXEL_HEIGHT        :: 64.0;
    HEIGHT              :: 1024;
    WIDTH               :: 1024;
    CHAR_COUNT          :: 256;
    PIXELS_ALPHA_LENGTH :: HEIGHT * WIDTH;
    PIXELS_RGB_LENGTH   :: PIXELS_ALPHA_LENGTH * 4;

    array_resize(*font.atlas.pixel_data, PIXELS_RGB_LENGTH ); //pending free
    pixels_rgb := font.atlas.pixel_data;

    pixels_alpha := NewArray(PIXELS_ALPHA_LENGTH, u8);
    defer array_free(pixels_alpha);

    font.baked_char = NewArray(CHAR_COUNT, Bakedchar); //pending free

    bake_font_bitmap(buffer, 0, PIXEL_HEIGHT, pixels_alpha.data, WIDTH, HEIGHT, 0, CHAR_COUNT, font.baked_char.data);
    
    curr_index := 0;
    pixels_index := 0;
    for i : 0..PIXELS_RGB_LENGTH -1 {
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

    upload_texture_to_gpu(*font.atlas);

    font.is_init = true;
}

fini_font :: (font : *Font) {
    assert(font_is_init(font));
    array_free(font.baked_char);
    fini_texture(*font.atlas);
    font.* = .{};
}

#scope_file