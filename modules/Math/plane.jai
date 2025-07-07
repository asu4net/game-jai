// Plane

Plane3 :: struct {
    a, b, c, d : float;

    #place a;
    #as vector4: Vector4;
    
    #place a;
    normal: Vector3;
}


make_plane :: (a: float, b:float, c:float, d:float) -> Plane3 {
    p: Plane3 = ---;  // @Cleanup: This is kinda dumb, but the union makes it hard... use #place?
    p.a = a;
    p.b = b;
    p.c = c;
    p.d = d;
    return p;
}

make_plane :: (v: Vector3, d: float) -> Plane3 {
    p: Plane3 = ---;
    p.a = v.x;
    p.b = v.y;
    p.c = v.z;
    p.d = d;
    return p;
}


make_plane :: (v: Vector3, x: Vector3) -> Plane3 {  // @Cleanup: Remove this.
    p: Plane3 = ---;
    p.a = v.x;
    p.b = v.y;
    p.c = v.z;
    p.d = -dot(v, x);
    return p;
}

plane_from_point_and_normal :: (point: Vector3, normal: Vector3) -> Plane3 {
    p: Plane3 = ---;
    p.a = normal.x;
    p.b = normal.y;
    p.c = normal.z;
    p.d = -dot(point, normal);
    
    return p;
}

make_plane :: (v: Vector4) -> Plane3 {
    p: Plane3 = ---;
    p.a = v.x;
    p.b = v.y;
    p.c = v.z;
    p.d = v.w;
    return p;
}

get_normal :: (p: Plane3) -> Vector3 {
    result := Vector3.{p.a, p.b, p.c};
    normalize(*result, fallback=.{z=1}); // Arbitrary fallback normal...
    return result;
}


// Ensure that (a, b, c) is of unit length, and scales all the plane's coefficients accordingly.
normalize :: (using p: Plane3) -> Plane3 {
    len := length(normal);

    if len == 0 {
        return .{c=1};
    } else {
        result := p;
        ilen := 1 / len;
        result.a *= ilen;
        result.b *= ilen;
        result.c *= ilen;
        result.d *= ilen;
        return result;
    }
}


normalized_plane_from_points :: (p0: Vector3, p1: Vector3, p2: Vector3) -> Plane3 {
    cross := unit_vector(cross_product(p2 - p1, p0 - p1));

    result: Plane3 = ---;  // @Cleanup: If the union on plane3 is made to work, this gets simpler.
    result.a = cross.x;
    result.b = cross.y;
    result.c = cross.z;
    result.d = -dot_product(cross, p0);

    return result;
}


plane_dot :: (plane: Plane3, v: Vector3) -> float #symmetric {
    return plane.a * v.x + plane.b * v.y + plane.c * v.z + plane.d;
}


operator- :: (p: Plane3) -> Plane3 {
    r: Plane3 = ---;
    r.a = -p.a;
    r.b = -p.b;
    r.c = -p.c;
    r.d = -p.d;
    return r;
}

