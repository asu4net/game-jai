Default_Texture_Slots :: enum {
    WHITE;
    COUNT;
}

Renderer2D :: struct {
    white_texture    : Texture;
    atlas_texture    : Texture;
    tex_slots        : [MAX_TEXTURE_SLOTS] s32;
    textures_to_bind : [MAX_TEXTURE_SLOTS]*Texture;
    last_tex_slot    : s32;
    camera           : Camera;
    curr_blend       : Blend;
    curr_primitive   : Primitive_Type;
    gui_width        : int = 1920;
    gui_height       : int = 1080;
    
    // Quad
    quad_ibo         : Index_Buffer;
    quad_vao         : Vertex_Array;
    quad_vbo         : Vertex_Buffer;
    quad_batch       : [] Quad_Vertex;
    quad_count       : u32;
    quad_index_count : u32;
    quad_shader      : Shader;
    
    // Circle
    circle_vao         : Vertex_Array;
    circle_vbo         : Vertex_Buffer;
    circle_batch       : [] Circle_Vertex;
    circle_count       : u32;
    circle_index_count : u32;
    circle_shader      : Shader;
}

#add_context renderer2d : *Renderer2D;

init_renderer2d :: () {
    if context.renderer2d then deinit_renderer2d();
    context.renderer2d = New(Renderer2D);
    using state := context.renderer2d;

    set_blend_mode(.ALPHA);

    init_white_texture(*white_texture);

    textures_to_bind[Default_Texture_Slots.WHITE] = *white_texture;
    last_tex_slot = xx Default_Texture_Slots.COUNT;

    if ATLAS_FILE_LOCATION.count > 0 {
        init_texture(*atlas_texture, ATLAS_FILE_LOCATION, .NEAREST, .NEAREST);
    }

    for i : 0..MAX_TEXTURE_SLOTS - 1 {
        tex_slots[i] = xx i;
    }

    init_shader(*quad_shader, .QUAD);
    init_shader(*circle_shader, .CIRCLE);

    {
        INDEX_COUNT :: MAX_2D_PRIMITIVES_PER_BATCH * INDICES_PER_2D_PRIMITIVE;
        
        indices := NewArray(INDEX_COUNT, u32);
        defer array_free(indices);
        
        offset : u32 = 0;
        i := 0;
        while i < INDEX_COUNT {

            indices[i + 0] = offset + 0;
            indices[i + 1] = offset + 1;
            indices[i + 2] = offset + 2;

            indices[i + 3] = offset + 2;
            indices[i + 4] = offset + 3;
            indices[i + 5] = offset + 0;

            offset += VERTICES_PER_2D_PRIMITIVE;
            i += INDICES_PER_2D_PRIMITIVE;
        }

        init_index_buffer(*quad_ibo, indices.data, INDEX_COUNT);
        
        VERTICES :: MAX_2D_PRIMITIVES_PER_BATCH * VERTICES_PER_2D_PRIMITIVE;

        // Quad
        {
            quad_batch = NewArray(VERTICES, Quad_Vertex);
            init_vertex_array(*quad_vao);
            init_vertex_buffer(*quad_vbo, VERTICES * size_of(Quad_Vertex));
            add_layout(*quad_vbo, type = .Float4, name = "a_Position");
            add_layout(*quad_vbo, type = .Float4, name = "a_Tint");
            add_layout(*quad_vbo, type = .Float2, name = "a_UV");
            add_layout(*quad_vbo, type = .Int,    name = "a_Texture");
            add_layout(*quad_vbo, type = .Int,    name = "a_EntityID");
            add_vertex_buffer(*quad_vao, *quad_vbo);
            add_index_buffer(*quad_vao, *quad_ibo);
        }

        // Circle
        {
            circle_batch = NewArray(VERTICES, Circle_Vertex);
            init_vertex_array(*circle_vao);
            init_vertex_buffer(*circle_vbo, VERTICES * size_of(Circle_Vertex));
            add_layout(*circle_vbo, type = .Float4, name = "a_Position");
            add_layout(*circle_vbo, type = .Float4, name = "a_LocalPosition");
            add_layout(*circle_vbo, type = .Float4, name = "a_Tint");
            add_layout(*circle_vbo, type = .Float,  name = "a_Thickness");
            add_layout(*circle_vbo, type = .Float,  name = "a_Fade");
            add_layout(*circle_vbo, type = .Int,    name = "a_EntityID");
            add_vertex_buffer(*circle_vao, *circle_vbo);
            add_index_buffer(*circle_vao, *quad_ibo);
        }
    }
}

