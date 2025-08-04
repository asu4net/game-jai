// Math



map :: (value : f32, min1 : f32, max1 : f32, min2 : f32, max2 : f32) -> f32 {
    return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

multiply :: (a : Vector2, b : Vector2) -> Vector2 {
    r : Vector2;
    r.x = a.x * b.x;
    r.y = a.y * b.y;
    return r;
}

rotate_x :: (mat: Matrix4, angle_x: f32) -> Matrix4 {
    c := cos(angle_x);
    s := sin(angle_x);
    op := IDENTITY;
    op.coef[1][1] =  c;
    op.coef[1][2] = -s;
    op.coef[2][1] =  s;
    op.coef[2][2] =  c;
    return op * mat;
}

rotate_y :: (mat: Matrix4, angle_y: f32) -> Matrix4 {
    c := cos(angle_y);
    s := sin(angle_y);
    op := IDENTITY;
    op.coef[0][0] =  c;
    op.coef[0][2] =  s;
    op.coef[2][0] = -s;
    op.coef[2][2] =  c;
    return op * mat;
}

rotate_z :: (mat: Matrix4, angle_z: f32) -> Matrix4 {
    c := cos(angle_z);
    s := sin(angle_z);
    op := IDENTITY;
    op.coef[0][0] =  c;
    op.coef[0][1] = -s;
    op.coef[1][0] =  s;
    op.coef[1][1] =  c;
    return op * mat;
}

rotate :: (mat: Matrix4, rotation : Vector3) -> Matrix4 {
    return rotate_z(rotate_y(rotate_x(mat, rotation.x), rotation.y), rotation.z);
}

rotate_around :: (pivot : Vector2, angle : f32, point : Vector2) -> Vector2 {
    
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

make_matrix :: (pos : Vector3, rot := ZERO_3D, sc := ONE_3D) -> Matrix4 {
    scale_matrix       := scale(IDENTITY, sc);
    rotation_matrix    := rotate(IDENTITY, RAD_PER_DEG * rot);
    translation_matrix := translate(IDENTITY, pos);
    return translation_matrix * rotation_matrix * scale_matrix;
}

make_matrix :: (pos : Vector2, rot : f32 = 0, sc := ONE_2D) -> Matrix4 {
    scale_matrix       := scale(IDENTITY, .{sc.x, sc.y, 0 });
    rotation_matrix    := rotate_z(IDENTITY, RAD_PER_DEG * rot);
    translation_matrix := translate(IDENTITY, .{pos.x, pos.y, 0 });
    return translation_matrix * rotation_matrix * scale_matrix;
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

ease_in_expo_interp :: (x: f32, min: f32, max: f32) -> f32 {
    factor := ifx x == 0 then 0 else pow(2, 10 * x - 10);
    return min + (max - min) * factor;
}

linear_interp :: (x: f32, min: f32, max: f32) -> f32 {
    return min + (max - min) * x;
}

linear_interp :: (x : f32, min: Vector4, max: Vector4) -> (v : Vector4) {
    v : Vector4;
    v.x = linear_interp(x, min.x, max.x);
    v.y = linear_interp(x, min.y, max.y);
    v.z = linear_interp(x, min.z, max.z);
    v.w = linear_interp(x, min.w, max.w);
    return v;
}