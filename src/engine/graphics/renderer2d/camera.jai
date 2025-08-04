CameraMode :: enum {
    NONE;
    ORTHO_WORLD;
    ORTHO_SCREEN;
}

Camera :: struct {
    mode       := CameraMode.ORTHO_SCREEN;
    viewport_w := DEF_SCREEN_WIDTH;
    viewport_h := DEF_SCREEN_HEIGHT;
    eye        := ZERO_3D;
    near       := (-1).(f32);
    far        := (+1).(f32);
    front      := FRONT_3D;
    right      := RIGHT_3D;
    up         := UP_3D;
    pv_matrix  := IDENTITY;
    
    //2D Specific
    size := (+1.5).(f32);
}

update_render_camera :: (using camera : *Camera) {

    update_ortho_world :: (using camera : *Camera) {
        assert(camera != null);
        set_viewport(xx viewport_w, xx viewport_h);
        aspect := cast(f32) viewport_w / cast(f32) viewport_h;
        limit  := aspect * size;
        p := orthographic_projection_matrix(-limit, limit, -size, size, near, far);
        v := look_at(eye, front, right, up);
        pv_matrix = p * v;
    }
    
    update_ortho_screen :: (using camera : *Camera) {
        assert(camera != null);
        set_viewport(xx viewport_w, xx viewport_h);
        pv_matrix = orthographic_projection_matrix(0, cast(f32) viewport_w*1, cast(f32) viewport_h, 0, -1.0, 1.0);
    }

    if mode == {
        case .ORTHO_WORLD;  update_ortho_world(camera);
        case .ORTHO_SCREEN; update_ortho_screen(camera);
        case .NONE; // Don't do anything.
    }
}