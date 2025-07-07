#load "cephes.jai";
#load "plane.jai";
#load "matrix.jai";
#load "print.jai";

// Scalar constants.

TAU   :: cast(float32) 6.283185;
TAU64 :: 6.28318530717958648;

PI    :: cast(float32) 3.1415927;
PI64  :: 3.141592653589793;

FLOAT16_MAX : float :   65504.0;

FLOAT32_MIN        :: 0h00800000;
FLOAT32_MAX        :: 0h7F7FFFFF;
FLOAT32_INFINITY   :: 0h7F800000;
FLOAT32_NAN        :: 0h7FBFFFFF;

FLOAT64_MIN        :: 0h00100000_00000000;
FLOAT64_MAX        :: 0h7FEFFFFF_FFFFFFFF;
FLOAT64_INFINITY   :: 0h7FF00000_00000000;
FLOAT64_NAN        :: 0h7FF7FFFF_FFFFFFFF;

S8_MIN  :s8:    -128;
S8_MAX  :s8:    127;
U8_MAX  :u8:    255;
S16_MIN :s16:   -32768;
S16_MAX :s16:   32767;
U16_MAX :u16:   0xffff;
S32_MIN :s32:   0x8000_0000;
S32_MAX :s32:   0x7fff_ffff;
U32_MAX :u32:   0xffff_ffff;
S64_MIN :s64:   0x8000_0000_0000_0000;
S64_MAX :s64:   0x7fff_ffff_ffff_ffff;
U64_MAX :u64:   0xffff_ffff_ffff_ffff;

Clamp :: inline (pointer: *$T, low: T, high: T) {
    if pointer.* < low    pointer.* = low;
    if pointer.* > high   pointer.* = high;
} @NoProfile

// ## Scalar functions

// ### Integer functions

abs :: inline (x: int) -> int {
    if x < 0 return -x;
    return x;
}

abs :: inline (x: s32) -> s32 {
    if x < 0 return -x;
    return x;
}

// ### Float functions

is_nan_is_inf :: (x: float64) -> (isnan: bool, isinf: bool) {
    uf := << cast(*u64)*x;

    unbiased_exponent := cast(s32) ((uf >> 52) & 0x7ff);  // @Feature: What we really mean here is "cast to whatever you think is a fast number, that is at least some size... [in this case it needs to be at least 11 bits!]

    if unbiased_exponent == 0x7ff {
        raw_mantissa := uf & 0xf_ffff_ffff_ffff;
        if raw_mantissa == 0 {
            return false, true;
        } else {
            return true, false;
        }
    }

    return false, false;
}

isnan :: (x: float64) -> bool {
    return is_nan_is_inf(x);
}

isinf :: (x: float64) -> bool {
    _, _isinf := is_nan_is_inf(x);
    return _isinf;
}

is_finite :: (x: float64) -> bool {
    uf := << cast(*u64)*x;
    unbiased_exponent := cast(s32) ((uf >> 52) & 0x7ff);  // @Speed: Could remove shift by doing big mask.
    return unbiased_exponent != 0x7ff;
}

is_nan_is_inf :: (x: float32) -> (isnan: bool, isinf: bool) {
    uf := << cast(*u32)*x;
    unbiased_exponent := (uf >> 23) & 0xff;
    if unbiased_exponent == 0xff {
        raw_mantissa := uf & 0x7f_ffff;
        if raw_mantissa == 0 {
            return false, true;
        } else {
            return true, false;
        }
    }

    return false, false;
}

isnan :: (x: float32) -> bool {
    return is_nan_is_inf(x);
}

isinf :: (x: float32) -> bool {
    _, _isinf := is_nan_is_inf(x);
    return _isinf;
}

is_finite :: (x: float) -> bool {
    uf := << cast(*u32)*x;
    unbiased_exponent := (uf >> 23) & 0xff;
    return unbiased_exponent != 0xff;
}

abs :: inline (x: float64) -> float64 {
    union {
        _float64: float64;
        _u64:     u64;
    }

    _float64 = x;
    _u64 &= 0x7fff_ffff_ffff_ffff;
    return _float64;
}