deinit_renderer2d :: () {
    using state := context.renderer2d;
    if !state then return;

    context.renderer2d = null;
    
    deinit_texture(*white_texture);
    
    if ATLAS_FILE_LOCATION.count > 0 {
        deinit_texture(*atlas_texture);
    }

    array_free(quad_batch);
    deinit_vertex_buffer(*quad_vbo);
    deinit_shader(*quad_shader);
    
    array_free(circle_batch);
    deinit_vertex_buffer(*circle_vbo);
    deinit_shader(*circle_shader);

    free(state);
}

draw_primitive2d :: inline (primitive_type : Primitive_Type, camera_mode : CameraMode, blend_mode : Blend) {
    assert(context.renderer2d != null);
    
    using state := context.renderer2d;
    
    if curr_blend     != .NONE && curr_blend     != blend_mode     ||
       curr_primitive != .NONE && curr_primitive != primitive_type ||
       camera.mode    != .NONE && camera.mode    != camera_mode {
        flush_renderer2d();
    }
    
    curr_blend     = blend_mode;
    curr_primitive = primitive_type;
    camera.mode    = camera_mode;
    
    if primitive_type == {
        case .QUAD;     assert(quad_count   <= MAX_2D_PRIMITIVES_PER_BATCH);
        case .CIRCLE;   assert(circle_count <= MAX_2D_PRIMITIVES_PER_BATCH);
    }
}

flush_renderer2d :: () {
    using state := context.renderer2d;
    assert(state != null);

    // Submit data to gpu
    update_render_camera(*camera);
    if curr_blend != .NONE then set_blend_mode(curr_blend);
    
    bind_textures :: inline () {
        using state := context.renderer2d;
        for i: 0..last_tex_slot - 1 {
            bind(textures_to_bind[i], xx i);
        }
    }

    if curr_primitive == {
        
        case .QUAD; {         
            bind_textures();
            bind(*quad_shader);
            set_constant_sampler2d(*quad_shader, "u_Textures[0]", tex_slots, MAX_TEXTURE_SLOTS);
            set_constant_matrix4(*quad_shader, "u_ProjectionView", camera.pv_matrix);
            set_vertex_buffer_data(*quad_vbo, *quad_batch[0], xx (size_of(Quad_Vertex) * VERTICES_PER_2D_PRIMITIVE * quad_count));
            draw_elements(*quad_vao, quad_index_count);
        }
        case .CIRCLE; {
            bind(*circle_shader);
            set_constant_matrix4(*circle_shader, "u_ProjectionView", camera.pv_matrix);
            set_vertex_buffer_data(*circle_vbo, *circle_batch[0], xx (size_of(Circle_Vertex) * VERTICES_PER_2D_PRIMITIVE * circle_count));
            draw_elements(*circle_vao, circle_index_count);
        }
    }

    // Reset state
    last_tex_slot      = xx Default_Texture_Slots.COUNT;
    curr_blend         = .NONE;
    curr_primitive     = .NONE;
    camera.mode        = .NONE;
    quad_count         = 0;
    quad_index_count   = 0;
    circle_count       = 0;
    circle_index_count = 0;
}

assign_tex_slot :: (texture : *Texture) -> (tex_slot : s32) {

    using state := context.renderer2d;

    tex_slot: s32 = xx Default_Texture_Slots.WHITE;
    if texture == null {
        return tex_slot;
    }

    for i : 0..state.last_tex_slot - 1{
        if state.textures_to_bind[i].id == texture.id {
            tex_slot = i;
            break;
        }
    }
    if tex_slot == 0 {
        if state.last_tex_slot > MAX_TEXTURE_SLOTS {
            flush_renderer2d();
        }
        state.textures_to_bind[state.last_tex_slot] = texture;
        tex_slot = state.last_tex_slot;
        state.last_tex_slot += 1;
    }
    return tex_slot;
}