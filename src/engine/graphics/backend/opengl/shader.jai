Default_Shader :: enum {
    QUAD;
    CIRCLE;
}

Shader :: struct {
    program : u32;
}

is_shader_init :: (shader : *Shader) -> bool {
    assert(shader != null);
    return shader.program != 0;
}

init_shader :: (shader : *Shader, def : Default_Shader) {
    if def == {
        case .QUAD;   init_shader(shader, QUAD_SHADER_SOURCE);
        case .CIRCLE; init_shader(shader, CIRCLE_SHADER_SOURCE);
    }
}

init_shader :: (shader : *Shader, source : string) {
    assert(!is_shader_init(shader));
    shader.program = get_shader_program(source);
    if shader.program == 0 then return;
    //#REVIEW_asuarez: Maybe do something is shader is valid
}

deinit_shader :: (shader : *Shader) {
    assert(is_shader_init(shader));
    glDeleteProgram(shader.program);
    shader.* = .{};
}

bind :: (shader : *Shader) {
    assert(is_shader_init(shader));
    glUseProgram(shader.program);
}

get_constant_location :: (shader : *Shader, name : string) -> s32 {
    return glGetUniformLocation(shader.program, name.data);
}

set_constant_matrix4 :: (using shader : *Shader, name : string, value : Matrix4) {
    location := get_constant_location(shader, name);
    glUniformMatrix4fv(location, 1, true, *value.floats[0]);
}

set_constant_sampler2d :: (using shader : *Shader, name : string, value : [] s32, count : s32) {
    location := get_constant_location(shader, name);
    glUniform1iv(location, xx count, value.data);
}

set_constant_int :: (using shader : *Shader, name : string, value : s32) {
    location := get_constant_location(shader, name);
    glUniform1i(location, value);
}

QUAD_SHADER_SOURCE :: #string SCOPE
    #ifdef VERTEX_SHADER        
    layout(location = 0) in vec4 a_Position;
    layout(location = 1) in vec4 a_Tint;
    layout(location = 2) in vec2 a_UV;
    layout(location = 3) in int  a_Texture;
    layout(location = 4) in int  a_EntityID;

    uniform mat4 u_ProjectionView;        
            
    out vec4     v_Tint;
    out vec2     v_UV;
    flat out int v_Texture;
    flat out int v_EntityID;

    void main()
    {
        gl_Position   = u_ProjectionView * vec4(a_Position.xy, 0.0, 1.0);
        v_Tint        = a_Tint;
        v_UV          = a_UV;
        v_Texture     = a_Texture;
        v_EntityID    = a_EntityID;
    }
    #endif //VERTEX_SHADER

    #ifdef FRAGMENT_SHADER            
    layout(location = 0) out vec4 o_Color;
    layout(location = 1) out int  o_EntityID;
    
    uniform sampler2D u_Textures[32];
    
    in vec4      v_Tint;
    in vec2      v_UV;
    flat in int  v_Texture;
    flat in int  v_EntityID;

    void main()
    {
        o_Color = texture(u_Textures[v_Texture], v_UV) * v_Tint;
        o_EntityID = v_EntityID;
    }
    #endif //FRAGMENT_SHADER
SCOPE

CIRCLE_SHADER_SOURCE :: #string SCOPE
    #ifdef VERTEX_SHADER      
    layout(location = 0) in vec4  a_Position;
    layout(location = 1) in vec4  a_LocalPosition;
    layout(location = 2) in vec4  a_Tint;
    layout(location = 3) in float a_Thickness;
    layout(location = 4) in float a_Fade;
    layout(location = 5) in int   a_EntityID;
    
    uniform mat4 u_ProjectionView;
    
    // Vertex output
    out vec4     v_LocalPosition;
    out vec4     v_Tint;
    out float    v_Thickness;
    out float    v_Fade;
    flat out int v_EntityID;
    
    void main()
    {
        gl_Position     = u_ProjectionView * a_Position;
        v_LocalPosition = a_LocalPosition;
        v_Tint          = a_Tint;
        v_Thickness     = a_Thickness;
        v_Fade          = a_Fade;
        v_EntityID      = a_EntityID;
    }
    #endif //VERTEX_SHADER

    #ifdef FRAGMENT_SHADER
    layout(location = 0) out vec4 o_Color;
    layout(location = 1) out int  o_EntityID;

    // Vertex input
    in vec4     v_LocalPosition;
    in vec4     v_Tint;
    in float    v_Thickness;
    in float    v_Fade;
    flat in int v_EntityID;

    void main()
    {
        vec2 localPos = vec2(v_LocalPosition.x * 2, v_LocalPosition.y * 2);
        float d = 1.0 - length(localPos);
        float alpha = smoothstep(0.0, v_Fade, d);
        alpha *= smoothstep(v_Thickness + v_Fade, v_Thickness, d);
        o_Color = vec4(v_Tint.rgb, alpha);
        o_EntityID = v_EntityID;    
    }
    #endif //FRAGMENT_SHADER
SCOPE

get_shader_program :: (shader_text: string) -> GLuint {
    LOG_BUFFER_SIZE :: 512;

    make_shader_object :: (shader: string, prefix: string, shader_type : GLenum) -> GLuint {
        shader_object := glCreateShader(shader_type);

        //shader_str := temp_c_string(shader);
        shaders: [2] *u8;
        lengths: [2] s32;

        shaders[0] = prefix.data;
        shaders[1] = shader.data;
        lengths[0] = xx prefix.count;
        lengths[1] = xx shader.count;

        glShaderSource(shader_object, 2, shaders.data, lengths.data);

        glCompileShader(shader_object);

        success : GLint;
        glGetShaderiv(shader_object, GL_COMPILE_STATUS, *success);

        if !success then {
            log_data: [LOG_BUFFER_SIZE] u8;
            glGetShaderInfoLog(shader_object, log_data.count, null, log_data.data);
            log("%", to_string(log_data.data), flags=.ERROR);
            return 0;
        }

        return shader_object;
    }

    PREFIX_V :: #string SCOPE
    #version 420 core
    #define VERTEX_SHADER
    SCOPE
    
    PREFIX_F :: #string SCOPE
    #version 420 core
    #define FRAGMENT_SHADER
    SCOPE

    vertex_shader   := make_shader_object(shader_text, PREFIX_V, GL_VERTEX_SHADER);
    fragment_shader := make_shader_object(shader_text, PREFIX_F, GL_FRAGMENT_SHADER);
    shader_program  := glCreateProgram();

    glAttachShader(shader_program, vertex_shader)  ;
    glAttachShader(shader_program, fragment_shader);
    glLinkProgram(shader_program);

    success : GLint = 0;
    glGetProgramiv(shader_program, GL_LINK_STATUS, *success);

    if !success then {
        log_data: [LOG_BUFFER_SIZE] u8;
        glGetProgramInfoLog(shader_program, log_data.count, null, log_data.data);
        log_error("%", to_string(log_data.data));
        return 0;
    }

    glDeleteShader(vertex_shader)  ;
    glDeleteShader(fragment_shader);
    
    return shader_program;
}