abs :: inline (x: float32) -> float32 {
    union {
        _float32: float32;
        _u32:     u32;
    }

    _float32 = x;
    _u32 &= 0x7fff_ffff;
    return _float32;
}

// 'frac' just returns x - floor(x). If you want it to have different
// behavior for negative numbers, write in and explain.
frac :: inline (x: $T) -> T
#modify {
    if (T == float32) || (T == float64) return true;
    return false;
} {
    return x - floor(x);
}

// We call this fmod_cycling to clarify that its behavior is different
// from that in base libc, which most people don't want. (But we want to
// avoid people introducing errors by using a familiar name that they think
// they know what it means, or by porting old C code). This fmod
// just generates a repeating pattern that cycles continuously, rather
// than being reflected for positive and negative inputs.
fmod_cycling :: inline (x: float64, y: float64) -> float64 {
    if y == 0 {
        Basic.log_error("Cannot fmod_cycling with denominator 0.\n");
        return FLOAT64_INFINITY;
    }

    // Not being that particular about if x is NaN or whatever...

    remainder := x - (floor(x/y) * y);

    return remainder;
}

fmod_cycling :: inline (x: float, divisor: float) -> float { return cast(float) fmod_cycling(cast(float64) x, cast(float64) divisor); }

// Float32 versions.
tan  :: inline (theta: float) -> float { return cast(float) tan (cast(float64) theta); }
acos :: inline (theta: float) -> float { return cast(float) acos(cast(float64) theta); }
asin :: inline (theta: float) -> float { return cast(float) asin(cast(float64) theta); }

sqrt :: inline (x: float) -> float { return cast(float) sqrt(cast(float64) x); }

pow  :: inline (x: float, power: float) -> float  { return cast(float) pow(cast(float64)x, cast(float64) power); }
exp  :: inline (x: float) -> float { return cast(float) exp(cast(float64) x); }
log  :: inline (x: float) -> float { return cast(float) log(cast(float64) x); }


// This 'saturate' stuff is not necessarily a good name for a general-purpose routine.
// That's a graphics-specific name. These things should probably be in some kind of
// GPU Math library, or, I don't know.
// Also, note that we have a non-functional Clamp already in this file...!
saturate :: (f: float)   -> float   {  return Basic.clamp(f, 0, 1);  }
saturate :: (f: float64) -> float64 {  return Basic.clamp(f, 0, 1);  }
square   :: (a : $T) -> T {  return a * a;  }

// See: https://fgiesen.wordpress.com/2012/03/28/half-to-float-done-quic/
// This seems like a specialist routine that probably should be elsewhere.
half_to_float :: (h: u16) -> float {
    magic      :: 0h77800000;  // This is ((254 - 15) << 23) as a float.
    was_infnan :: 0h47800000;  // This is ((127 + 16) << 23) as a float.

    union { u: u32; f: float; };

    u = (cast(u32)h & 0x7fff) << 13;  // exponent/mantissa bits
    f *= magic;                       // exponent adjust
    if f >= was_infnan                // make sure Inf/NaN survive
        u |= 255 << 23;
    u |= (cast(u32)h & 0x8000) << 16; // sign bit
    return f;
}

// Vectors

Vector2 :: struct {
    x, y: float;

#place x;
    component: [2] float = ---; @JsonIgnore
}

Vector3 :: struct {
    x, y, z: float;

#place x;
    xy: Vector2 = ---; @JsonIgnore
#place y;
    yz: Vector2 = ---; @JsonIgnore

#place x;
    component: [3] float = ---; @JsonIgnore
}

Vector4 :: struct {
    x, y, z, w: float;

#place x;
    xy: Vector2 = ---; @JsonIgnore
#place y;
    yz: Vector2 = ---; @JsonIgnore
#place z;
    zw: Vector2 = ---; @JsonIgnore
#place x;
    xyz: Vector3 = ---; @JsonIgnore
#place y;
    yzw: Vector3 = ---; @JsonIgnore
#place x;
    component: [4] float = ---; @JsonIgnore
}

Quaternion :: struct {
    x, y, z:  float;
    w      := 1.0;

#place x;
    component: [4] float = ---; @JsonIgnore

#place x;
    xyz: Vector3 = ---; @JsonIgnore
}


