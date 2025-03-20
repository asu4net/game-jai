Rect :: struct {
    x: float32; 
    y: float32; 
    width: int; 
    height: int;
}

Quad_Vertex :: struct {
    position : Vector4;
    tint     : Vector4;
    uv       : Vector2;
    texture  : s32;
    entity   : s32;
}

Circle_Vertex :: struct {
    position       : Vector4;
    local_position : Vector4;
    tint           : Vector4;
    thickness      : float32;
    fade           : float32;
    entity         : s32;
}

Primitive_Type :: enum {
    NONE;
    QUAD;
    CIRCLE;
}

Draw2D_Context :: struct {
    white_texture        : Texture;
    texture_slots        : [MAX_TEXTURE_SLOTS] s32;
    textures_to_bind     : [MAX_TEXTURE_SLOTS]*Texture;
    last_texture_slot    : s32;
    camera               : RenderCamera;
    curr_blending        : Blending_Mode;
    curr_primitive       : Primitive_Type;
    initialized          : bool;
    started_batch        : bool;

    // Quad
    quad_ibo             : Index_Buffer;
    quad_vao             : Vertex_Array;
    quad_vbo             : Vertex_Buffer;
    quad_batch           : [] Quad_Vertex;
    quad_count           : u32;
    quad_index_count     : u32;
    quad_shader          : Shader;
    
    // Circle
    circle_vao         : Vertex_Array;
    circle_vbo         : Vertex_Buffer;
    circle_batch       : [] Circle_Vertex;
    circle_count       : u32;
    circle_index_count : u32;
    circle_shader      : Shader;
}

is_draw_2d_initialized :: () -> bool {
    assert(draw_2d != null);
    return draw_2d.initialized;
}

init_draw_2d :: (instance : *Draw2D_Context) {
    assert(draw_2d == null);
    assert(instance != null);
    draw_2d = instance;
    state := draw_2d;
    
    set_blending_mode(.ALPHA);
    init_white_texture(*state.white_texture);
    //texture_2d_init(*atlas_texture, "assets/atlas.png")

    state.textures_to_bind[Default_Texture_Slots.WHITE] = *state.white_texture;
    //textures_to_bind[Default_Texture_Slots.ATLAS] = *atlas_texture
    state.last_texture_slot = xx Default_Texture_Slots.COUNT;

    for i : 0..MAX_TEXTURE_SLOTS - 1 {
        state.texture_slots[i] = xx i;
    }

    init_shader(*state.quad_shader, .QUAD);
    init_shader(*state.circle_shader, .CIRCLE);

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

        init_index_buffer(*state.quad_ibo, indices.data, INDEX_COUNT);
        
        VERTICES :: MAX_2D_PRIMITIVES_PER_BATCH * VERTICES_PER_2D_PRIMITIVE;

        // Quad
        {
            state.quad_batch = NewArray(VERTICES, Quad_Vertex);
            init_vertex_array(*state.quad_vao);
            init_vertex_buffer(*state.quad_vbo, VERTICES * size_of(Quad_Vertex));
            add_layout(*state.quad_vbo, type = .Float4, name = "a_Position");
            add_layout(*state.quad_vbo, type = .Float4, name = "a_Tint");
            add_layout(*state.quad_vbo, type = .Float2, name = "a_UV");
            add_layout(*state.quad_vbo, type = .Int,    name = "a_Texture");
            add_layout(*state.quad_vbo, type = .Int,    name = "a_EntityID");
            add_vertex_buffer(*state.quad_vao, *state.quad_vbo);
            add_index_buffer(*state.quad_vao, *state.quad_ibo);
        }

        // Circle
        {
            state.circle_batch = NewArray(VERTICES, Circle_Vertex);
            init_vertex_array(*state.circle_vao);
            init_vertex_buffer(*state.circle_vbo, VERTICES * size_of(Circle_Vertex));
            add_layout(*state.circle_vbo, type = .Float4, name = "a_Position");
            add_layout(*state.circle_vbo, type = .Float4, name = "a_LocalPosition");
            add_layout(*state.circle_vbo, type = .Float4, name = "a_Tint");
            add_layout(*state.circle_vbo, type = .Float,  name = "a_Thickness");
            add_layout(*state.circle_vbo, type = .Float,  name = "a_Fade");
            add_layout(*state.circle_vbo, type = .Int,    name = "a_EntityID");
            add_vertex_buffer(*state.circle_vao, *state.circle_vbo);
            add_index_buffer(*state.circle_vao, *state.quad_ibo);
        }
    }

    state.initialized = true;
}

fini_draw_2d :: () {
    Draw2DStateHeader();

    fini_texture(*state.white_texture);
    //texture_2d_finish(*atlas_texture)

    array_free(state.quad_batch);
    fini_vertex_buffer(*state.quad_vbo);
    fini_shader(*state.quad_shader);
    
    array_free(state.circle_batch);
    fini_vertex_buffer(*state.circle_vbo);
    fini_shader(*state.circle_shader);
    
    state.* = .{};
}

get_2d_camera :: () -> *RenderCamera {
    Draw2DStateHeader();
    return *state.camera;
}

