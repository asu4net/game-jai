VERTICES_PER_2D_PRIMITIVE   :: 4;
INDICES_PER_2D_PRIMITIVE    :: 6;
MAX_2D_PRIMITIVES_PER_BATCH :: 3000;
MAX_TEXTURE_SLOTS           :: 32;

Default_Texture_Slots :: enum {
    WHITE;
    COUNT;
}

V4Verts2D :: [VERTICES_PER_2D_PRIMITIVE] Vector4;
V2Verts2D :: [VERTICES_PER_2D_PRIMITIVE] Vector2;

DEFAULT_VERTEX_POSITIONS_2D : V4Verts2D : .[
    .{-0.5, -0.5,  0.0,  1.0 }, // bottom-left
    .{ 0.5, -0.5,  0.0,  1.0 }, // bottom-right
    .{ 0.5,  0.5,  0.0,  1.0 }, // top-right
    .{-0.5,  0.5,  0.0,  1.0 }  // top-left
];

DEFAULT_VERTEX_POSITIONS_GUI : V4Verts2D : .[
    .{ 0.0, 1.0, 0.0, 1.0 }, // bottom-right
    .{ 1.0, 1.0, 0.0, 1.0 }, // bottom-left
    .{ 1.0, 0.0, 0.0, 1.0 }, // top-right
    .{ 0.0, 0.0, 0.0, 1.0 }  // top-left
];

DEFAULT_VERTEX_UVS_2D : V2Verts2D : .[
    .{ 0.0, 0.0 }, // bottom-left
    .{ 1.0, 0.0 }, // bottom-right
    .{ 1.0, 1.0 }, // top-right
    .{ 0.0, 1.0 }  // top-left
];

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

QuadFlag :: enum_flags u16 {
    AUTOSIZE;
    FLIP_X;
    FLIP_Y;
    USE_SUBTEX;
}

DEFAULT_QUAD_FLAGS :: QuadFlag.AUTOSIZE;

GUIQuadFlag :: enum_flags u16 {
    FLIP_X;
    FLIP_Y;
    USE_SUBTEX;
}

DEFAULT_GUI_QUAD_FLAGS :: 0;

Draw2D_Settings :: struct {
    viewport_width  : s32 = DEF_SCREEN_WIDTH;
    viewport_height : s32 = DEF_SCREEN_HEIGHT;
}