// We'll add Complex just so people have a common thing to refer to.
// (We don't use this in our games etc, but, maybe someone will!)
Complex :: #type,isa Vector2;

operator * :: (a: Complex, b: Complex) -> Complex {
    return .{a.x*b.x - a.y*b.y, a.x*b.y + a.y*b.x};
}


dot :: dot_product;

dot_product :: (a: Vector2, b: Vector2) -> float {
    return a.x*b.x + a.y*b.y;
}

dot_product :: (a: Vector3, b: Vector3) -> float {
    return a.x*b.x + a.y*b.y + a.z*b.z;
}

dot_product :: (a: Vector4, b: Vector4) -> float {
    return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w;
}

dot_product :: (a: Quaternion, b: Quaternion) -> float {
    return a.x*b.x + a.y*b.y + a.z*b.z + a.w*b.w;
}


// @Incomplete: Would like to be able to do this:
// dot   :: dot_product;
// cross :: cross_product;

length :: (a: Vector2) -> float {
    return sqrt(a.x*a.x + a.y*a.y);
}

length :: (a: Vector3) -> float {
    return sqrt(a.x*a.x + a.y*a.y + a.z*a.z);
}

length :: (a: Vector4) -> float {
    return sqrt(a.x*a.x + a.y*a.y + a.z*a.z + a.w*a.w);
}

length :: (a: Quaternion) -> float {
    return sqrt(a.x*a.x + a.y*a.y + a.z*a.z + a.w*a.w);
}

length_squared :: inline (a: Vector2) -> float {
    return a.x*a.x + a.y*a.y;
}

length_squared :: inline (a: Vector3) -> float {
    return a.x*a.x + a.y*a.y + a.z*a.z;
}

length_squared :: inline (a: Vector4) -> float {
    return a.x*a.x + a.y*a.y + a.z*a.z + a.w*a.w;
}

make_vector2 :: (x: float) -> Vector2 {
    return .{x, x};
}

make_vector3 :: (x: float) -> Vector3 {
    return .{x, x, x};
}

make_vector3 :: (c: [3] float) -> Vector3 {
    return .{c[0], c[1], c[2]};
}

make_vector3 :: (using v: Vector2, z: float) -> Vector3 {
    return .{x, y, z};
}

make_vector4 :: (x: float) -> Vector4 {
    return .{x, x, x, x};
}

make_vector4 :: (using v: Vector2, z: float, w: float) -> Vector4 {
    return .{x, y, z, w};
}

make_vector4 :: (using v: Vector3, w: float) -> Vector4 {
    return .{x, y, z, w};
}

xy :: (x: float, y: float) -> Vector2 {
    return .{x, y};
}

xy :: (x: float) -> Vector2 {
    return .{x, x};
}

xyz :: (x: float, y: float, z: float) -> Vector3 {
    return .{x, y, z};
}

xyz :: (x: float) -> Vector3 {
    return .{x, x, x};
}

xyz :: (c: [3] float) -> Vector3 {
    return .{c[0], c[1], c[2]};
}

xyz :: (using v: Vector2, z: float) -> Vector3 {
    return .{x, y, z};
}

xyzw :: (x: float, y: float, z: float, w: float) -> Vector4 {
    return .{x, y, z, w};
}

xyzw :: (x: float) -> Vector4 {
    return .{x, x, x, x};
}

xyzw :: (using v: Vector2, z: float, w: float) -> Vector4 {
    return .{x, y, z, w};
}

xyzw :: (using v: Vector3, w: float) -> Vector4 {
    return .{x, y, z, w};
}

rgb  :: xyz;
rgba :: xyzw;


normalize_or_identity :: (using q: *Quaternion) -> float {
    sq := sqrt(x*x + y*y + z*z + w*w);
    if sq == 0 {
        w = 1;
        return sq;
    }

    factor := 1.0 / sq;
    x *= factor;
    y *= factor;
    z *= factor;
    w *= factor;

    return sq;
} @NoProfile


abs :: inline (using v: Vector2) -> Vector2 {
    return .{abs(x), abs(y)};
}

