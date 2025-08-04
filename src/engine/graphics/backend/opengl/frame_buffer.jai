Frame_Buffer :: struct {

    Texture_Format :: enum {
        NONE;

        // Color
        RGBA8;
        RED_INTEGER;

        // Depth/stencil
        DEPTH24STENCIL8;
    }

    Attachment_Spec :: struct {
        texture_format: Texture_Format;
    }

    Spec :: struct {
        width: int;
        height: int;
        samples: int = 1;
        attachments: [] Attachment_Spec;
    }

    spec: Spec;
    fbo: u32;
    color_attachment_specs: [..] Attachment_Spec;
    depth_attachment_spec: Attachment_Spec;
    color_attachments: [..] u32;
    depth_attachment: u32;
}

init_frame_buffer :: (fb: *Frame_Buffer, spec: Frame_Buffer.Spec) {
    fb.spec = spec;

    for spec.attachments {
        if is_depth_format(it.texture_format) {
            fb.depth_attachment_spec = it;
        } else {
            array_add(*fb.color_attachment_specs, it);
        }
    }

    invalidate_frame_buffer(fb);
}

deinit_frame_buffer :: (fb: *Frame_Buffer) {
    glDeleteFramebuffers(1, *fb.fbo);
    glDeleteTextures(xx fb.color_attachments.count, fb.color_attachments.data);
    glDeleteTextures(1, *fb.depth_attachment);
}

invalidate_frame_buffer :: (fb: *Frame_Buffer) {
    if fb.fbo != 0 {
        glDeleteFramebuffers(1, *fb.fbo);
        glDeleteTextures(xx fb.color_attachments.count, fb.color_attachments.data);
        glDeleteTextures(1, *fb.depth_attachment);

        array_reset(*fb.color_attachments);
        fb.depth_attachment = 0;
    }

    glCreateFramebuffers(1, *fb.fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, fb.fbo);

    multisample := fb.spec.samples > 1;

    if fb.color_attachment_specs.count > 0 {
        array_resize(*fb.color_attachments, fb.color_attachment_specs.count);
        create_textures(multisample, cast(u32) fb.color_attachments.count);

        for i : 0..fb.color_attachments.count-1 {
            bind_texture(multisample, fb.color_attachments[i]);

            format := fb.color_attachment_specs[i].texture_format;
            if format == {
                case .RGBA8; {
                    attach_color_texture(fb.color_attachments[i], xx fb.spec.samples, GL_RGBA8, GL_RGBA, fb.spec.width, fb.spec.height, cast(int)i);
                }
                case .RED_INTEGER; {
                    attach_color_texture(fb.color_attachments[i], xx fb.spec.samples, GL_R32I, GL_RED_INTEGER, fb.spec.width, fb.spec.height, cast(int)i);
                }
            }
        }
    }

    if fb.depth_attachment_spec.texture_format != .NONE {
        create_textures(multisample, 1);
        bind_texture(multisample, fb.depth_attachment);

        if fb.depth_attachment_spec.texture_format == .DEPTH24STENCIL8 {
            attach_depth_texture(fb.depth_attachment, fb.spec.samples, GL_DEPTH24_STENCIL8, GL_DEPTH_STENCIL_ATTACHMENT, xx fb.spec.width, xx fb.spec.height);
        }
    }

    if fb.color_attachments.count > 1 {
        assert(fb.color_attachments.count <= 4);
        buffers := GLenum.[xx GL_COLOR_ATTACHMENT0, xx GL_COLOR_ATTACHMENT1, xx GL_COLOR_ATTACHMENT2, xx GL_COLOR_ATTACHMENT3];
        glDrawBuffers(cast(GLsizei) fb.color_attachments.count, buffers.data);
    } else if fb.color_attachments.count == 0 {
        glDrawBuffer(GL_NONE);
    }

    assert(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

framebuffer_bind :: (fb: *Frame_Buffer) {
    glBindFramebuffer(GL_FRAMEBUFFER, fb.fbo);
    glViewport(0, 0, xx fb.spec.width, xx fb.spec.height);
}

framebuffer_unbind :: () {
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

framebuffer_resize :: (fb: *Frame_Buffer, width: u32, height: u32) {
    if width == 0 || height == 0 {
        log_error("Attempted to resize framebuffer to %, %", width, height);
        return;
    }

    fb.spec.width = width;
    fb.spec.height = height;
    invalidate_frame_buffer(fb);
}

framebuffer_read_pixel :: (fb: *Frame_Buffer, attachment_index: u32, x: int, y: int) -> int {
    assert(attachment_index < fb.color_attachments.count);
    glReadBuffer(GL_COLOR_ATTACHMENT0 + attachment_index);

    pixel_data: int;
    glReadPixels(xx x, xx y, 1, 1, GL_RED_INTEGER, GL_INT, *pixel_data);
    return pixel_data;
}

framebuffer_clear_attachment :: (fb: *Frame_Buffer, attachment_index: u32, value: int) {
    assert(attachment_index < fb.color_attachments.count);
    spec := fb.color_attachment_specs[attachment_index];
    glClearTexImage(fb.color_attachments[attachment_index], 0, fb_format_to_gl(spec.texture_format), GL_INT, *value);
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

attach_color_texture :: (id: u32, samples: u32, internal_format: GLenum, format: GLenum, width: int, height: int, index: int) {
    multisampled := samples > 1;
    if multisampled {
        glTexImage2DMultisample(GL_TEXTURE_2D_MULTISAMPLE, samples, internal_format, xx width, xx height, GL_FALSE);
    } else {
        glTexImage2D(GL_TEXTURE_2D, 0, xx internal_format, xx width, xx height, 0, format, GL_UNSIGNED_BYTE, null);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0 + cast(u32) index, texture_target(multisampled), id, 0);
}

attach_depth_texture :: (id: u32, samples: int, format: GLenum, attachment_type: GLenum, width: u32, height: u32) {
    multisampled := samples > 1;
    if multisampled {
        glTexImage2DMultisample(GL_TEXTURE_2D_MULTISAMPLE, xx samples, format, width, height, GL_FALSE);
    } else {
        glTexStorage2D(GL_TEXTURE_2D, 1, format, width, height);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_R, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    glFramebufferTexture2D(GL_FRAMEBUFFER, attachment_type, texture_target(multisampled), id, 0);
}

is_depth_format :: inline (format: Frame_Buffer.Texture_Format) -> bool {
    return format == .DEPTH24STENCIL8;
}

fb_format_to_gl :: inline (format: Frame_Buffer.Texture_Format) -> GLenum {
    if format == {
        case .RGBA8; return GL_RGBA8;
        case .RED_INTEGER; return GL_RED_INTEGER;
        case; return 0;
    }
}