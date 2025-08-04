Circle_Vertex :: struct {
    position       : Vector4;
    local_position : Vector4;
    tint           : Vector4;
    thickness      : f32;
    fade           : f32;
    entity         : s32;
}

draw_circle :: (pos := ZERO_2D, rad := (0.50).(f32), thickness := (0.05).(f32), fade := (0.01).(f32), tint := WHITE, id := (0).(u32)) {
    draw_primitive2d(.CIRCLE, .ORTHO_WORLD, .ALPHA);

    vertex_positions : Vector4Verts2D = ---;
    scale_mat := scale(IDENTITY, .{ rad * 2.0, rad * 2.0, 1.0 });
    
    vertex_positions[0] = scale_mat * DEF_VERTEX_POSITIONS_2D[0];
    vertex_positions[1] = scale_mat * DEF_VERTEX_POSITIONS_2D[1];
    vertex_positions[2] = scale_mat * DEF_VERTEX_POSITIONS_2D[2];
    vertex_positions[3] = scale_mat * DEF_VERTEX_POSITIONS_2D[3];

    final_thickness := thickness / (rad * 2);

    vertex_colors: Vector4Verts2D = ---;
    for *vertex_colors it.* = tint;

    for *vertex_positions it.* = translate(IDENTITY, .{pos.x, pos.y, 0}) * it.*;
    
    default_vertex_positions := DEF_VERTEX_POSITIONS_2D;
    
    using state := context.renderer2d;

    for i : 0..VERTICES_PER_2D_PRIMITIVE - 1 {

        vert := *state.circle_batch[i + state.circle_count * VERTICES_PER_2D_PRIMITIVE];
        
        vert.local_position = default_vertex_positions[i];
        vert.position       = vertex_positions[i];
        vert.tint           = vertex_colors[i];
        vert.thickness      = final_thickness;
        vert.fade           = fade;
        vert.entity         = xx id;
    }    
    
    state.circle_index_count += INDICES_PER_2D_PRIMITIVE;
    state.circle_count += 1;
}