abs :: inline (using v: Vector3) -> Vector3 {
    return .{abs(x), abs(y), abs(z)};
}

abs :: inline (using v: Vector4) -> Vector4 {
    return .{abs(x), abs(y), abs(z), abs(w)};
}

min :: inline (v1: Vector2, v2: Vector2) -> Vector2 {
    return .{Min(v1.x, v2.x), Min(v1.y, v2.y)};
}

min :: inline (v1: Vector3, v2: Vector3) -> Vector3 {
    return .{Min(v1.x, v2.x), Min(v1.y, v2.y), Min(v1.z, v2.z)};
}

min :: inline (v1: Vector4, v2: Vector4) -> Vector4 {
    return .{Min(v1.x, v2.x), Min(v1.y, v2.y), Min(v1.z, v2.z), Min(v1.w, v2.w)};
}

max :: inline (v1: Vector2, v2: Vector2) -> Vector2 {
    return .{Max(v1.x, v2.x), Max(v1.y, v2.y)};
}

max :: inline (v1: Vector3, v2: Vector3) -> Vector3 {
    return .{Max(v1.x, v2.x), Max(v1.y, v2.y), Max(v1.z, v2.z)};
}

max :: inline (v1: Vector4, v2: Vector4) -> Vector4 {
    return .{Max(v1.x, v2.x), Max(v1.y, v2.y), Max(v1.z, v2.z), Max(v1.w, v2.w)};
}



lerp :: inline (a: float, b: float, t: float) -> float {
    return a + (b - a) * t;
} @NoProfile

lerp :: inline (a: float64, b: float64, t: float64) -> float64 {
    return a + (b - a) * t;
} @NoProfile

lerp :: (a: $R, b: R, t: float) -> R
#modify {
    // This lerp only applies to the types below:
    return (R == Vector2) || (R == Vector3) || (R == Vector4) || (R == Quaternion);
} {
    return a + (b - a) * t;
}

lerp :: (a: Quaternion, b: Quaternion, t: float) -> Quaternion {
    r: Quaternion = ---;

    r.x = a.x + t * (b.x - a.x);
    r.y = a.y + t * (b.y - a.y);
    r.z = a.z + t * (b.z - a.z);
    r.w = a.w + t * (b.w - a.w);

    return r;
} @NoProfile

lerp :: (a: Vector2, b: Vector2, t: float) -> Vector2 {
    r: Vector2 = ---;

    r.x = a.x + t * (b.x - a.x);
    r.y = a.y + t * (b.y - a.y);

    return r;
} @NoProfile

lerp :: (a: Vector3, b: Vector3, t: float) -> Vector3 {
    r: Vector3 = ---;

    r.x = a.x + t * (b.x - a.x);
    r.y = a.y + t * (b.y - a.y);
    r.z = a.z + t * (b.z - a.z);

    return r;
} @NoProfile

lerp :: (a: Vector4, b: Vector4, t: float) -> Vector4 {
    r: Vector4 = ---;

    r.x = a.x + t * (b.x - a.x);
    r.y = a.y + t * (b.y - a.y);
    r.z = a.z + t * (b.z - a.z);
    r.w = a.w + t * (b.w - a.w);

    return r;
} @NoProfile

nlerp :: inline (p0: Quaternion, p1: Quaternion, fraction: float) -> Quaternion {
    result := lerp(p0, p1, fraction);
	normalize_or_identity(*result);

    return result;
}

slerp :: (start: Quaternion, end: Quaternion, t: float) -> Quaternion {
    // Input quaternions should be unit length or else
    // something broken will happen.

    // The technique below will work for input vectors of any
    // number of dimensions (you could write a templatized version
    // of the code, or one that takes a generic N-vector data type,
    // and it would just work).


    // Compute the cosine of the angle between the two vectors.
    dot := dot_product(start, end);

    DOT_THRESHOLD :: 0.9995;
    if dot > DOT_THRESHOLD {
        // If the inputs are too close for comfort, linearly interpolate
        // and normalize the result.
        result := lerp(start, end, t);
        normalize_or_identity(*result);
        return result;
    }

    Clamp(*dot, -1, 1);
    theta_0 := acos(dot);  // Angle between input vectors
    theta   := theta_0 * t;  // Angle between 'start' and result

    e1 := start;
    e2 := end - start * dot;
    normalize_or_identity(*e2);              // { e1, e2 } is now an orthonormal basis

    return (e1 * cos(theta)) + (e2 * sin(theta));
}

