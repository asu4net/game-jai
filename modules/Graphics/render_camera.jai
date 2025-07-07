RenderCameraMode :: enum {
    NONE;
    ORTHO_WORLD;
    ORTHO_SCREEN;
}

RenderCamera :: struct {
    mode       : RenderCameraMode;
    viewport_w : s32  = DEF_SCREEN_WIDTH;
    viewport_h : s32  = DEF_SCREEN_HEIGHT;
    eye        : v3   = ZERO_3D;
    near       : f32  = -1;
    far        : f32  = +1;
    front      : v3   = FRONT_3D;
    right      : v3   = RIGHT_3D;
    up         : v3   = UP_3D;
    pv_matrix  : m4   = IDENTITY;

    //2D Specific
    size : f32 = +1.5;
}

update_render_camera :: (using camera : *RenderCamera) {

    update_ortho_world :: (using camera : *RenderCamera) {
        assert(camera != null);
        set_viewport(xx viewport_w, xx viewport_h);
        aspect := cast(f32) viewport_w / cast(f32) viewport_h;
        limit  := aspect * size;
        p := orthographic_projection_matrix(-limit, limit, -size, size, near, far);
        v := look_at(eye, front, right, up);
        pv_matrix = p * v;
    }
    
    update_ortho_screen :: (using camera : *RenderCamera) {
        assert(camera != null);
        set_viewport(xx viewport_w, xx viewport_h);
        pv_matrix = orthographic_projection_matrix(0, cast(f32) viewport_w*1, cast(f32) viewport_h, 0, -1.0, 1.0);
    }

    if mode == {
        case .ORTHO_WORLD;  update_ortho_world(camera);
        case .ORTHO_SCREEN; update_ortho_screen(camera);
        case .NONE; assert(false);
    }
}