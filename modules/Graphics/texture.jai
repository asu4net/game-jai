Min_Filter :: enum {
    LINEAR;
    NEAREST;
}

Mag_Filter :: enum {
    LINEAR;
    NEAREST;
}

Wrap_Mode :: enum {
    REPEAT;
    CLAMP_TO_EDGE;
}

Texture_Coordinate :: enum {
    U;
    V;
}

Texture :: struct {
    id : u32;
    width : u32;
    height : u32;
    channels : u32;
    min_filter : Min_Filter;
    mag_filter : Mag_Filter;
    wrap_mode_u : Wrap_Mode;
    wrap_mode_v : Wrap_Mode;
    pixels : [..] u8;
    image_path : string;
    stbi_loaded : bool;
}

upload_texture_to_gpu :: (using texture : *Texture) {
    assert(id == 0);
    
    data_format     : u32 = GL_ZERO;
    internal_format : u32 = GL_ZERO;
    
    if channels == 4 {
        internal_format = GL_RGBA8;
        data_format = GL_RGBA;
    } 
    else if channels == 3 {
        internal_format = GL_RGB8;
        data_format = GL_RGB;
   }

    local_id : u32;
    glCreateTextures(GL_TEXTURE_2D, 1, *local_id);
    id = local_id;
    
    glTextureStorage2D(id, 1, internal_format, width, height);

    set_min_filter(id, min_filter);
    set_mag_filter(id, mag_filter);

    set_wrap_mode(id, .U, wrap_mode_u);
    set_wrap_mode(id, .V, wrap_mode_v);

    glTextureSubImage2D(id, 0, 0, 0, width, height, data_format, GL_UNSIGNED_BYTE, pixels.data);
}

init_white_texture :: (using texture : *Texture) {
    width = 1;
    height = 1;
    channels = 4;
    assert(pixels.data == null);
    for i : 0..3 {
        array_add(*pixels, 255);
    }
    upload_texture_to_gpu(texture);
}

init_texture :: (
    texture  : *Texture, 
    path     : string, 
    mag      : Mag_Filter = .LINEAR,
    min      : Min_Filter = .LINEAR,
    wrap_u   : Wrap_Mode  = .REPEAT,
    wrap_v   : Wrap_Mode  = .REPEAT
) {
    using texture;
    
    mag_filter = mag;
    min_filter = min;
    wrap_mode_u = wrap_u;
    wrap_mode_v = wrap_v;
    
    image_path = path;

    assert(pixels.data == null);
    assert(image_path.count != 0);

    stbi_set_flip_vertically_on_load(1);
    
    x, y, c : s32;
    
    pixels.data = stbi_load(image_path.data, *x, *y, *c, 0);
    assert(pixels.data != null);
    stbi_loaded = true;

    pixels.count = x * y * c;
    
    width    = xx x;
    height   = xx y;
    channels = xx c;

    upload_texture_to_gpu(texture);
}

deinit_texture :: (using texture : *Texture) {
    assert(id != 0);
    glDeleteTextures(1, *id);
    assert(pixels.data != null);
    if stbi_loaded {
        stbi_image_free(pixels.data);
    } else {
        array_free(pixels);
    }
    texture.* = .{};
}

bind :: (using texture : *Texture, slot : u32 = 0) {
    assert(id != 0);
    glBindTextureUnit(slot, id);
}

set_mag_filter :: (texture_id : u32, mag_filter : Mag_Filter) {
    if mag_filter == {
        case .LINEAR;  glTextureParameteri(texture_id, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        case .NEAREST; glTextureParameteri(texture_id, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    }
}

set_min_filter :: (texture_id : u32, min_filter : Min_Filter) {
    if min_filter == {
        case .LINEAR;  glTextureParameteri(texture_id, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        case .NEAREST; glTextureParameteri(texture_id, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    }
}

set_wrap_mode :: (texture_id : u32, texture_coordinate : Texture_Coordinate, wrap_mode : Wrap_Mode) {
    coord := ifx texture_coordinate == .U then GL_TEXTURE_WRAP_S else GL_TEXTURE_WRAP_T;
    if wrap_mode == {
        case .REPEAT; glTextureParameteri(texture_id, cast(u32) coord, GL_REPEAT);
        case .CLAMP_TO_EDGE; glTextureParameteri(texture_id, cast(u32) coord, GL_CLAMP_TO_EDGE);
    }
}