multiply :: (v: Vector2, f: float) -> Vector2 {
    return .{v.x * f, v.y * f};
}

multiply :: (v: Vector3, f: float) -> Vector3 {
    return .{v.x*f, v.y*f, v.z*f};
}

distance :: (a: Vector4, b: Vector4) -> float {
    dx := b.x - a.x;
    dy := b.y - a.y;
    dz := b.z - a.z;
    dw := b.w - a.w;

    return sqrt(dx*dx + dy*dy + dz*dz + dw*dw);
}

distance :: (a: Vector3, b: Vector3) -> float {
    // Once inline is totally turned on, We could just:
    //    return sqrt(distance_squared(a, b));

    dx := b.x - a.x;
    dy := b.y - a.y;
    dz := b.z - a.z;

    return sqrt(dx*dx + dy*dy + dz*dz);
}

distance_squared :: inline (a: Vector3, b: Vector3) -> float {
    dx := b.x - a.x;
    dy := b.y - a.y;
    dz := b.z - a.z;

    return dx*dx + dy*dy + dz*dz;
}

distance :: (a: Vector2, b: Vector2) -> float {
    dx := b.x - a.x;
    dy := b.y - a.y;

    return sqrt(dx*dx + dy*dy);
}

distance_squared :: inline (a: Vector2, b: Vector2) -> float {
    dx := b.x - a.x;
    dy := b.y - a.y;

    return dx*dx + dy*dy;
}

AnyVector2 :: struct {
    x: float;
    y: float;
}

normalize :: (v: *$T/MyVectors, epsilon := 0.0, fallback := T.{}) -> float {
    sq := length(v);
    if sq <= epsilon {
        v.* = fallback;
        return sq;
    }

    factor := 1 / sq;
    v.x *= factor;
    v.y *= factor;

    #if (T == Vector3) || (T == Vector4) || (T == Quaternion) then v.z *= factor;
    #if (T == Vector4) || (T == Quaternion) then v.w *= factor;

    return sq;
} @NoProfile

// More 'functional' version that returns the result;
// @Cleanup: This should probably be the main thing we support?
// Is there really any performance benefit to the in-place version in 2023?
// @Speed: We could put a $ in front of fallback to remove the inefficiency of a runtime parameter here?
normalize :: (v: $T/MyVectors, epsilon := 0.0, fallback := T.{}) -> T {
    w := v;
    inline normalize(*w, epsilon, fallback);
    return w;
} @NoProfile

unit_vector :: (v: Vector3) -> Vector3 {
    // Uses (0, 0, 0) as the fallback if v is 0.
    sq := sqrt(v.x*v.x + v.y*v.y + v.z*v.z);
    if sq == 0 return v;

    result: Vector3 = ---;
    factor := 1.0 / sq;
    result.x = v.x * factor;
    result.y = v.y * factor;
    result.z = v.z * factor;

    return result;
}

unit_vector :: (v: Vector2) -> Vector2 {
    // Uses (0, 0) as the fallback if v is 0.
    sq := sqrt(v.x*v.x + v.y*v.y);
    if sq == 0 return v;

    result: Vector2 = ---;
    factor := 1.0 / sq;
    result.x = v.x * factor;
    result.y = v.y * factor;

    return result;
}

rotate :: (v: *Vector2, theta: float) {
    ct := cos(theta);
    st := sin(theta);

    x := v.x * ct + v.y * -st;
    y := v.x * st + v.y * ct;

    v.x = x;
    v.y = y;
}

rotate :: (v: Vector2, theta: float) -> Vector2 {
    ct := cos(theta);
    st := sin(theta);

    r: Vector2 = ---;
    r.x = v.x * ct + v.y * -st;
    r.y = v.x * st + v.y * ct;

    return r;
}

