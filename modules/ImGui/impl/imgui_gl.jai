Impl_CreateContext :: () {
    ui_state.ctx = CreateContext();

    io := GetIO();
    io.ConfigFlags_ |= .DockingEnable;
}

// This is the main rendering function that you have to implement and provide to ImGui (via setting up 'RenderDrawListsFn' in the ImGuiIO structure)
// Note that this implementation is little overcomplicated because we are saving/setting up/restoring every OpenGL state explicitly, in order to be able to run within any OpenGL engine that doesn't do so. 
// If text or lines are blurry when integrating ImGui in your engine: in your Render function, try translating your projection matrix by (0.5f,0.5f) or (0.375f,0.375f)
Impl_RenderDrawData :: () {
    // @@ Watch out, we don't have a context here!
    using ui_state;

    draw_data := GetDrawData();

    // Avoid rendering when minimized, scale coordinates for retina displays (screen coordinates != framebuffer coordinates)
    io := GetIO();
    fb_width := (io.DisplaySize.x * io.DisplayFramebufferScale.x);
    fb_height := (io.DisplaySize.y * io.DisplayFramebufferScale.y);
    if fb_width == 0 || fb_height == 0 return;
    draw_data.ScaleClipRects(draw_data, io.DisplayFramebufferScale);

    // Backup GL state
    last_active_texture: GLenum;        glGetIntegerv(GL_ACTIVE_TEXTURE, xx *last_active_texture);
    last_program: GLuint;               glGetIntegerv(GL_CURRENT_PROGRAM, xx *last_program);
    last_texture: GLuint;               glGetIntegerv(GL_TEXTURE_BINDING_2D, xx *last_texture);
    last_sampler: GLuint;               glGetIntegerv(GL_SAMPLER_BINDING, xx *last_sampler);
    last_array_buffer: GLuint;          glGetIntegerv(GL_ARRAY_BUFFER_BINDING, xx *last_array_buffer);
    last_element_array_buffer: GLuint;  glGetIntegerv(GL_ELEMENT_ARRAY_BUFFER_BINDING, xx *last_element_array_buffer);
    last_vertex_array: GLuint;          glGetIntegerv(GL_VERTEX_ARRAY_BINDING, xx *last_vertex_array);
    last_polygon_mode: [2]GLuint;       glGetIntegerv(GL_POLYGON_MODE, xx last_polygon_mode.data);
    last_viewport: [4]GLint;            glGetIntegerv(GL_VIEWPORT, last_viewport.data);
    last_scissor_box : [4]GLint;        glGetIntegerv(GL_SCISSOR_BOX, last_scissor_box.data);
    last_blend_src_rgb: GLenum;         glGetIntegerv(GL_BLEND_SRC_RGB, xx *last_blend_src_rgb);
    last_blend_dst_rgb: GLenum;         glGetIntegerv(GL_BLEND_DST_RGB, xx *last_blend_dst_rgb);
    last_blend_src_alpha: GLenum;       glGetIntegerv(GL_BLEND_SRC_ALPHA, xx *last_blend_src_alpha);
    last_blend_dst_alpha: GLenum;       glGetIntegerv(GL_BLEND_DST_ALPHA, xx *last_blend_dst_alpha);
    last_blend_equation_rgb: GLenum;    glGetIntegerv(GL_BLEND_EQUATION_RGB, xx *last_blend_equation_rgb);
    last_blend_equation_alpha: GLenum;  glGetIntegerv(GL_BLEND_EQUATION_ALPHA, xx *last_blend_equation_alpha);
    last_enable_blend :=                glIsEnabled(GL_BLEND);
    last_enable_cull_face :=            glIsEnabled(GL_CULL_FACE);
    last_enable_depth_test :=           glIsEnabled(GL_DEPTH_TEST);
    last_enable_scissor_test :=         glIsEnabled(GL_SCISSOR_TEST);

    // Setup render state: alpha-blending enabled, no face culling, no depth testing, scissor enabled, polygon fill
    glActiveTexture(GL_TEXTURE0);
    glEnable(GL_BLEND);
    glBlendEquation(GL_FUNC_ADD);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glDisable(GL_CULL_FACE);
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_SCISSOR_TEST);
    glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);

    // Setup viewport, orthographic projection matrix
    glViewport(0, 0, xx fb_width, xx fb_height);

    new_context: #Context;
    push_context new_context {
        ortho_projection := orthographic_projection_matrix(0, io.DisplaySize.x, io.DisplaySize.y, 0, 0, 1);
        ortho_projection = transpose(ortho_projection);

        glUseProgram(ShaderHandle);
        glUniform1i(AttribLocationTex, 0);
        glUniformMatrix4fv(AttribLocationProjMtx, 1, GL_FALSE, xx *ortho_projection);
        glBindVertexArray(VaoHandle);
        glBindSampler(0, 0); // Rely on combined texture/sampler state.

        // Render command lists
        for n: 0..draw_data.CmdListsCount-1 {
            cmd_list := draw_data.CmdLists.Data[n];
            idx_buffer_offset : *ImDrawIdx;

            glBindBuffer(GL_ARRAY_BUFFER, VboHandle);
            glBufferData(GL_ARRAY_BUFFER, cmd_list.VtxBuffer.Size * size_of(ImDrawVert), cmd_list.VtxBuffer.Data, GL_STREAM_DRAW);

            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ElementsHandle);
            glBufferData(GL_ELEMENT_ARRAY_BUFFER, cmd_list.IdxBuffer.Size * size_of(ImDrawIdx), cmd_list.IdxBuffer.Data, GL_STREAM_DRAW);

            for cmd_i: 0..cmd_list.CmdBuffer.Size-1 {
                pcmd := *cmd_list.CmdBuffer.Data[cmd_i];
                if pcmd.UserCallback {
                    pcmd.UserCallback(cmd_list, pcmd);
                }
                else {
                    glBindTexture(GL_TEXTURE_2D, xx pcmd.TextureId);
                    glScissor(xx pcmd.ClipRect.x, xx (fb_height - pcmd.ClipRect.w), xx (pcmd.ClipRect.z - pcmd.ClipRect.x), xx (pcmd.ClipRect.w - pcmd.ClipRect.y));
                    
                    glDrawElements(GL_TRIANGLES, pcmd.ElemCount, GL_UNSIGNED_SHORT, idx_buffer_offset);
                }
                idx_buffer_offset += pcmd.ElemCount;
            }
        }

        // Restore modified GL state
        glUseProgram(last_program);
        glBindTexture(GL_TEXTURE_2D, last_texture);
        glBindSampler(0, last_sampler);
        glActiveTexture(last_active_texture);
        glBindVertexArray(last_vertex_array);
        glBindBuffer(GL_ARRAY_BUFFER, last_array_buffer);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, last_element_array_buffer);
        glBlendEquationSeparate(last_blend_equation_rgb, last_blend_equation_alpha);
        glBlendFuncSeparate(last_blend_src_rgb, last_blend_dst_rgb, last_blend_src_alpha, last_blend_dst_alpha);
        if last_enable_blend        glEnable(GL_BLEND);         else glDisable(GL_BLEND);
        if last_enable_cull_face    glEnable(GL_CULL_FACE);     else glDisable(GL_CULL_FACE);
        if last_enable_depth_test   glEnable(GL_DEPTH_TEST);    else glDisable(GL_DEPTH_TEST);
        if last_enable_scissor_test glEnable(GL_SCISSOR_TEST);  else glDisable(GL_SCISSOR_TEST);
        glPolygonMode(GL_FRONT_AND_BACK, last_polygon_mode[0]);
        glViewport(last_viewport[0], last_viewport[1], xx last_viewport[2], xx last_viewport[3]);
        glScissor(last_scissor_box[0], last_scissor_box[1], xx last_scissor_box[2], xx last_scissor_box[3]);
    }
}

