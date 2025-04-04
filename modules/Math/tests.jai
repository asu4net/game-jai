// These were tests that were in Math.jai, but it doesn't seem like a good idea
// to pay for tests every time everyone compiles (in part because of the overhead,
// in part because that overhead will cause people to write fewer tests than they
// otherwise would, which you don't want if you think tests really help!)
//
// Once we formalize someplace for tests to go, we can probably put these back
// into Math as something that gets optionally loaded...!

// @note @abner Yes. I'm going to decide whether the test framework should opt to load these from a tests.jai file.

/*
// @@ Make this work with float arguments.
// Use as: 'clamp(u8, i)'
clamp :: ($T : Type, i : $I) -> T {
    if i < min(T) i = min(T);
    if i > max(T) i = max(T);
    return cast,no_check(T) i; // We use no_check because we know it won't overflow.
}
*/

// values_are_close stuff has been moved to Sloppy_Math.
cast_and_limits :: () {
    assert(max(u8) == U8_MAX);
    assert(max(s8) == S8_MAX);
    assert(max(u16) == U16_MAX);
    assert(max(s16) == S16_MAX);
    assert(max(u32) == U32_MAX);
    assert(max(s32) == S32_MAX);
    assert(max(u64) == U64_MAX);
    assert(max(s64) == S64_MAX);
    assert(min(u8) == 0);
    assert(min(s8) == S8_MIN);
    assert(min(u16) == 0);
    assert(min(s16) == S16_MIN);
    assert(min(u32) == 0);
    assert(min(s32) == S32_MIN);
    assert(min(u64) == 0);
    assert(min(s64) == S64_MIN);

    assert(min(int) == S64_MIN);
    assert(max(int) == S64_MAX);
    
    assert(min(float) == FLOAT32_MIN);
    assert(max(float) == FLOAT32_MAX);
    assert(min(float32) == FLOAT32_MIN);
    assert(max(float32) == FLOAT32_MAX);
    assert(min(float64) == FLOAT64_MIN);
    assert(max(float64) == FLOAT64_MAX);
    
/*
    assert(clamp(u8, -1) == 0);
    assert(clamp(u16, -12341234) == 0);
    assert(clamp(u8, 256) == 255);
    assert(clamp(u8, 0xFF + 1) == 255);

    assert(clamp(float, max(float64)) == max(float));
*/
    // None of these work, but it would be nice to support them:
    //assert(clamp(float64, 1.0) == 1.0);                       // float always fits insdie float64, so this should be a no-op.
    //assert(clamp(s8, cast(u8)255) == max(s8));                // can't compare arguments with different sign: i_u8 < min(s8)
    //assert(clamp(u32, 1234122345234534.0) == max(u32));       // can't compare float against u32

    // It's also rather inconvenient that the compiler provides an error inside clamp (a polymorphic functin), but doesn't point you
    // to the location of where that particular polymorphic function is instanced. It could also be more clear about the values of the
    // polymorphic variables, for example: clamp :: ($T : Type, i : $I) with T=u8 and I=s8, or just: clamp(T=u8, I=s8)
} @test

float_limits :: () {
    assert(FLOAT32_MIN == cast(float)1.175494351e-38);
    assert(FLOAT32_MAX == cast(float)3.402823466e+38);
    assert(FLOAT64_MIN == 2.2250738585072014e-308);
    assert(FLOAT64_MAX == 1.7976931348623158e+308);
} @test

half_to_float :: () {

    // IC: Wouldn't it be nice to have binary number notation?

    assert(half_to_float(0x0000) == 0);
    assert(half_to_float(0x0001) == 5.96046448e-08);    // 0b0_00000_0000000001
    assert(half_to_float(0x0400) == 6.10351563e-05);    // 0b0_00001_0000000000
    assert(half_to_float(0x7bff) == 65504);             // 0b0_11110_1111111111
    assert(half_to_float(0x3bff) == 0.999511719);       // 0b0_01110_1111111111
    assert(half_to_float(0x3c00) == 1);                 // 0b0_01111_0000000000
    assert(half_to_float(0x3c01) == 1.000976563);       // 0b0_01111_0000000001
    assert(half_to_float(0xc000) == -2);                // 0b1_10000_0000000000

    assert(isinf(half_to_float(0x7c00)));   // INF
    assert(isinf(half_to_float(0xfc00)));   // -INF
    assert(isnan(half_to_float(0xffff)));   // NaN
} @test

inverse_test :: () {

    q : Quaternion;
    set_from_axis_and_angle(*q, xyz(1, 2, 3), PI/3);

    m := make_matrix4(1, 2, 3, 4, 1, 2, 4, 8, 1, 3, 6, 9, 0, 0, 0, 1);
    //m := Matrix4_Identity;
    //m := make_scale_matrix4(xyz(1, 2, 3));
    //m := make_rotation_matrix4(q);
    //m = scale(m, xyz(1, 2, 3));

    // print ("%\n", m);

    mi1 := inverse(m);
    mi2 := inverse_gaussian_elimination(m);
    mi3 := inverse_lengyel(m);

    // print("\nInverses:\n");

    // print ("%\n", mi1);
    // print ("%\n", mi2);
    // print ("%\n", mi3);

    is_identity :: (m: Matrix4) -> bool {
        for i:0..3 for j:0..3 {
            if !values_are_close(m.coef[i][j], xx (i==j)) return false;
        }
        return true;
    }

    assert(is_identity(m * mi1));
    assert(is_identity(m * mi2));
    assert(is_identity(m * mi3));
} @test