cross :: cross_product;
cross_product :: (a: Vector3, b: Vector3) -> Vector3 {
    n: Vector3 = ---;

    n.x = a.y * b.z - a.z * b.y;
    n.y = a.z * b.x - a.x * b.z;
    n.z = a.x * b.y - a.y * b.x;

    return n;
}

rotate :: (v: Vector3, q: Quaternion) -> Vector3 {
    // For derivation, see: https://fgiesen.wordpress.com/2019/02/09/rotating-a-single-vector-using-a-quaternion/

    t := cross_product(q.xyz, v) * 2.0;

    return v + t * q.w + cross_product(q.xyz, t);
}

rotate :: (v: *Vector3, q: Quaternion) {
    t := cross_product(q.xyz, <<v) * 2.0;

    vv := <<v + t * q.w + cross_product(q.xyz, t);
    <<v = vv;
}



// Vector2 operators:

operator + :: (a: Vector2, b: Vector2) -> Vector2 {
    return .{a.x+b.x, a.y+b.y};
}

operator - :: (a: Vector2, b: Vector2) -> Vector2 {
    return .{a.x-b.x, a.y-b.y};
}

operator - :: (a: Vector2) -> Vector2 {
    return .{-a.x, -a.y};
}

operator * :: (a: Vector2, b: Vector2) -> Vector2 {
    // I always found it questionable to overload * as Hadamard product, but, I guess
    // this is what it is for now. We'll see if it causes confusion.
    // One example of potential confusion: * on Quaternion does a totally
    // different thing from * on Vector4.      -jblow, 7 January 2023.

    return .{a.x*b.x, a.y*b.y};
}

operator * :: (a: Vector2, k: float) -> Vector2  #symmetric {
    return .{a.x*k, a.y*k};
}

operator / :: (a: Vector2, b: Vector2) -> Vector2 {
    return .{a.x/b.x, a.y/b.y};
}

operator / :: (a: Vector2, k: float) -> Vector2 {
    denom := 1 / k;
    return .{a.x*denom, a.y*denom};
}

operator / :: (k: float, a: Vector2) -> Vector2 {
    return .{k/a.x, k/a.y};
}


// Why are we defining operator == for Vectors?
// You are probably writing bad code if you use this...!
// @Cleanup: We may remove this in the future.
operator == :: (a: Vector2, b: Vector2) -> bool {
    return a.x == b.x && a.y == b.y;
}

saturate :: (a: Vector2) -> Vector2 {
    return .{saturate(a.x), saturate(a.y)};
}


// Vector3 operators:

operator + :: (a: Vector3, b: Vector3) -> Vector3 {
    return .{a.x+b.x, a.y+b.y, a.z+b.z};
}

operator - :: (a: Vector3, b: Vector3) -> Vector3 {
    return .{a.x-b.x, a.y-b.y, a.z-b.z};
}

operator - :: (a: Vector3) -> Vector3 {
    return .{-a.x, -a.y, -a.z};
}

operator * :: (a: Vector3, b: Vector3) -> Vector3 {
    return .{a.x*b.x, a.y*b.y, a.z*b.z};
}

// @Cleanup: Make some kind of syntax like:  k: float|float64  ??
// Or some other easy way to do polymorphism with a scalar constraint?
// operator * :: (a: Vector3, k: float) -> Vector3  #symmetric
operator * :: (a: Vector3, k: float) -> Vector3  #symmetric {
    return .{a.x*k, a.y*k, a.z*k};
}

operator * :: (a: Vector3, k: float64) -> Vector3  #symmetric {
    return .{xx(a.x*k), xx(a.y*k), xx(a.z*k)};
}

operator / :: (a: Vector3, b: Vector3) -> Vector3 {
    return .{a.x/b.x, a.y/b.y, a.z/b.z};
}

operator / :: (a: Vector3, k: float) -> Vector3 {
    denom := 1 / k;
    return .{a.x*denom, a.y*denom, a.z*denom};
}

operator / :: (k: float, a: Vector3) -> Vector3 {
    return .{k/a.x, k/a.y, k/a.z};
}

operator == :: (a: Vector3, b: Vector3) -> bool {
    return a.x == b.x && a.y == b.y && a.z == b.z;
}

