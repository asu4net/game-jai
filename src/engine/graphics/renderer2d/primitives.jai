Primitive_Type :: enum {
    NONE;
    QUAD;
    CIRCLE;
}

Vector4Verts2D :: [VERTICES_PER_2D_PRIMITIVE] Vector4;
Vector2Verts2D :: [VERTICES_PER_2D_PRIMITIVE] Vector2;

DEF_VERTEX_POSITIONS_2D :Vector4Verts2D: .[
    .{-0.5, -0.5,  0.0,  1.0 }, // bottom-left
    .{ 0.5, -0.5,  0.0,  1.0 }, // bottom-right
    .{ 0.5,  0.5,  0.0,  1.0 }, // top-right
    .{-0.5,  0.5,  0.0,  1.0 }  // top-left
];

DEF_VERTEX_UVS_2D :Vector2Verts2D: .[
    .{ 0.0, 0.0 }, // bottom-left
    .{ 1.0, 0.0 }, // bottom-right
    .{ 1.0, 1.0 }, // top-right
    .{ 0.0, 1.0 }  // top-left
];

#load "primitives/circle.jai";
#load "primitives/quad.jai";
#load "primitives/text.jai";