// You can read the io.WantCaptureMouse, io.WantCaptureKeyboard flags to tell if dear imgui wants to use your inputs.
// - When io.WantCaptureMouse is true, do not dispatch mouse input data to your main application.
// - When io.WantCaptureKeyboard is true, do not dispatch keyboard input data to your main application.
// Generally you may always pass all inputs to dear imgui, and hide them from your application based on those two flags.
Impl_ProcessEvent :: (event: Input.Event) -> bool {
    using Input;
    using ui_state;
    io := GetIO();
    if event.type == {
        // TODO: get mouse move events into jai's input handling code
        //case .MOUSE_MOVE;
            //return true;
        case .MOUSE_WHEEL;
            if event.wheel_delta > 0 MouseWheel = 1;
            if event.wheel_delta < 0 MouseWheel = -1;
            return true;
        case. KEYBOARD;
            if event.key_code == {
                case .MOUSE_BUTTON_LEFT;   
                    //MousePressed[0] = event.key_pressed != 0;
                case .MOUSE_BUTTON_RIGHT;  
                    //MousePressed[1] = event.key_pressed != 0;
                case .MOUSE_BUTTON_MIDDLE; 
                    //MousePressed[2] = event.key_pressed != 0;
                case;
                    io.AddKeyEvent(io, .ImGuiMod_Ctrl,  (event.key_code == .CTRL));
                    io.AddKeyEvent(io, .ImGuiMod_Shift, (event.key_code == .SHIFT));
                    io.AddKeyEvent(io, .ImGuiMod_Alt,   (event.key_code == .ALT));
                    io.AddKeyEvent(io, .ImGuiMod_Super, (event.key_code == .CMD));

                    key := Impl_KeyCodeToImGuiKey(event.key_code);
                    io.AddKeyEvent(io, key, event.key_pressed != 0);
            }
            return true;
        case .TEXT_INPUT;
            buf := talloc(size_of(s32) + 1); // unicode rune + 0
            memcpy(buf, *event.utf32, size_of(s32));
            io.AddInputCharactersUTF8(io, buf);
            return true;
    }
    return false;
}