saturate :: (a: Vector3) -> Vector3 {
    return .{saturate(a.x), saturate(a.y), saturate(a.z)};
}


// Vector4 operators:

operator + :: (a: Vector4, b: Vector4) -> Vector4 {
    return .{a.x+b.x, a.y+b.y, a.z+b.z, a.w+b.w};
}

operator - :: (a: Vector4, b: Vector4) -> Vector4 {
    return .{a.x-b.x, a.y-b.y, a.z-b.z, a.w-b.w};
}

operator * :: (a: Vector4, b: Vector4) -> Vector4 {
    return .{a.x*b.x, a.y*b.y, a.z*b.z, a.w*b.w};
}

operator * :: (a: Vector4, k: float) -> Vector4  #symmetric {
    return .{a.x*k, a.y*k, a.z*k, a.w*k};
}

operator / :: (a: Vector4, b: Vector4) -> Vector4 {
    return .{a.x/b.x, a.y/b.y, a.z/b.z, a.w/b.w};
}

operator / :: (a: Vector4, k: float) -> Vector4 {
    denom := 1 / k;
    return .{a.x*denom, a.y*denom, a.z*denom, a.w*denom};
}

operator / :: (k: float, a: Vector4) -> Vector4 {
    return .{k/a.x, k/a.y, k/a.z, k/a.w};
}

operator == :: (a: Vector4, b: Vector4) -> bool {
    return a.x == b.x && a.y == b.y && a.z == b.z && a.w == b.w;
}

saturate :: (a: Vector4) -> Vector4 {
    return .{saturate(a.x), saturate(a.y), saturate(a.z), saturate(a.w)};
}


// Quaternion operators:

operator + :: (a: Quaternion, b: Quaternion) -> Quaternion {
    return .{a.x+b.x, a.y+b.y, a.z+b.z, a.w+b.w};
}

operator * :: (a: Quaternion, k: float) -> Quaternion  #symmetric {
    return .{a.x*k, a.y*k, a.z*k, a.w*k};
}

operator - :: (a: Quaternion, b: Quaternion) -> Quaternion {
    return .{a.x-b.x, a.y-b.y, a.z-b.z, a.w-b.w};
}

operator == :: (a: Quaternion, b: Quaternion) -> bool {
    return a.x == b.x && a.y == b.y && a.z == b.z && a.w == b.w;
}

operator - :: (using a: Quaternion) -> Quaternion {
    return .{-x, -y, -z, -w};
}

set_from_axis_and_angle :: (using q: *Quaternion, v: Vector3, theta: float) {
    axis := unit_vector(v);

    st := sin(theta * 0.5);
    ct := cos(theta * 0.5);

    x = axis.x * st;
    y = axis.y * st;
    z = axis.z * st;
    w = ct;
}

set_from_axis_and_angle :: inline (q: *Quaternion, x: float, y: float, z: float, theta: float) {
    set_from_axis_and_angle(q, .{x, y, z}, theta);
}

get_axis_and_angle :: (using q: Quaternion) -> x: float64, y: float64, z: float64, theta: float64 {
    safe_w := w;
    Clamp(*safe_w, -1, 1);

    theta := acos(safe_w);

    Basic.assert(theta >= -7);
    Basic.assert(theta <= 7);

    sin_theta := sin(theta);
    theta *= 2;

    EPSILON :: 0.0001;  // @Cleanup: Think about whether this is a good value.
    if (sin_theta < EPSILON) && (sin_theta > -EPSILON) {
        return 1, 0, 0, theta;
    }

    return  x / sin_theta, y / sin_theta, z / sin_theta, theta;
}

conjugate :: (using q: Quaternion) -> Quaternion {
    r: Quaternion = ---;
    r.x = -x;
    r.y = -y;
    r.z = -z;
    r.w = w;

    return r;
}

operator * :: (m: Quaternion, a: Quaternion) -> Quaternion {
    v  := m.xyz;
    av := a.xyz;

    r: Quaternion;
    r.w = m.w * a.w - dot_product(v, av);

    rv := cross_product(v, av);

    av *= m.w;
    v  *= a.w;

    rv = rv + av + v;

    r.x = rv.x;
    r.y = rv.y;
    r.z = rv.z;

    return r;

}

