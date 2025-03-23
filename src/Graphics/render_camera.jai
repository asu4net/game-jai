RenderCameraMode :: enum {
    NONE;
    ORTHO_WORLD;
    ORTHO_SCREEN;
}

RenderCamera :: struct {
    mode       : RenderCameraMode;
    viewport_w : s32      = DEF_SCREEN_WIDTH;
    viewport_h : s32      = DEF_SCREEN_HEIGHT;
    eye        : Vector3  = ZERO_3D;
    near       : float32  = -1;
    far        : float32  = +1;
    front      : Vector3  = FRONT_3D;
    right      : Vector3  = RIGHT_3D;
    up         : Vector3  = UP_3D;
    pv_matrix  : Matrix4  = Matrix4_Identity;

    //2D Specific
    size : float32 = +1;
}

update_render_camera :: (using camera : *RenderCamera) {

    update_ortho_world :: (using camera : *RenderCamera) {
        assert(camera != null);
        set_viewport(xx viewport_w, xx viewport_h);
        aspect := cast(float) viewport_w / cast(float) viewport_h;
        limit  := aspect * size;
        p := orthographic_projection_matrix(-limit, limit, -size, size, near, far);
        v := look_at(eye, front, right, up);
        pv_matrix = p * v;
    }
    
    update_ortho_screen :: (using camera : *RenderCamera) {
        assert(camera != null);
        set_viewport(xx viewport_w, xx viewport_h);
        pv_matrix = orthographic_projection_matrix(0, cast(float) viewport_w*1, cast(float) viewport_h, 0, -1.0, 1.0);
    }

    if mode == {
        case .ORTHO_WORLD;  update_ortho_world(camera);
        case .ORTHO_SCREEN; update_ortho_screen(camera);
        case .NONE; assert(false);
    }
}