Impl_Init :: () -> bool {
    using ui_state;
    assert(ctx != null, "must call create context");
    SetCurrentContext(ctx);

    print("imgui version %\n", to_string(GetVersion()));

    using Input.Key_Code;
    io := GetIO();

    io.SetClipboardTextFn = Impl_SetClipboardText;
    io.GetClipboardTextFn = Impl_GetClipboardText;
    io.ClipboardUserData = null;

    // TODO: Cursors

    Impl_CreateDeviceObjects();

    return true;
}

Impl_Shutdown :: () {
    using ui_state;
    SetCurrentContext(ui_state.ctx);
    Impl_InvalidateDeviceObjects();
    DestroyContext();
    ui_state.ctx = null;
}

Impl_NewFrame :: (display_width: s32, display_height: s32, current_time : f64) {
    using ui_state;

    io := GetIO();

    // Setup display size (every frame to accommodate for window resizing)
    io.DisplaySize = .{xx display_width, xx display_height};
    io.DisplayFramebufferScale = .{1, 1};

    // Setup time step
    if Time > 0.0 io.DeltaTime = xx (current_time - Time);
    else io.DeltaTime = (1.0/60.0);
    Time = current_time;
    
    // #TODO_asuarez: Do this platform agnostic.

    // Setup inputs
        #if OS == .WINDOWS {
        Win32 :: #import "Windows";
        get_client_mouse_pos :: () -> (x: s32, y: s32) {
            using context.window;
            point: Win32.POINT;
            Win32.GetCursorPos(*point);
            Win32.ScreenToClient(handle, *point);
            return point.x, point.y;
        }
    }

    mx, my := get_client_mouse_pos();
    io.MousePos = .{xx mx, xx my };

    io.MouseDown[0] = Input.input_button_states[xx Input.Key_Code.MOUSE_BUTTON_LEFT]   == .DOWN;
    io.MouseDown[1] = Input.input_button_states[xx Input.Key_Code.MOUSE_BUTTON_RIGHT]  == .DOWN;
    io.MouseDown[2] = Input.input_button_states[xx Input.Key_Code.MOUSE_BUTTON_MIDDLE] == .DOWN;

    io.MouseWheel = MouseWheel;
    MousePressed[0], MousePressed[1], MousePressed[2] = false, false, false;

    MouseWheel = 0.0;

    // Hide OS mouse cursor if ImGui is drawing it
    // TODO: cursors

    // Start the frame. This call will update the io.WantCaptureMouse, io.WantCaptureKeyboard flag that you can use to dispatch inputs (or not) to your application.
    NewFrame();
}

#scope_file

UI_State :: struct {
    ctx: *ImGuiContext;
    Time: float64 = 0.0;
    MousePressed: [3]bool = .[false, false, false];
    MouseWheel: float = 0.0;
    FontTexture: GLuint = 0;
    ShaderHandle: GLuint = 0;
    VertHandle: GLuint = 0;
    FragHandle: GLuint = 0;
    AttribLocationTex: GLint = 0;
    AttribLocationProjMtx: GLint = 0;
    AttribLocationPosition: GLuint = 0;
    AttribLocationUV: GLuint = 0;
    AttribLocationColor: GLuint = 0;
    VboHandle: GLuint = 0;
    VaoHandle: GLuint = 0;
    ElementsHandle: GLuint = 0;
};

ui_state : UI_State;

Impl_InvalidateDeviceObjects :: () {
    using ui_state;
    if FontTexture {
        glDeleteTextures(1, *FontTexture);
        GetIO().Fonts.TexID = 0;
        FontTexture = 0;
    }
}