set_rotation :: (using m: *$T/interface AnyMatrix3, q: Quaternion) {
    s :: 2.0;

    xs := q.x * s;
    ys := q.y * s;
    zs := q.z * s;

    wx := q.w * xs;
    wy := q.w * ys;
    wz := q.w * zs;

    _xx := q.x * xs;
    xy := q.x * ys;
    xz := q.x * zs;

    yy := q.y * ys;
    yz := q.y * zs;
    zz := q.z * zs;

    _11 = 1.0 - (yy + zz);
    _12 = xy - wz;
    _13 = xz + wy;

    _21 = xy + wz;
    _22 = 1.0 - (_xx + zz);
    _23 = yz - wx;

    _31 = xz - wy;
    _32 = yz + wx;
    _33 = 1.0 - (_xx + yy);
}


get_rotation :: (using m: $T/interface AnyMatrix3) -> Quaternion {  // @Polymorph: Make it work on Matrix4 || Matrix3.

    // Algorithm in Ken Shoemake's article in 1987 SIGGRAPH course notes
    // article "Quaternion Calculus and Fast Animation".

    // @Cleanup: We are kinda cheating here because AnyMatrix3 doesn't
    // define coef[], because we don't have a way to do that with 'interface'
    // yet. Something to think about ... !

    q: Quaternion = ---;
    trace := _11 + _22 + _33;

    if trace > 0 {
        // |w| > 1/2, may as well choose w > 1/2
        s := sqrt(trace + 1);  // 2w

        q.w = s * 0.5;
        s = 0.5 / s;       // 1/(4w)

        q.x = (coef[2][1] - coef[1][2]) * s;
        q.y = (coef[0][2] - coef[2][0]) * s;
        q.z = (coef[1][0] - coef[0][1]) * s;
    } else {
        // |w| <= 1/2
        i := 0;
        if (coef[1][1] > coef[0][0]) i = 1;
        if (coef[2][2] > coef[i][i]) i = 2;

        j := (1 << i) & 3; // i + 1 modulo 3.
        k := (1 << j) & 3;

        s := sqrt(coef[i][i] - coef[j][j] - coef[k][k] + 1);

        q.component[i] = s * 0.5;
        s = 0.5 / s;
        q.component[j] = (coef[i][j] + coef[j][i]) * s;
        q.component[k] = (coef[k][i] + coef[i][k]) * s;
        q.w = (coef[k][j] - coef[j][k]) * s;
    }

    //assert(coef[3][3] == 1.0);
    //if (coef[3][3] != 1.0) q = q.scale(1.0 / sqrt(coef[3][3]));

    normalize_or_identity(*q);
    return q;
}

make_an_orthonormal_basis :: (x_axis: Vector3) -> (y_axis: Vector3, z_axis: Vector3) {
    cross := Vector3.{1, 1, 1};
    if x_axis.x > x_axis.y {
        if x_axis.x > x_axis.z {
            cross.x = 0;
        } else {
            cross.z = 0;
        }
    } else {
        if x_axis.y > x_axis.z {
            cross.y = 0;
        } else {
            cross.z = 0;
        }
    }

    y_axis := cross_product(cross, x_axis);
    normalize(*y_axis, fallback=.{z=1});

    z_axis := cross_product(x_axis, y_axis);
    normalize(*z_axis, fallback=.{z=1});

    return y_axis, z_axis;
}

make_an_orthonormal_basis :: (x_axis: Vector3, approximate_axis: Vector3) -> (y_axis: Vector3, z_axis: Vector3) {
    y_axis := cross_product(approximate_axis, x_axis);
    normalize(*y_axis, fallback=.{z=1});
    z_axis := cross_product(x_axis, y_axis);
    normalize(*z_axis, fallback=.{z=1});

    return y_axis, z_axis;
}




#scope_module
Basic :: #import "Basic";  // For assert, Swap.
Swap  :: Basic.Swap;
Min   :: Basic.min;
Max   :: Basic.max;


MyVectors :: Type.[Vector2, Vector3, Vector4, Quaternion];  // Used for type restriction in normalize().
