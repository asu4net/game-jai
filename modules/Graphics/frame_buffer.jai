Frame_Buffer :: struct {

    Texture_Format :: enum {
        NONE;

        // Color
        RGBA8;
        RED_INTEGER;

        // Depth/stencil
        DEPTH24STENCIL8;
    }

    id      : u32;
    width   : int;
    height  : int;
    samples : int;
}

init :: (fb : *Frame_Buffer) {
    create_textures(true, 0);
}

#scope_module

MAX_FRAME_BUFFER_SIZE :: 8192;

texture_target :: inline (multisampled : bool) -> GLenum {
    return xx ifx multisampled then GL_TEXTURE_2D_MULTISAMPLE else GL_TEXTURE_2D;
}

create_textures :: inline (multisampled : bool, count : u32) -> u32 {
    out_id : u32;
    glCreateTextures(texture_target(multisampled), count, *out_id);
    return out_id;
}

bind_texture :: inline (multisampled : bool, id : u32) {
    glBindTexture(texture_target(multisampled), id);
}