Draw2D_Context :: struct {
    white_texture        : Texture;
    texture_slots        : [MAX_TEXTURE_SLOTS] s32;
    textures_to_bind     : [MAX_TEXTURE_SLOTS]*Texture;
    last_texture_slot    : s32;
    camera               : RenderCamera;
    curr_blending        : Blending;
    curr_primitive       : Primitive_Type;
    initialized          : bool;
    started_batch        : bool;
    gui_width            : float;
    gui_height           : float; 
    
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
    
    state.gui_width  = DEF_SCREEN_WIDTH;
    state.gui_height = DEF_SCREEN_HEIGHT;

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

draw_2d_begin :: (using settings := Draw2D_Settings.{}) {
    Draw2DStateHeader();
    state.camera.viewport_w = viewport_width;
    state.camera.viewport_h = viewport_height;
    //start_batch(); this is being handled by the primitive header for now
}

draw_2d_end :: () {
    flush();
}

draw_quad :: (
    pos       : Vector2  = ZERO_2D,
    ang       : float32  = 0,
    sca       : Vector2  = ONE_2D,
    texture   : *Texture = null,
    tiling    : Vector2  = ONE_2D,
    size      : Vector2  = ONE_2D,
    blending  : Blending = .ALPHA,
    rect      : Rect     = .{},
    tint      : Vector4  = WHITE,
    entity_id : u32      = 0,
    flags     : QuadFlag = DEFAULT_QUAD_FLAGS
)
{
    Draw2DPrimitiveHeader(.QUAD, .ORTHO_WORLD, blending);

    vertex_positions := DEFAULT_VERTEX_POSITIONS_2D;
    vertex_uvs       := DEFAULT_VERTEX_UVS_2D;

    vertex_colors    : V4Verts2D = ---;
    for *vertex_colors it.* = tint;
    
    if texture != null {
        
        pixel_width  := texture.width;
        pixel_height := texture.height;

        if .USE_SUBTEX & flags {
            
            pixel_width  = xx rect.width;
            pixel_height = xx rect.height;
            sub_tex_uv(*vertex_uvs, texture, rect);
        }

        for *vertex_uvs multiply(it.*, tiling);
        flip_quad_vertex_uv(*vertex_uvs, xx .FLIP_X & flags, xx .FLIP_Y & flags);

        if .AUTOSIZE & flags {
            
            pixel_size := Vector2.{xx pixel_width, xx pixel_height};
            final_size := multiply(pixel_size, size);

            pos := normalize(final_size) / 2.0;

            vertex_positions[0] = .{ -pos.x, -pos.y, 0.0, 1.0 };
            vertex_positions[1] = .{  pos.x, -pos.y, 0.0, 1.0 };
            vertex_positions[2] = .{  pos.x,  pos.y, 0.0, 1.0 };
            vertex_positions[3] = .{ -pos.x,  pos.y, 0.0, 1.0 };
        }
    }
    
    for *vertex_positions it.* = make_transform(pos, ang, sca) * it.*;
    
    slot := assign_texture_slot(texture);

    for i : 0..VERTICES_PER_2D_PRIMITIVE - 1 {
        state.quad_batch[i + state.quad_count * VERTICES_PER_2D_PRIMITIVE] = .{
            vertex_positions[i], vertex_colors[i], vertex_uvs[i], slot, xx entity_id
        };
    }    
    
    state.quad_index_count += INDICES_PER_2D_PRIMITIVE;
    state.quad_count += 1;
}

draw_text :: (
    pos           : Vector2  = ZERO_2D,
    ang           : float32  = 0,
    sca           : Vector2  = ONE_2D,
    text          : string   = "placeholder!",
    font          : *Font    = null,
    size          : float    = 0.1,
    blending      : Blending = .ALPHA,
    tint          : Vector4  = WHITE,
    entity_id     : u32      = 0
)
{
    assert(font != null);
    Draw2DPrimitiveHeader(.QUAD, .ORTHO_WORLD, blending);

    text_size : float = size / cast(float) font.pixel_height;

    x_pos, y_pos : float;

    for c : text {

        vertex_positions : V4Verts2D = ---;
        vertex_uvs       : V2Verts2D = ---;
        vertex_colors    : V4Verts2D = ---;
        for *vertex_colors it.* = tint;

        glyph : Glyph;
        d := *glyph.quad;
        fill_glyph(font, *glyph, c);

        vertex_positions[0] = .{d.x0 * text_size + x_pos , d.y1 * -text_size + y_pos, 0, 1};
        vertex_positions[1] = .{d.x1 * text_size + x_pos , d.y1 * -text_size + y_pos, 0, 1};
        vertex_positions[2] = .{d.x1 * text_size + x_pos , d.y0 * -text_size + y_pos, 0, 1};
        vertex_positions[3] = .{d.x0 * text_size + x_pos , d.y0 * -text_size + y_pos, 0, 1};

        vertex_uvs[0] = .{ d.s0, d.t1 };
        vertex_uvs[1] = .{ d.s1, d.t1 };
        vertex_uvs[2] = .{ d.s1, d.t0 };
        vertex_uvs[3] = .{ d.s0, d.t0 };
        
        x_pos += text_size * glyph.x_pos;
        y_pos += text_size * glyph.y_pos;

        for *vertex_positions it.* = make_transform(pos, ang, sca) * it.*;

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

draw_gui_quad :: (
    pos       : Vector2     = ZERO_2D,
    ang       : float32     = 0,
    sca       : Vector2     = ONE_2D,
    texture   : *Texture    = null,
    tiling    : Vector2     = ONE_2D,
    size      : Vector2     = ONE_2D,
    blending  : Blending    = .ALPHA,
    rect      : Rect        = .{},
    tint      : Vector4     = WHITE,
    entity_id : u32         = 0,
    flags     : GUIQuadFlag = DEFAULT_GUI_QUAD_FLAGS
)
{
    Draw2DPrimitiveHeader(.QUAD, .ORTHO_SCREEN, blending);

    vertex_positions : V4Verts2D = ---;
    vertex_colors    : V4Verts2D = ---;
    
    vertex_uvs       := DEFAULT_VERTEX_UVS_2D;
    for *vertex_colors it.* = tint;

    coef_x := state.camera.viewport_w / state.gui_width;
    coef_y := state.camera.viewport_h / state.gui_height;
    coef := min(coef_x, coef_y);
    
    GUI_QUAD_PIXEL_WIDTH  :: 200;
    GUI_QUAD_PIXEL_HEIGHT :: 200;

    pixel_size := Vector2.{ GUI_QUAD_PIXEL_WIDTH, GUI_QUAD_PIXEL_HEIGHT };

    if texture != null {
        
        if .USE_SUBTEX & flags then {
            pixel_size = Vector2.{ xx rect.width, xx rect.height };
            sub_tex_uv(*vertex_uvs, texture, rect);
        }
        else pixel_size = Vector2.{ xx texture.width, xx texture.height };

        for *vertex_uvs multiply(it.*, tiling);
        flip_quad_vertex_uv(*vertex_uvs, xx .FLIP_X & flags, xx .FLIP_Y & flags);
    }
    
    p := multiply(pixel_size * coef, size);
    
    vertex_positions[0] = .{ 0.0, p.y, 0.0, 1.0 };
    vertex_positions[1] = .{ p.x, p.y, 0.0, 1.0 };
    vertex_positions[2] = .{ p.x, 0.0, 0.0, 1.0 };
    vertex_positions[3] = .{ 0.0, 0.0, 0.0, 1.0 };
    
    transform := make_transform(pos * coef, ang, sca);
    for *vertex_positions it.* = transform * it.*;
    
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
    Draw2DPrimitiveHeader(.CIRCLE, .ORTHO_WORLD, .ALPHA);

    vertex_positions : V4Verts2D = ---;
    scale_mat := scale(Matrix4_Identity, .{ radius * 2.0, radius * 2.0, 1.0 });
    vertex_positions[0] = scale_mat * DEFAULT_VERTEX_POSITIONS_2D[0];
    vertex_positions[1] = scale_mat * DEFAULT_VERTEX_POSITIONS_2D[1];
    vertex_positions[2] = scale_mat * DEFAULT_VERTEX_POSITIONS_2D[2];
    vertex_positions[3] = scale_mat * DEFAULT_VERTEX_POSITIONS_2D[3];

    final_thickness := thickness / (radius * 2);

    vertex_colors    : V4Verts2D = ---;
    for *vertex_colors it.* = tint;

    for *vertex_positions it.* = transform * it.*;
    
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

#scope_file

draw_2d : *Draw2D_Context;

Draw2DStateHeader :: () #expand {
    assert(is_draw_2d_initialized());
    `state := draw_2d;
}

Draw2DPrimitiveHeader :: (_primitive_type : Primitive_Type, _camera_mode : RenderCameraMode, _blending_mode : Blending) #expand {
    assert(is_draw_2d_initialized());
    
    `state := draw_2d;
    
    if !state.started_batch {
        start_batch();
    }

    if state.curr_blending  != .NONE && state.curr_blending  != _blending_mode  ||
       state.curr_primitive != .NONE && state.curr_primitive != _primitive_type ||
       state.camera.mode    != .NONE && state.camera.mode    != _camera_mode {
        next_batch();
    }
    
    state.curr_blending  = _blending_mode;
    state.curr_primitive = _primitive_type;
    state.camera.mode    = _camera_mode;

    if _primitive_type == {
        case .QUAD;     assert(state.quad_count   <= MAX_2D_PRIMITIVES_PER_BATCH);
        case .CIRCLE;   assert(state.circle_count <= MAX_2D_PRIMITIVES_PER_BATCH);
    }
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
    state.last_texture_slot  = xx Default_Texture_Slots.COUNT;
    state.curr_blending      = .NONE;
    state.curr_primitive     = .NONE;
    state.camera.mode        = .NONE;
    state.quad_count         = 0;
    state.quad_index_count   = 0;
    state.circle_count       = 0;
    state.circle_index_count = 0;
    state.started_batch      = true;
}

flush :: () {
    Draw2DStateHeader();
    
    if !state.started_batch then {
        return;
    }

    update_render_camera(*state.camera);
    set_blending_mode(state.curr_blending);
    assert(state.started_batch);

    if state.curr_primitive == {
        
        case .QUAD; {         
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
            bind(*state.circle_shader);
            set_constant_matrix4(*state.circle_shader, "u_ProjectionView", state.camera.pv_matrix);
            set_vertex_buffer_data(*state.circle_vbo, *state.circle_batch[0], xx (size_of(Circle_Vertex) * VERTICES_PER_2D_PRIMITIVE * state.circle_count));
            draw_elements(*state.circle_vao, state.circle_index_count);
        }

        case; assert(false);
    }

    state.started_batch  = false;
}

next_batch :: () {
    flush();
    start_batch();
}

flip_quad_vertex_uv :: (vertex_uvs : *V2Verts2D, flip_x : bool, flip_y : bool) {

    DoCopy :: () #expand {
        `uv := array_copy(vertex_uvs.*, ,,temp);
    }

    if flip_x && flip_y {
        DoCopy();
        vertex_uvs.*[0] = uv[3];
        vertex_uvs.*[1] = uv[2];
        vertex_uvs.*[2] = uv[1];
        vertex_uvs.*[3] = uv[0];
        return;
    }
    if flip_x {
        DoCopy();
        vertex_uvs.*[0] = uv[1];
        vertex_uvs.*[1] = uv[0];
        vertex_uvs.*[2] = uv[3];
        vertex_uvs.*[3] = uv[2];
        return;
    }
    if flip_y {
        DoCopy();
        vertex_uvs.*[0] = uv[2];
        vertex_uvs.*[1] = uv[3];
        vertex_uvs.*[2] = uv[0];
        vertex_uvs.*[3] = uv[1];
        return;
    }
}

sub_tex_uv :: (vertex_uvs : *V2Verts2D, texture : *Texture, rect : Rect) {
    assert(texture && vertex_uvs);
    
    item_px_pos  := Vector2.{ xx rect.x, xx rect.y };
    texture_size := Vector2.{ xx texture.width, xx texture.height };
    item_size    := Vector2.{ xx rect.width, xx rect.height };

    top_right, bottom_left : Vector2;
    top_right.x = (item_px_pos.x + item_size.x) * (1 / texture_size.x);
    top_right.y = (item_px_pos.y + item_size.y) * (1 / texture_size.y);
    
    bottom_left.x = item_px_pos.x * (1 / texture_size.x);
    bottom_left.y = (item_px_pos.y * (1 / texture_size.y));
    
    vertex_uvs.*[0] = .{ bottom_left.x, bottom_left.y }; // bottom-left
    vertex_uvs.*[1] = .{ top_right.x,   bottom_left.y }; // bottom-right
    vertex_uvs.*[2] = .{ top_right.x,   top_right.y };   // top-right
    vertex_uvs.*[3] = .{ bottom_left.x, top_right.y };   // top-left
}