//#NOTE_asuarez Esto viene a ser parte del batch de quads.

draw_gui_text :: (pos := ZERO_2D, ang := (0).(f32), scl := ONE_2D, text := "", font: *Font = null, blend := Blend.ALPHA, tint := WHITE, id := (0).(u32)) {
    assert(font != null);
    draw_primitive2d(.QUAD, .ORTHO_SCREEN, blend);
    using state := context.renderer2d;

    x_pos, y_pos : f32;
    
    for c : text {

        vertex_positions : Vector4Verts2D = ---;
        vertex_uvs       : Vector2Verts2D = ---;
        vertex_colors    : Vector4Verts2D = ---;
        for *vertex_colors it.* = tint;

        glyph : Glyph;
        d := *glyph.quad;
        fill_glyph(font, *glyph, c);
        
        coef_x := state.camera.viewport_w / state.gui_width;
        coef_y := state.camera.viewport_h / state.gui_height;
        coef := (min(coef_x, coef_y)).(f32);

        vertex_positions[0] = .{d.x0 * coef + x_pos, d.y1 * coef + y_pos, 0, 1};
        vertex_positions[1] = .{d.x1 * coef + x_pos, d.y1 * coef + y_pos, 0, 1};
        vertex_positions[2] = .{d.x1 * coef + x_pos, d.y0 * coef + y_pos, 0, 1};
        vertex_positions[3] = .{d.x0 * coef + x_pos, d.y0 * coef + y_pos, 0, 1};

        x_pos += coef * glyph.x_pos;
        y_pos += coef * glyph.y_pos;

        for *vertex_positions it.* = make_matrix(coef * pos, ang, scl) * it.*;

        vertex_uvs[0] = .{ d.s0, d.t1 };
        vertex_uvs[1] = .{ d.s1, d.t1 };
        vertex_uvs[2] = .{ d.s1, d.t0 };
        vertex_uvs[3] = .{ d.s0, d.t0 };
        
        slot := assign_tex_slot(*font.atlas);

        for i : 0..VERTICES_PER_2D_PRIMITIVE - 1 {
            state.quad_batch[i + state.quad_count * VERTICES_PER_2D_PRIMITIVE] = .{
                vertex_positions[i], vertex_colors[i], vertex_uvs[i], slot, xx id
            };
        }

        state.quad_index_count += INDICES_PER_2D_PRIMITIVE;
        state.quad_count += 1;
    }
}