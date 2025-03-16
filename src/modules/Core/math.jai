matrix4_look_at_from_fru :: (eye: Vector3, f: Vector3, r: Vector3, u: Vector3, flip_z_axis := true) -> (m: Matrix4) {
	
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