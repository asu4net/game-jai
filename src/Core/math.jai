RAD_PER_DEG :: TAU/360.0;
DEG_PER_RAD :: 360.0/TAU;

map :: (value : float, min1 : float, max1 : float, min2 : float, max2 : float) -> float {
    return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

multiply :: (a : Vector2, b : Vector2) -> Vector2 {
    r : Vector2;
    r.x = a.x * b.x;
    r.y = a.y * b.y;
    return r;
}

rotate_x :: (mat: Matrix4, angle_x: float32) -> Matrix4 {
    c := cos(angle_x);
    s := sin(angle_x);
    op := Matrix4_Identity;
    op.coef[1][1] =  c;
    op.coef[1][2] = -s;
    op.coef[2][1] =  s;
    op.coef[2][2] =  c;
    return op * mat;
}

rotate_y :: (mat: Matrix4, angle_y: float32) -> Matrix4 {
    c := cos(angle_y);
    s := sin(angle_y);
    op := Matrix4_Identity;
    op.coef[0][0] =  c;
    op.coef[0][2] =  s;
    op.coef[2][0] = -s;
    op.coef[2][2] =  c;
    return op * mat;
}

rotate_z :: (mat: Matrix4, angle_z: float32) -> Matrix4 {
    c := cos(angle_z);
    s := sin(angle_z);
    op := Matrix4_Identity;
    op.coef[0][0] =  c;
    op.coef[0][1] = -s;
    op.coef[1][0] =  s;
    op.coef[1][1] =  c;
    return op * mat;
}

rotate :: (mat: Matrix4, rotation : Vector3) -> Matrix4 {
    return rotate_z(rotate_y(rotate_x(mat, rotation.x), rotation.y), rotation.z);
}

make_transform :: (pos : Vector3, rot := ZERO_3D, sc := ONE_3D) -> Matrix4 {
    scale_matrix := scale(Matrix4_Identity, sc);
    rotation_matrix :=  ifx rot != ZERO_3D then rotate(scale_matrix, RAD_PER_DEG * rot) else scale_matrix;
    translation_matrix := translate(rotation_matrix, pos);
    return translation_matrix;
}

make_transform :: (pos : Vector2, ang: float = 0, sca := ONE_2D) -> Matrix4 {
    p := Vector3.{ pos.x, pos.y, 0 };
    r := FRONT_3D * ang;
    s := Vector3.{ sca.x, sca.y, 0 };
    return make_transform(p, r, s);
}

look_at :: (eye: Vector3, f: Vector3, r: Vector3, u: Vector3, flip_z_axis := true) -> (m: Matrix4) {
	
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

ease_in_expo_interp :: (x: float32, min: float32, max: float32) -> float32 {
    factor := ifx x == 0 then 0 else pow(2, 10 * x - 10);
    return min + (max - min) * factor;
}

linear_interp :: (x: float32, min: float32, max: float32) -> float32 {
    return min + (max - min) * x;
}

linear_interp :: (x : float32, min: Vector4, max: Vector4) -> (v : Vector4) {
    v.r = linear_interp(x, min.r, max.r);
    v.g = linear_interp(x, min.g, max.g);
    v.b = linear_interp(x, min.b, max.b);
    v.a = linear_interp(x, min.a, max.a);
    return v;
}