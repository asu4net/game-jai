RAD_PER_DEG :: TAU/360.0;
DEG_PER_RAD :: 360.0/TAU;

f64 :: float64;
f32 :: float32;
v2  :: Vector2;
v3  :: Vector3;
v4  :: Vector4;
m4  :: Matrix4; 

IDENTITY :: Matrix4_Identity;

ZERO_2D   :: v2.{ +0, +0 };
ONE_2D    :: v2.{ +1, +1 };
UP_2D     :: v2.{ +0, +1 };
DOWN_2D   :: v2.{ +0, -1 };
RIGHT_2D  :: v2.{ +1, +0 };
LEFT_2D   :: v2.{ -1, +0 };

ZERO_3D   :: v3.{ +0, +0, +0 };
ONE_3D    :: v3.{ +1, +1, +1 };
UP_3D     :: v3.{ +0, +1, +0 };
DOWN_3D   :: v3.{ +0, -1, +0 };
RIGHT_3D  :: v3.{ +1, +0, +0 };
LEFT_3D   :: v3.{ -1, +0, +0 };
FRONT_3D  :: v3.{ +0, +0, +1 };
BACK_3D   :: v3.{ +0, +0, -1 };

ZERO_4D   :: v4.{ +0, +0, +0, +0 };
ONE_4D    :: v4.{ +1, +1, +1, +1 };

WHITE        :: v4.{ 1, 1, 1, 1 };
WHITE_FADED  :: v4.{ 1, 1, 1, 0 };
BLACK        :: v4.{ 0, 0, 0, 1 };
BLUE         :: v4.{ 0, 0, 1, 1 };
LIGHT_BLUE   :: v4.{ 0.3, 0.3, 1, 1 };
CYAN         :: v4.{ 0, 1, 1, 1 };
GRAY         :: v4.{ 0.5, 0.5, 0.5, 1 };
DARK_GRAY    :: v4.{ 0.2, 0.2, 0.2, 1 };
GREEN        :: v4.{ 0, 1, 0, 1 };
LIGHT_GREEN  :: v4.{ 0.3, 1, 0.3, 1 };
GREY         :: v4.{ 0.5, 0.5, 0.5, 1 };
DARK_GREY    :: v4.{ 0.2, 0.2, 0.2, 1 };
MAGENTA      :: v4.{ 1, 0, 1, 1 };
RED          :: v4.{ 1, 0, 0, 1 };
LIGHT_RED    :: v4.{ 1, 0.3, 0.3, 1 };
YELLOW       :: v4.{ 1, 0.92, 0.016, 1 };
ORANGE       :: v4.{ 0.97, 0.6, 0.11, 1 };

map :: (value : f32, min1 : f32, max1 : f32, min2 : f32, max2 : f32) -> f32 {
    return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

multiply :: (a : v2, b : v2) -> v2 {
    r : v2;
    r.x = a.x * b.x;
    r.y = a.y * b.y;
    return r;
}

rotate_x :: (mat: m4, angle_x: f32) -> m4 {
    c := cos(angle_x);
    s := sin(angle_x);
    op := IDENTITY;
    op.coef[1][1] =  c;
    op.coef[1][2] = -s;
    op.coef[2][1] =  s;
    op.coef[2][2] =  c;
    return op * mat;
}

rotate_y :: (mat: m4, angle_y: f32) -> m4 {
    c := cos(angle_y);
    s := sin(angle_y);
    op := IDENTITY;
    op.coef[0][0] =  c;
    op.coef[0][2] =  s;
    op.coef[2][0] = -s;
    op.coef[2][2] =  c;
    return op * mat;
}

rotate_z :: (mat: m4, angle_z: f32) -> m4 {
    c := cos(angle_z);
    s := sin(angle_z);
    op := IDENTITY;
    op.coef[0][0] =  c;
    op.coef[0][1] = -s;
    op.coef[1][0] =  s;
    op.coef[1][1] =  c;
    return op * mat;
}

rotate :: (mat: m4, rotation : v3) -> m4 {
    return rotate_z(rotate_y(rotate_x(mat, rotation.x), rotation.y), rotation.z);
}

rotate_around :: (pivot : v2, angle : f32, point : v2) -> v2 {
    
    s := sin(angle * RAD_PER_DEG);
    c := cos(angle * RAD_PER_DEG);

    // translate point back to origin:
    new_point := point;
    new_point.x -= pivot.x;
    new_point.y -= pivot.y;
    
    // rotate point
    x_new := new_point.x * c - new_point.y * s;
    y_new := new_point.x * s + new_point.y * c;

    // translate point back:
    new_point.x = x_new + pivot.x;
    new_point.y = y_new + pivot.y;
    return new_point;
}

make_transform :: (pos : v3, rot := ZERO_3D, sc := ONE_3D) -> m4 {
    scale_matrix       := scale(IDENTITY, sc);
    rotation_matrix    := rotate(IDENTITY, RAD_PER_DEG * rot);
    translation_matrix := translate(IDENTITY, pos);
    return translation_matrix * rotation_matrix * scale_matrix;
}

make_transform :: (pos : v2, rot : f32 = 0, sc := ONE_2D) -> m4 {
    scale_matrix       := scale(IDENTITY, .{sc.x, sc.y, 0 });
    rotation_matrix    := rotate_z(IDENTITY, RAD_PER_DEG * rot);
    translation_matrix := translate(IDENTITY, .{pos.x, pos.y, 0 });
    return translation_matrix * rotation_matrix * scale_matrix;
}

look_at :: (eye: v3, f: v3, r: v3, u: v3, flip_z_axis := true) -> (m: m4) {
	
    f, s, u := f, r, u;
	f = normalize(f);
	s = normalize(s);
	u = normalize(u);
	fe := dot(f, eye);
	
    return .{
		+s.x, +s.y, +s.z, -dot(s, eye),
		+u.x, +u.y, +u.z, -dot(u, eye),
		-f.x, -f.y, -f.z, ifx flip_z_axis then +fe else -fe,
		   0,    0,    0, 1,
	};
}

ease_in_expo_interp :: (x: f32, min: f32, max: f32) -> f32 {
    factor := ifx x == 0 then 0 else pow(2, 10 * x - 10);
    return min + (max - min) * factor;
}

linear_interp :: (x: f32, min: f32, max: f32) -> f32 {
    return min + (max - min) * x;
}

linear_interp :: (x : f32, min: v4, max: v4) -> (v : v4) {
    v : v4;
    v.x = linear_interp(x, min.x, max.x);
    v.y = linear_interp(x, min.y, max.y);
    v.z = linear_interp(x, min.z, max.z);
    v.w = linear_interp(x, min.w, max.w);
    return v;
}