update_2d_camera :: (viewport_width : s32, viewport_height : s32) {
    Draw2DStateHeader();
    state.camera.viewport_w = viewport_width;
    state.camera.viewport_h = viewport_height;
    update_render_camera(*state.camera);
}

QuadFlag :: enum {
    AUTOSIZE;
    FLIP_X;
    FLIP_Y;
    USE_SUBTEX;
}

DEFAULT_QUAD_FLAGS :: QuadFlag.AUTOSIZE;

draw_text :: (
    transform     : Matrix4       = Matrix4_Identity,
    text          : string        = "placeholder!",
    font          : *Font         = null,
    size          : float         = 0.1,
    blending      : Blending_Mode = .ALPHA,
    tint          : Vector4       = .{ 1, 1, 1, 1},
    entity_id     : u32           = 0
)
{
    assert(font != null);
    Draw2DPrimitiveHeader(.QUAD, blending);

    text_scale : float = size / cast(float) font.pixel_height;

    x_pos, y_pos : float;

    for c : text {

        vertex_positions : V4Verts2D = ---;
        vertex_uvs       : V2Verts2D = ---;
        vertex_colors    : V4Verts2D = ---;
        fill_vertex_colors(*vertex_colors, tint);

        glyph : Glyph;
        d := *glyph.quad;
        fill_glyph(font, *glyph, c);

        vertex_positions[0] = .{d.x0 * text_scale + x_pos , d.y1 * -text_scale + y_pos, 0, 1};
        vertex_positions[1] = .{d.x1 * text_scale + x_pos , d.y1 * -text_scale + y_pos, 0, 1};
        vertex_positions[2] = .{d.x1 * text_scale + x_pos , d.y0 * -text_scale + y_pos, 0, 1};
        vertex_positions[3] = .{d.x0 * text_scale + x_pos , d.y0 * -text_scale + y_pos, 0, 1};

        vertex_uvs[0] = .{ d.s0, d.t1 };
        vertex_uvs[1] = .{ d.s1, d.t1 };
        vertex_uvs[2] = .{ d.s1, d.t0 };
        vertex_uvs[3] = .{ d.s0, d.t0 };
        
        x_pos += text_scale * glyph.x_pos;
        y_pos += text_scale * glyph.y_pos;

        transform_vertex_positions(*vertex_positions, transform);

        slot := assign_texture_slot(*font.atlas);

        for i : 0..VERTICES_PER_2D_PRIMITIVE - 1 {
            state.quad_batch[i + state.quad_count * VERTICES_PER_2D_PRIMITIVE] = .{
                vertex_positions[i], vertex_colors[i], vertex_uvs[i], slot, xx entity_id
            };
        }

        state.quad_index_count += INDICES_PER_2D_PRIMITIVE;
        state.quad_count += 1;
    }
}

draw_quad :: (
    transform     : Matrix4       = Matrix4_Identity,
    texture       : *Texture      = null,
    tiling        : Vector2       = .{ 1, 1 },
    blending      : Blending_Mode = .ALPHA,
    sub_tex_rect  : Rect          = .{},
    tint          : Vector4       = .{ 1, 1, 1, 1},
    entity_id     : u32           = 0,
    flags         : QuadFlag      = DEFAULT_QUAD_FLAGS
)
{
    Draw2DPrimitiveHeader(.QUAD, blending);

    vertex_positions := DEFAULT_VERTEX_POSITIONS_2D;
    vertex_uvs       := DEFAULT_VERTEX_UVS_2D;

    vertex_colors    : V4Verts2D = ---;
    fill_vertex_colors(*vertex_colors, tint);

    if texture != null {

        pixel_width, pixel_height : int;

        if .USE_SUBTEX & flags {
            
            pixel_width  = sub_tex_rect.width;
            pixel_height = sub_tex_rect.height;

            fill_quad_sub_tex_vertex_uvs(
                *vertex_uvs,
                .{ xx texture.width, xx texture.height},
                .{ xx sub_tex_rect.width, xx sub_tex_rect.height},
                .{ xx sub_tex_rect.x, xx sub_tex_rect.y},
                .FLIP_X & flags == 1,
                .FLIP_Y & flags == 1,
                tiling
            );
        } else {

            pixel_width  = texture.width;
            pixel_height = texture.height;

            fill_quad_vertex_uvs(*vertex_uvs, .FLIP_X & flags == 1, .FLIP_Y & flags == 1, tiling);
        }

        if .AUTOSIZE & flags {
            fill_quad_vertex_positions(*vertex_positions, .{ xx pixel_width, xx pixel_height });
        }
    }
    
    transform_vertex_positions(*vertex_positions, transform);
    
    slot := assign_texture_slot(texture);

    for i : 0..VERTICES_PER_2D_PRIMITIVE - 1 {
        state.quad_batch[i + state.quad_count * VERTICES_PER_2D_PRIMITIVE] = .{
            vertex_positions[i], vertex_colors[i], vertex_uvs[i], slot, xx entity_id
        };
    }    
    
    state.quad_index_count += INDICES_PER_2D_PRIMITIVE;
    state.quad_count += 1;
}

