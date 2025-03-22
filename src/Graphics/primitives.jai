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
    .{-0.5, -0.5, 0.0, 1.0 }, // bottom-left
    .{ 0.5, -0.5, 0.0, 1.0 }, // bottom-right
    .{ 0.5,  0.5, 0.0, 1.0 }, // top-right
    .{-0.5,  0.5, 0.0, 1.0 }  // top-left
];

DEFAULT_VERTEX_UVS_2D : V2Verts2D : .[
    .{ 0.0, 0.0 }, // bottom-left
    .{ 1.0, 0.0 }, // bottom-right
    .{ 1.0, 1.0 }, // top-right
    .{ 0.0, 1.0 }  // top-left
];

DEFAULT_VERTEX_COLORS_2D : V4Verts2D : .[
    .{ 1.0, 1.0, 1.0, 1.0 }, // bottom-left
    .{ 1.0, 1.0, 1.0, 1.0 }, // bottom-right
    .{ 1.0, 1.0, 1.0, 1.0 }, // top-right
    .{ 1.0, 1.0, 1.0, 1.0 }  // top-left
];

transform_vertex_positions :: (vertex_positions : *V4Verts2D, transform : Matrix4) {
    vertex_positions.*[0] = transform * vertex_positions.*[0];
    vertex_positions.*[1] = transform * vertex_positions.*[1];
    vertex_positions.*[2] = transform * vertex_positions.*[2];
    vertex_positions.*[3] = transform * vertex_positions.*[3];    
}

fill_quad_vertex_positions :: (vertex_positions : *V4Verts2D, size : Vector2) {
    
    pos := normalize(size) / 2.0;
    vertex_positions.*[0] = .{ -pos.x, -pos.y, 0.0, 1.0 };
    vertex_positions.*[1] = .{  pos.x, -pos.y, 0.0, 1.0 };
    vertex_positions.*[2] = .{  pos.x,  pos.y, 0.0, 1.0 };
    vertex_positions.*[3] = .{ -pos.x,  pos.y, 0.0, 1.0 };
}

fill_circle_vertex_positions :: (vertex_positions : *V4Verts2D, radius : float32) {
    
    scale_mat := scale(Matrix4_Identity, .{ radius * 2.0, radius * 2.0, 1.0 });
    vertex_positions.*[0] = scale_mat * DEFAULT_VERTEX_POSITIONS_2D[0];
    vertex_positions.*[1] = scale_mat * DEFAULT_VERTEX_POSITIONS_2D[1];
    vertex_positions.*[2] = scale_mat * DEFAULT_VERTEX_POSITIONS_2D[2];
    vertex_positions.*[3] = scale_mat * DEFAULT_VERTEX_POSITIONS_2D[3];
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

fill_quad_vertex_uvs :: (vertex_uvs : *V2Verts2D, flip_x : bool, flip_y : bool, tiling_factor : Vector2) {
    flip_quad_vertex_uv(vertex_uvs, flip_x, flip_y);
    for i : 1..VERTICES_PER_2D_PRIMITIVE - 1 {
        vertex_uvs.*[i].x *= tiling_factor.x;
        vertex_uvs.*[i].y *= tiling_factor.y;
    }
}

fill_vertex_colors :: (vertex_colors : *V4Verts2D, color : Vector4) {
    vertex_colors.*[0] = color;
    vertex_colors.*[1] = color;
    vertex_colors.*[2] = color;
    vertex_colors.*[3] = color;
}

fill_quad_sub_tex_vertex_uvs :: (
    vertex_uvs    : *V2Verts2D, 
    texture_size  : Vector2,
    item_size     : Vector2,
    item_px_pos   : Vector2,
    flip_x        : bool, 
    flip_y        : bool, 
    tiling_factor : Vector2
) {
    top_right, bottom_left : Vector2;
    
    top_right.x = (item_px_pos.x + item_size.x) * (1 / texture_size.x);
    top_right.y = (item_px_pos.y + item_size.y) * (1 / texture_size.y);

    bottom_left.x = item_px_pos.x * (1 / texture_size.x);
    bottom_left.y = (item_px_pos.y * (1 / texture_size.y));

    vertex_uvs.*[0] = .{ bottom_left.x, bottom_left.y }; // bottom-left
    vertex_uvs.*[1] = .{ top_right.x,   bottom_left.y }; // bottom-right
    vertex_uvs.*[2] = .{ top_right.x,   top_right.y };   // top-right
    vertex_uvs.*[3] = .{ bottom_left.x, top_right.y };   // top-left

    fill_quad_vertex_uvs(vertex_uvs, flip_x, flip_y, tiling_factor);
}
