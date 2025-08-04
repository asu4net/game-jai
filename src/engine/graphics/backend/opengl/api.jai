Blend :: enum {
    NONE;
    ALPHA;
    SOLID;
    ADD;
    MULTIPLY;
}

Shader_Data_Type :: enum {
    None; Float; Float2; Float3; Float4; Mat3; Mat4; Int; Sampler2D; Int2; Int3; Int4; Bool;
}

shader_data_type_from_gl :: (type: int) -> Shader_Data_Type {
    if type == {
        case GL_FLOAT      ; return .Float;
        case GL_FLOAT_VEC2 ; return .Float2;
        case GL_FLOAT_VEC3 ; return .Float3;
        case GL_FLOAT_VEC4 ; return .Float4;
        case GL_FLOAT_MAT3 ; return .Mat3;
        case GL_FLOAT_MAT4 ; return .Mat4;
        case GL_INT        ; return .Int;
        case GL_INT_VEC2   ; return .Int2;
        case GL_INT_VEC3   ; return .Int3;
        case GL_INT_VEC4   ; return .Int4;
        case GL_SAMPLER_2D ; return .Sampler2D;
        case GL_BOOL       ; return .Bool;
    }
    return .None;
}

shader_data_type_to_gl :: (type: Shader_Data_Type) -> u32 {
    if type == {
        case .Float     ; return GL_FLOAT;
        case .Float2    ; return GL_FLOAT;
        case .Float3    ; return GL_FLOAT;
        case .Float4    ; return GL_FLOAT;
        case .Mat3      ; return GL_FLOAT;
        case .Mat4      ; return GL_FLOAT;
        case .Int       ; return GL_INT;
        case .Int2      ; return GL_INT;
        case .Int3      ; return GL_INT;
        case .Int4      ; return GL_INT;
        case .Sampler2D ; return GL_SAMPLER_2D;
        case .Bool      ; return GL_BOOL;
        case .None      ; return 0;
    }
    return 0;
}

shader_data_type_to_size :: (type: Shader_Data_Type) -> u32 {
    if type == {
        case .Float     ; return 4;         
        case .Float2    ; return 4 * 2;
        case .Float3    ; return 4 * 3;
        case .Float4    ; return 4 * 4;
        case .Mat3      ; return 4 * 3 * 3;
        case .Mat4      ; return 4 * 4 * 4;
        case .Int       ; return 4;
        case .Sampler2D ; return 32;
        case .Int2      ; return 4 * 2;
        case .Int3      ; return 4 * 3;
        case .Int4      ; return 4 * 4;
        case .Bool      ; return 1;
        case .None      ; return 0;
    }
    return 0;
}

shader_data_type_to_count :: (type: Shader_Data_Type) -> s32 {
    if type == {
        case .Float     ; return 1;         
        case .Float2    ; return 2;
        case .Float3    ; return 3;
        case .Float4    ; return 4;
        case .Mat3      ; return 3 * 3;
        case .Mat4      ; return 4 * 4;
        case .Int       ; return 1;
        case .Sampler2D ; return 32;
        case .Int2      ; return 2;
        case .Int3      ; return 3;
        case .Int4      ; return 4;
        case .Bool      ; return 1;
        case .None      ; return 0;
    }
    return 0;
}

set_viewport :: (width: u32, height: u32, x: u32 = 0, y: u32 = 0) {
    glViewport(xx x, xx y, xx width, xx height);
}

set_clear_color :: (r: f32, g: f32, b: f32, a: f32) {
    glClearColor(r, g, b, a);
}

set_clear_color :: (v: Vector4) {
    glClearColor(xx v.x, xx v.y, xx v.z, xx v.w);
}

clear_screen :: () {
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
}

set_blend_enabled :: (enabled: bool = true) {
    if enabled {
        glEnable(GL_BLEND);
        return;
    }

    glDisable(GL_BLEND);
}

set_blend_mode :: (blend : Blend) {
    set_blend_enabled();
    if blend == {
        case .NONE;
             assert(false);
            return;
        case .SOLID;
            glBlendFunc(GL_ONE, GL_ZERO);               
            return;
        case .ALPHA;
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            return;
        case .ADD;
            glBlendFunc(GL_SRC_ALPHA, GL_ONE);               
            return;
        case .MULTIPLY;
            glBlendFuncSeparate(GL_DST_COLOR, GL_ONE, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);              
            return;
    }
}

set_depth_test_enabled :: (enabled : bool = true) {
    if enabled then {
        glEnable(GL_DEPTH_TEST);
        return;
    }
    glDisable(GL_DEPTH_TEST);
}

draw_elements :: (vao : *Vertex_Array, element_count : u32) {
    bind(vao);
    glDrawElements(GL_TRIANGLES, xx element_count, GL_UNSIGNED_INT, null);
    unbind(vao);
}

/*
set_vsync_enabled :: inline (enabled: bool = true) {
    wglSwapIntervalEXT(xx enabled);
}

swap_buffers :: () {
    using context.engine;
    
    #if OS == .WINDOWS {
        #import "Windows";
        dc := GetDC(window);
        SwapBuffers(dc);
    } else #if OS == .LINUX {
        info := find_window_info(window);
        if (!info) || !info.specific.glx_window {
            log_error("Engine: Attempt to swap_buffers on a previously unseen window!\n");
            return;
        }

        glXSwapBuffers(x_global_display, info.specific.glx_window);
    } else #if OS == .MACOS {
        // On macOS, OpenGL buffer swapping is done on the context, not on the view.
        // So we can only swap for the active window. (And you need to swap before switching to another view).
        NSOpenGLContext.flushBuffer(the_gl_context);
    } else #if OS == .ANDROID {
        // I think it's gonna make more sense for display and surface to be on the specific window info, then
        // we will have to get the window here like Linux does.
        eglSwapBuffers(the_egl_display, the_egl_surface);
    } else {
        assert(false);
    }
}
*/