draw_circle :: (
    transform : Matrix4  = Matrix4_Identity,
    radius    : float32  = 0.5,
    thickness : float32  = 0.05,
    fade      : float32  = 0.01,
    tint      : Vector4  = .{ 1, 1, 1, 1 }, 
    entity_id : u32      = 0
)
{
    Draw2DPrimitiveHeader(.CIRCLE, .ALPHA);

    vertex_positions : V4Verts2D = ---;
    fill_circle_vertex_positions(*vertex_positions, radius);
    final_thickness := thickness / (radius * 2);

    vertex_colors    : V4Verts2D = ---;
    fill_vertex_colors(*vertex_colors, tint);

    transform_vertex_positions(*vertex_positions, transform);
    
    default_vertex_positions := DEFAULT_VERTEX_POSITIONS_2D;
    
    for i : 0..VERTICES_PER_2D_PRIMITIVE - 1 {

        vert := *state.circle_batch[i + state.circle_count * VERTICES_PER_2D_PRIMITIVE];
        
        vert.local_position = default_vertex_positions[i];
        vert.position       = vertex_positions[i];
        vert.tint           = vertex_colors[i];
        vert.thickness      = final_thickness;
        vert.fade           = fade;
        vert.entity         = xx entity_id;
    }    
    
    state.circle_index_count += INDICES_PER_2D_PRIMITIVE;
    state.circle_count += 1;
}

submit_drawings :: () {
    flush();
}

#scope_file

draw_2d : *Draw2D_Context;

Draw2DStateHeader :: () #expand {
    assert(is_draw_2d_initialized());
    `state := draw_2d;
}

Draw2DPrimitiveHeader :: (_primitive_type : Primitive_Type, _blending_mode : Blending_Mode = .ALPHA) #expand {
    assert(is_draw_2d_initialized());
    `state := draw_2d;
    if !state.started_batch {
        next_batch();
    }
    if state.curr_blending != _blending_mode {
        next_batch();
        set_blending_mode(_blending_mode);
        state.curr_blending = _blending_mode;
    }
    if state.curr_primitive != .NONE && state.curr_primitive != _primitive_type {
        next_batch();
    }
    if _primitive_type == {
        case .QUAD;   assert(state.quad_count <= MAX_2D_PRIMITIVES_PER_BATCH);
        case .CIRCLE; assert(state.circle_count <= MAX_2D_PRIMITIVES_PER_BATCH);
    }
    state.curr_primitive = _primitive_type;
}

assign_texture_slot :: (texture : *Texture) -> (texture_slot : s32) {
    Draw2DStateHeader();

    texture_slot : s32 = xx Default_Texture_Slots.WHITE;
    if texture == null {
        return texture_slot;
    }

    for i : 0..state.last_texture_slot - 1{
        if state.textures_to_bind[i].id == texture.id {
            texture_slot = i;
            break;
        }
    }
    if texture_slot == 0 {
        if state.last_texture_slot > MAX_TEXTURE_SLOTS {
            next_batch();
        }
        state.textures_to_bind[state.last_texture_slot] = texture;
        texture_slot = state.last_texture_slot;
        state.last_texture_slot += 1;
    }
    return texture_slot;
}

start_batch :: () {
    Draw2DStateHeader();

    state.last_texture_slot = xx Default_Texture_Slots.COUNT;
    
    state.quad_count = 0;
    state.quad_index_count = 0;
    
    state.circle_count = 0;
    state.circle_index_count = 0;

    state.started_batch = true;
}

flush :: () {
    Draw2DStateHeader();
    if state.curr_primitive == {
        
        case .NONE; return;
       
        case .QUAD; {
            assert(state.started_batch);
            for i : 0..state.last_texture_slot - 1 {
                bind(state.textures_to_bind[i], xx i);
            }
            bind(*state.quad_shader);
            set_constant_sampler2d(*state.quad_shader, "u_Textures[0]", state.texture_slots, MAX_TEXTURE_SLOTS);
            set_constant_matrix4(*state.quad_shader, "u_ProjectionView", state.camera.pv_matrix);
            set_vertex_buffer_data(*state.quad_vbo, *state.quad_batch[0], xx (size_of(Quad_Vertex) * VERTICES_PER_2D_PRIMITIVE * state.quad_count));
            draw_elements(*state.quad_vao, state.quad_index_count);
        }
        case .CIRCLE; {
            assert(state.started_batch);
            bind(*state.circle_shader);
            set_constant_matrix4(*state.circle_shader, "u_ProjectionView", state.camera.pv_matrix);
            set_vertex_buffer_data(*state.circle_vbo, *state.circle_batch[0], xx (size_of(Circle_Vertex) * VERTICES_PER_2D_PRIMITIVE * state.circle_count));
            draw_elements(*state.circle_vao, state.circle_index_count);
        }
    }

    state.curr_primitive = .NONE;
    state.started_batch = false;
}

next_batch :: () {
    state := draw_2d;
    if state.started_batch {
        flush();
    }
    start_batch();
}