Impl_CreateDeviceObjects :: () -> bool {
    // Backup GL state
    using ui_state;
    last_texture, last_array_buffer, last_vertex_array: GLuint;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, xx *last_texture);
    glGetIntegerv(GL_ARRAY_BUFFER_BINDING, xx *last_array_buffer);
    glGetIntegerv(GL_VERTEX_ARRAY_BINDING, xx *last_vertex_array);

    vertex_shader := #string END
        #version 330
        uniform mat4 ProjMtx;
        in vec2 Position;
        in vec2 UV;
        in vec4 Color;
        out vec2 Frag_UV;
        out vec4 Frag_Color;
        void main() {
           Frag_UV = UV;
           // By default, the binaries shipped with jai-imgui are built with IMGUI_USE_BGRA_PACKED_COLOR.
           // This is more efficient in D3D11, but in opengl there's no way to specify the input buffers
           // format to be BGRA, so we just do the swizzle here if our module parameter, also named
           // IMGUI_USE_BGRA_PACKED_COLOR, is true.
           Frag_Color = Color.rgba;
           gl_Position = ProjMtx * vec4(Position.xy,0,1);
        }
    END;

    fragment_shader := #string END
        #version 330
        uniform sampler2D Texture;
        in vec2 Frag_UV;
        in vec4 Frag_Color;
        out vec4 Out_Color;
        void main() {
           Out_Color = Frag_Color * texture( Texture, Frag_UV.st).r;
        }
    END

    ShaderHandle = glCreateProgram();
    VertHandle = glCreateShader(GL_VERTEX_SHADER);
    FragHandle = glCreateShader(GL_FRAGMENT_SHADER);
    _glShaderSource(VertHandle, vertex_shader);
    _glShaderSource(FragHandle, fragment_shader);
    glCompileShader(VertHandle);
    glCompileShader(FragHandle);
    glAttachShader(ShaderHandle, VertHandle);
    glAttachShader(ShaderHandle, FragHandle);
    glLinkProgram(ShaderHandle);

    AttribLocationTex = glGetUniformLocation(ShaderHandle, "Texture");
    AttribLocationProjMtx = glGetUniformLocation(ShaderHandle, "ProjMtx");
    AttribLocationPosition = xx glGetAttribLocation(ShaderHandle, "Position");
    AttribLocationUV = xx glGetAttribLocation(ShaderHandle, "UV");
    AttribLocationColor = xx glGetAttribLocation(ShaderHandle, "Color");

    glGenBuffers(1, *VboHandle);
    glGenBuffers(1, *ElementsHandle);

    glGenVertexArrays(1, *VaoHandle);
    glBindVertexArray(VaoHandle);
    glBindBuffer(GL_ARRAY_BUFFER, VboHandle);
    glEnableVertexAttribArray(AttribLocationPosition);
    glEnableVertexAttribArray(xx AttribLocationUV);
    glEnableVertexAttribArray(xx AttribLocationColor);

    // @@ Is there a function to easily get the offset of a member?
    //ImDrawVert :: struct {
    //   pos: ImVec2;       // 0
    //   uv: ImVec2;        // 8
    //   col: s32;          // 16
    //}
    glVertexAttribPointer(AttribLocationPosition, 2, GL_FLOAT, GL_FALSE, size_of(ImDrawVert), xx 0);
    glVertexAttribPointer(AttribLocationUV, 2, GL_FLOAT, GL_FALSE, size_of(ImDrawVert), xx 8);
    glVertexAttribPointer(AttribLocationColor, 4, GL_UNSIGNED_BYTE, GL_TRUE, size_of(ImDrawVert), xx 16);

    Impl_CreateFontsTexture();

    // Restore modified GL state
    glBindTexture(GL_TEXTURE_2D, last_texture);
    glBindBuffer(GL_ARRAY_BUFFER, last_array_buffer);
    glBindVertexArray(last_vertex_array);

    return true;
}

Impl_KeyCodeToImGuiKey :: (keycode : Input.Key_Code) -> Key {
    using ui_state;
    using Input.Key_Code;
    if keycode == {
        case TAB;           return .Tab;
        case ARROW_LEFT;    return .LeftArrow;
        case ARROW_RIGHT;   return .RightArrow;
        case ARROW_UP;      return .UpArrow;
        case ARROW_DOWN;    return .DownArrow;
        case PAGE_UP;       return .PageUp;
        case PAGE_DOWN;     return .PageDown;
        case HOME;          return .Home;
        case END;           return .End;
        case INSERT;        return .Insert;
        case DELETE;        return .Delete;
        case BACKSPACE;     return .Backspace;
        case SPACEBAR;      return .Space;
        case ENTER;         return .Enter;
        case ESCAPE;        return .Escape;
        case 44;            return .Comma;          // ','
        case 46;            return .Period;         // '.'
        case 59;            return .Semicolon;      // ';'
        case 61;            return .Equal;          // '='
        case 45;            return .Minus;          // '-'
        case 47;            return .Slash;          // '/'
        case 39;            return .Apostrophe;     // "'"
        case 91;            return .LeftBracket;    // '['
        case 92;            return .Backslash;      // '\'
        case 93;            return .RightBracket;   // ']'
        case 96;            return .GraveAccent;    // '`'

        case SCROLL_LOCK;   return .ScrollLock;
        case PRINT_SCREEN;  return .PrintScreen;
        case PAUSE;         return .Pause;

        // Digits
        case 48; return .ImGuiKey_0;
        case 49; return .ImGuiKey_1;
        case 50; return .ImGuiKey_2;
        case 51; return .ImGuiKey_3;
        case 52; return .ImGuiKey_4;
        case 53; return .ImGuiKey_5;
        case 54; return .ImGuiKey_6;
        case 55; return .ImGuiKey_7;
        case 56; return .ImGuiKey_8;
        case 57; return .ImGuiKey_9;

        // Letters (A-Z)
        case 65; return .A;
        case 66; return .B;
        case 67; return .C;
        case 68; return .D;
        case 69; return .E;
        case 70; return .F;
        case 71; return .G;
        case 72; return .H;
        case 73; return .I;
        case 74; return .J;
        case 75; return .K;
        case 76; return .L;
        case 77; return .M;
        case 78; return .N;
        case 79; return .O;
        case 80; return .P;
        case 81; return .Q;
        case 82; return .R;
        case 83; return .S;
        case 84; return .T;
        case 85; return .U;
        case 86; return .V;
        case 87; return .W;
        case 88; return .X;
        case 89; return .Y;
        case 90; return .Z;

        // Func keys
        case F1;  return .F1;
        case F2;  return .F2;
        case F3;  return .F3;
        case F4;  return .F4;
        case F5;  return .F5;
        case F6;  return .F6;
        case F7;  return .F7;
        case F8;  return .F8;
        case F9;  return .F9;
        case F10; return .F10;
        case F11; return .F11;
        case F12; return .F12;
        case F13; return .F13;
        case F14; return .F14;
        case F15; return .F15;
        case F16; return .F16;
        case F17; return .F17;
        case F18; return .F18;
        case F19; return .F19;
        case F20; return .F20;
        case F21; return .F21;
        case F22; return .F22;
        case F23; return .F23;
        case F24; return .F24;

        // Modifiers
        case CTRL;  return .LeftCtrl;
        case SHIFT; return .LeftShift;
        case ALT;   return .LeftAlt;
        case CMD;   return .LeftSuper;

        // Application-specific
        case 0; return .None;
    }
    return .None;
}

Impl_GetClipboardText :: (data: *void) -> *u8 #c_call {
    new_context: #Context; // TODO: hide the context in the userdata pointer passed to us
    push_context new_context {
        return to_c_string(Clipboard.os_clipboard_get_text());
    }
}

Impl_SetClipboardText :: (data: *void, text: *u8) #c_call {
    new_context: #Context;
    push_context new_context {
        Clipboard.os_clipboard_set_text(to_string(text));
    }
}

Impl_CreateFontsTexture :: () -> bool {
    using ui_state;
    io := GetIO();
    assert(io != null);
    assert(io.Fonts != null);

    if io.Fonts.TexID != 0
        return false;

    // Build texture atlas
    pixels: *u8 = null;
    width, height: s32;
    assert(io.Fonts != null);
    io.Fonts.GetTexDataAsAlpha8(io.Fonts, *pixels, *width, *height);
    assert(pixels != null);
    assert(width > 0);
    assert(height > 0);
    //io.Fonts.GetTexDataAsRGBA32(io.Fonts, *pixels, *width, *height);

    // Upload texture to graphics system
    last_texture: GLuint;
    glGetIntegerv(GL_TEXTURE_BINDING_2D, xx *last_texture);

    glGenTextures(1, *FontTexture);
    glBindTexture(GL_TEXTURE_2D, FontTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    //glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED, xx width, xx height, 0, GL_RED, GL_UNSIGNED_BYTE, pixels);
    //glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, xx width, xx height, 0, GL_RGBA, GL_UNSIGNED_BYTE, pixels);

    // Store our identifier
    io.Fonts.TexID = xx FontTexture;

    // Restore state
    glBindTexture(GL_TEXTURE_2D, last_texture);

    return true;
}

#scope_file

#import "GL" (DUMP_GL_ERRORS = true);