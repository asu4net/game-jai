
Matrix2 :: struct {
    _11, _12 : float;
    _21, _22 : float;

    #place _11; v:      [2]    Vector2 = ---; // These are row vectors.
    #place _11; coef:   [2][2] float   = ---;
    #place _11; floats: [4]    float   = ---;

    Row_Type    :: Vector2;
    Column_Type :: Vector2;

    IsMatrixFromMathModule :: true;
}

Matrix2_Identity :: Matrix2.{_11=1, _22=1};

Matrix3 :: struct {
    _11, _12, _13 : float;
    _21, _22, _23 : float;
    _31, _32, _33 : float;

    #place _11; v:      [3]    Vector3 = ---; // These are row vectors.
    #place _11; coef:   [3][3] float   = ---;
    #place _11; floats: [9]    float   = ---;

    Row_Type    :: Vector3;
    Column_Type :: Vector3;

    IsMatrixFromMathModule :: true;
}

Matrix3_Identity :: Matrix3.{_11=1, _22=1, _33=1};

Matrix4 :: struct {
    _11, _12, _13, _14 : float;
    _21, _22, _23, _24 : float;
    _31, _32, _33, _34 : float;
    _41, _42, _43, _44 : float;

    #place _11; mat4x3: Matrix4x3 = ---;

    #place _11; v:      [4]    Vector4 = ---; // These are row vectors.
    #place _11; coef:   [4][4] float   = ---;
    #place _11; floats: [16]   float   = ---;

    Row_Type    :: Vector4;
    Column_Type :: Vector4;

    IsMatrixFromMathModule :: true;
}

Matrix4_Identity :: Matrix4.{_11=1, _22=1, _33=1, _44=1};

Matrix4x3 :: struct {
    _11, _12, _13, _14 : float;
    _21, _22, _23, _24 : float;
    _31, _32, _33, _34 : float;

    // Matrix4x3 is used when you want to have a matrix that is
    // mathematically a Matrix4, but bottom row is known to be
    // [0, 0, 0, 1], which is a common case when doing affine
    // computer graphics. We eliminate the storage for that row
    // in order to save memory, avoid extra multiplies and adds, etc.

    #place _11; v:      [3]    Vector4 = ---; // These are row vectors.
    #place _11; coef:   [3][4] float   = ---;
    #place _11; floats: [12]   float   = ---;

    Row_Type    :: Vector4;
    Column_Type :: Vector3;

    IsMatrixFromMathModule :: true;
}

Matrix4x3_Identity :: Matrix4x3.{_11=1, _22=1, _33=1};

// We use AnyMatrix3 as an interface to do certain matrix operations on
// Matrix3, Matrix4, and Matrix4x3. get_rotation actually uses the coef[]
// array as well, but right now we do not have a way to declare this in
// an interface in any way that makes sense, so, you will just have to
// make sure any type you pass also has the appropriate coef array for now!
AnyMatrix3 :: struct {
    _11, _12, _13 : float;
    _21, _22, _23 : float;
    _31, _32, _33 : float;
}

// See the comment on AnyMatrix3 above.
AnyMatrix4x3 :: struct {
    _11, _12, _13, _14 : float;
    _21, _22, _23, _24 : float;
    _31, _32, _33, _34 : float;
}

AnyMatrix2 :: struct {
    _11, _12 : float;
    _21, _22 : float;
}

AnyMatrix :: struct {
    IsMatrixFromMathModule :: true;
}

// @Cleanup: Make row, column polymorphic?
row :: (m: Matrix4, i: int) -> Vector4 {
    return m.v[i];
}

column :: (m: Matrix4, i: int) -> Vector4 {
    return .{m.coef[0][i], m.coef[1][i], m.coef[2][i], m.coef[3][i]};
}


multiply :: (m: Matrix4, v: Vector4) -> Vector4 {
    result: Vector4 = ---;
    result.x = m._11 * v.x + m._12 * v.y + m._13 * v.z + m._14 * v.w;
    result.y = m._21 * v.x + m._22 * v.y + m._23 * v.z + m._24 * v.w;
    result.z = m._31 * v.x + m._32 * v.y + m._33 * v.z + m._34 * v.w;
    result.w = m._41 * v.x + m._42 * v.y + m._43 * v.z + m._44 * v.w;
    return result;
}

multiply :: (m: Matrix4x3, v: Vector4) -> Vector3 {
    result: Vector3 = ---;
    result.x = m._11 * v.x + m._12 * v.y + m._13 * v.z + m._14 * v.w;
    result.y = m._21 * v.x + m._22 * v.y + m._23 * v.z + m._24 * v.w;
    result.z = m._31 * v.x + m._32 * v.y + m._33 * v.z + m._34 * v.w;
    return result;
}

multiply :: (m: Matrix2, v: Vector2) -> Vector2 {
    r: Vector2 = ---;
    r.x = m._11 * v.x + m._12 * v.y;
    r.y = m._21 * v.x + m._22 * v.y;

    return r;
}


// We can't condense these matrix-vector multiplies into one
// routine because of the thing where Matrix4x3*Vector4 yields Vector3.
// (Unless we add another field saying what multiply returns, or
// do a one-off weird hack.)
operator * :: (m: Matrix4, v: Vector4) -> Vector4 {
    return inline multiply(m, v);
}

operator * :: (m: Matrix4x3, v: Vector4) -> Vector3 {
    return inline multiply(m, v);
}

operator * :: (m: Matrix3, v: Vector3) -> Vector3 {
    return inline multiply(m, v);
}

transform_point :: (m: $T/interface AnyMatrix4x3, v: Vector3) -> Vector3 {
    result: Vector3 = ---;
    result.x = m._11 * v.x + m._12 * v.y + m._13 * v.z + m._14;
    result.y = m._21 * v.x + m._22 * v.y + m._23 * v.z + m._24;
    result.z = m._31 * v.x + m._32 * v.y + m._33 * v.z + m._34;
    return result;
}

multiply :: (m: $T/interface AnyMatrix3, v: Vector3) -> Vector3 {
    result: Vector3 = ---;
    result.x = m._11 * v.x + m._12 * v.y + m._13 * v.z;
    result.y = m._21 * v.x + m._22 * v.y + m._23 * v.z;
    result.z = m._31 * v.x + m._32 * v.y + m._33 * v.z;
    return result;
}

transform_vector :: (m: $T/interface AnyMatrix3, v: Vector3) -> Vector3 {
    return inline multiply(m, v);
}


// We could and maybe should do some 'interface' stuff to cut down on all these
// 'multiply' variants, or, at least factoring out the 3x3 coefficients
// and adding the rest in. Possibly we can do some #if action.

multiply :: (m: Matrix2, n: Matrix2) -> Matrix2 {
    result: Matrix2 = ---;

    result._11 = m._11 * n._11 + m._12 * n._21;
    result._21 = m._21 * n._11 + m._22 * n._21;

    result._12 = m._11 * n._12 + m._12 * n._22;
    result._22 = m._21 * n._12 + m._22 * n._22;

    return result;
}

multiply :: (m: Matrix3, n: Matrix3) -> Matrix3 {
    result: Matrix3 = ---;

    result._11 = m._11 * n._11 + m._12 * n._21 + m._13 * n._31;
    result._21 = m._21 * n._11 + m._22 * n._21 + m._23 * n._31;
    result._31 = m._31 * n._11 + m._32 * n._21 + m._33 * n._31;

    result._12 = m._11 * n._12 + m._12 * n._22 + m._13 * n._32;
    result._22 = m._21 * n._12 + m._22 * n._22 + m._23 * n._32;
    result._32 = m._31 * n._12 + m._32 * n._22 + m._33 * n._32;

    result._13 = m._11 * n._13 + m._12 * n._23 + m._13 * n._33;
    result._23 = m._21 * n._13 + m._22 * n._23 + m._23 * n._33;
    result._33 = m._31 * n._13 + m._32 * n._23 + m._33 * n._33;

    return result;
}


multiply :: (m: Matrix4, n: Matrix3) -> Matrix4 {
    result: Matrix4 = ---;

    result._11 = m._11*n._11 + m._12*n._21 + m._13*n._31;
    result._21 = m._21*n._11 + m._22*n._21 + m._23*n._31;
    result._31 = m._31*n._11 + m._32*n._21 + m._33*n._31;
    result._41 = m._41*n._11 + m._42*n._21 + m._43*n._31;

    result._12 = m._11*n._12 + m._12*n._22 + m._13*n._32;
    result._22 = m._21*n._12 + m._22*n._22 + m._23*n._32;
    result._32 = m._31*n._12 + m._32*n._22 + m._33*n._32;
    result._42 = m._41*n._12 + m._42*n._22 + m._43*n._32;

    result._13 = m._11*n._13 + m._12*n._23 + m._13*n._33;
    result._23 = m._21*n._13 + m._22*n._23 + m._23*n._33;
    result._33 = m._31*n._13 + m._32*n._23 + m._33*n._33;
    result._43 = m._41*n._13 + m._42*n._23 + m._43*n._33;

    result._14 = m._14;
    result._24 = m._24;
    result._34 = m._34;
    result._44 = m._44;

    return result;
}


multiply :: (m: Matrix4, n: Matrix4) -> Matrix4 {
    result: Matrix4 = ---;

    result._11 = m._11*n._11 + m._12*n._21 + m._13*n._31 + m._14*n._41;
    result._21 = m._21*n._11 + m._22*n._21 + m._23*n._31 + m._24*n._41;
    result._31 = m._31*n._11 + m._32*n._21 + m._33*n._31 + m._34*n._41;
    result._41 = m._41*n._11 + m._42*n._21 + m._43*n._31 + m._44*n._41;

    result._12 = m._11*n._12 + m._12*n._22 + m._13*n._32 + m._14*n._42;
    result._22 = m._21*n._12 + m._22*n._22 + m._23*n._32 + m._24*n._42;
    result._32 = m._31*n._12 + m._32*n._22 + m._33*n._32 + m._34*n._42;
    result._42 = m._41*n._12 + m._42*n._22 + m._43*n._32 + m._44*n._42;

    result._13 = m._11*n._13 + m._12*n._23 + m._13*n._33 + m._14*n._43;
    result._23 = m._21*n._13 + m._22*n._23 + m._23*n._33 + m._24*n._43;
    result._33 = m._31*n._13 + m._32*n._23 + m._33*n._33 + m._34*n._43;
    result._43 = m._41*n._13 + m._42*n._23 + m._43*n._33 + m._44*n._43;

    result._14 = m._11*n._14 + m._12*n._24 + m._13*n._34 + m._14*n._44;
    result._24 = m._21*n._14 + m._22*n._24 + m._23*n._34 + m._24*n._44;
    result._34 = m._31*n._14 + m._32*n._24 + m._33*n._34 + m._34*n._44;
    result._44 = m._41*n._14 + m._42*n._24 + m._43*n._34 + m._44*n._44;

    return result;
}

multiply :: (m: Matrix4x3, n: Matrix4x3) -> Matrix4x3 {
    result: Matrix4x3 = ---;

    result._11 = m._11*n._11 + m._12*n._21 + m._13*n._31;
    result._21 = m._21*n._11 + m._22*n._21 + m._23*n._31;
    result._31 = m._31*n._11 + m._32*n._21 + m._33*n._31;

    result._12 = m._11*n._12 + m._12*n._22 + m._13*n._32;
    result._22 = m._21*n._12 + m._22*n._22 + m._23*n._32;
    result._32 = m._31*n._12 + m._32*n._22 + m._33*n._32;

    result._13 = m._11*n._13 + m._12*n._23 + m._13*n._33;
    result._23 = m._21*n._13 + m._22*n._23 + m._23*n._33;
    result._33 = m._31*n._13 + m._32*n._23 + m._33*n._33;

    result._14 = m._11*n._14 + m._12*n._24 + m._13*n._34 + m._14;
    result._24 = m._21*n._14 + m._22*n._24 + m._23*n._34 + m._24;
    result._34 = m._31*n._14 + m._32*n._24 + m._33*n._34 + m._34;

    return result;
}

multiply :: (m: Matrix4, n: Matrix4x3) -> Matrix4 {
    result: Matrix4 = ---;

    result._11 = m._11*n._11 + m._12*n._21 + m._13*n._31;
    result._21 = m._21*n._11 + m._22*n._21 + m._23*n._31;
    result._31 = m._31*n._11 + m._32*n._21 + m._33*n._31;
    result._41 = m._41*n._11 + m._42*n._21 + m._43*n._31;

    result._12 = m._11*n._12 + m._12*n._22 + m._13*n._32;
    result._22 = m._21*n._12 + m._22*n._22 + m._23*n._32;
    result._32 = m._31*n._12 + m._32*n._22 + m._33*n._32;
    result._42 = m._41*n._12 + m._42*n._22 + m._43*n._32;

    result._13 = m._11*n._13 + m._12*n._23 + m._13*n._33;
    result._23 = m._21*n._13 + m._22*n._23 + m._23*n._33;
    result._33 = m._31*n._13 + m._32*n._23 + m._33*n._33;
    result._43 = m._41*n._13 + m._42*n._23 + m._43*n._33;

    result._14 = m._11*n._14 + m._12*n._24 + m._13*n._34 + m._14;
    result._24 = m._21*n._14 + m._22*n._24 + m._23*n._34 + m._24;
    result._34 = m._31*n._14 + m._32*n._24 + m._33*n._34 + m._34;
    result._44 = m._41*n._14 + m._42*n._24 + m._43*n._34 + m._44;

    return result;
}

multiply :: (m: Matrix4x3, n: Matrix4) -> Matrix4 {
    result: Matrix4 = ---;

    result._11 = m._11*n._11 + m._12*n._21 + m._13*n._31 + m._14*n._41;
    result._21 = m._21*n._11 + m._22*n._21 + m._23*n._31 + m._24*n._41;
    result._31 = m._31*n._11 + m._32*n._21 + m._33*n._31 + m._34*n._41;
    result._41 = n._41;

    result._12 = m._11*n._12 + m._12*n._22 + m._13*n._32 + m._14*n._42;
    result._22 = m._21*n._12 + m._22*n._22 + m._23*n._32 + m._24*n._42;
    result._32 = m._31*n._12 + m._32*n._22 + m._33*n._32 + m._34*n._42;
    result._42 = n._42;

    result._13 = m._11*n._13 + m._12*n._23 + m._13*n._33 + m._14*n._43;
    result._23 = m._21*n._13 + m._22*n._23 + m._23*n._33 + m._24*n._43;
    result._33 = m._31*n._13 + m._32*n._23 + m._33*n._33 + m._34*n._43;
    result._43 = n._43;

    result._14 = m._11*n._14 + m._12*n._24 + m._13*n._34 + m._14*n._44;
    result._24 = m._21*n._14 + m._22*n._24 + m._23*n._34 + m._24*n._44;
    result._34 = m._31*n._14 + m._32*n._24 + m._33*n._34 + m._34*n._44;
    result._44 = n._44;

    return result;
}

// We cannot use #symmetric on operator *, unless one of the coefficients is a scalar,
// because matrix multiplication is not symmetric!
operator * :: (a: Matrix4, b: Matrix4) -> Matrix4 {
    return inline multiply(a, b);
}

operator * :: (a: Matrix4x3, b: Matrix4x3) -> Matrix4x3 {
    return inline multiply(a, b);
}

operator * :: (a: Matrix4, b: Matrix4x3) -> Matrix4 {
    return inline multiply(a, b);
}

operator * :: (a: Matrix4x3, b: Matrix4) -> Matrix4 {
    return inline multiply(a, b);
}

operator * :: (a: Matrix4, b: Matrix3) -> Matrix4 {
    return inline multiply(a, b);
}

operator * :: (a: Matrix3, b: Matrix3) -> Matrix3 {
    return inline multiply(a, b);
}

operator * :: (a: Matrix2, b: Matrix2) -> Matrix2 {
    return inline multiply(a, b);
}

operator * :: (a: Matrix2, b: Vector2) -> Vector2 {
    return inline multiply(a, b);
}

operator * :: (a: $T/interface AnyMatrix, t: float) -> T #symmetric {
    r: T = ---;
    for 0..a.floats.count-1  r.floats[it] = a.floats[it] * t;
    return r;
}

operator + :: (a: $T/interface AnyMatrix, b: T) -> T {
    r: T = ---;
    for 0..a.floats.count-1  r.floats[it] = a.floats[it] + b.floats[it];
    return r;
}

operator - :: (a: $T/interface AnyMatrix, b: T) -> T {
    r: T = ---;
    for 0..a.floats.count-1  r.floats[it] = a.floats[it] - b.floats[it];
    return r;
}

operator == :: (a: $T/interface AnyMatrix, b: T) -> bool {
    for i: 0..a.floats.count-1 {
        if a.floats[i] != b.floats[i] return false;
    }

    return true;
}

make_matrix3 :: (m: $T/interface AnyMatrix3) -> Matrix3 {  // Can use this to go from Matrix4x3 or Matrix4 down to Matrix3.
    r: Matrix3 = ---;
    for i: 0..2 for j: 0..2 {
        r.coef[i][j] = m.coef[i][j];
    }

    return r;
}

make_matrix4 :: (m: $T/interface AnyMatrix3) -> Matrix4 {
    // We'll start with Matrix4_Identity, then overwrite members below. Instead of this,
    // we could do a bunch of static checks that make the code more complex, but
    // that are more guaranteed to be optimized. But here we are relying on the
    // runtime optimizer.
    r := Matrix4_Identity;

    // We are being a little fast and loose, because we are using the coef array,
    // but AnyMatrix3 is declared to just use the _ab members.

    row := Basic.min(3, m.coef.count-1);     // Index of the highest row (0-based!)
    col := Basic.min(3, m.coef[0].count-1);  // Index of the highest column (0-based!)

    for i: 0..row {
        for j: 0..col {
            r.coef[i][j] = m.coef[i][j];
        }
    }

    return r;
}

// We should remove this. I mean, come on...
make_matrix4 :: (values: ..float) -> Matrix4 #deprecated "Use a struct literal instead." {
    r: Matrix4 = ---;

    for values {
        r.floats[it_index] = it;
    }

    return r;
}

// @Cleanup: Make transpose() polymorphic?

// Transpose a 4x4 matrix.
transpose :: (m: Matrix4) -> Matrix4 {
    r: Matrix4 = ---;

    for i: 0..3 for j: 0..3 {
        r.coef[i][j] = m.coef[j][i];
    }

    return r;
}

// Transpose a 3x3 matrix.
transpose :: (m: Matrix3) -> Matrix3 {
    r: Matrix3 = ---;

    for i: 0..2 for j: 0..2 {
        r.coef[i][j] = m.coef[j][i];
    }

    return r;
}

// Transpose a 4x4 matrix in place.
transpose :: (m: *Matrix4) {
    Swap(*m.coef[0][1], *m.coef[1][0]);
    Swap(*m.coef[0][2], *m.coef[2][0]);
    Swap(*m.coef[0][3], *m.coef[3][0]);

    Swap(*m.coef[1][2], *m.coef[2][1]);
    Swap(*m.coef[1][3], *m.coef[3][1]);

    Swap(*m.coef[2][3], *m.coef[3][2]);
}

// Transpose a 3x3 matrix in place.
transpose :: (m: *Matrix3) {
    Swap(*m.coef[0][1], *m.coef[1][0]);
    Swap(*m.coef[0][2], *m.coef[2][0]);
    Swap(*m.coef[1][2], *m.coef[2][1]);
}


// @Cleanup: Remove make_scale_*, these are goofy.

make_scale_matrix4 :: (v: Vector3) -> Matrix4 {
    m: Matrix4 = ---;
    identity(*m);

    m._11 = v.x;
    m._22 = v.y;
    m._33 = v.z;

    return m;
}

scale :: (m: $T/interface AnyMatrix3, s: float) -> T {
    scale(*m, s);   // This * implicitly creates a copy of m.
    return m;
}

scale :: (m: *$T/interface AnyMatrix3, s: float) {
    m._11 *= s;
    m._21 *= s;
    m._31 *= s;

    m._12 *= s;
    m._22 *= s;
    m._32 *= s;

    m._13 *= s;
    m._23 *= s;
    m._33 *= s;
}

scale :: (m: $T/interface AnyMatrix3, v: Vector3) -> T {
    scale(*m, v);   // This * implicitly creates a copy of m.
    return m;
}

scale :: (m: *$T/interface AnyMatrix3, v: Vector3) {
    m._11 *= v.x;
    m._21 *= v.x;
    m._31 *= v.x;

    m._12 *= v.y;
    m._22 *= v.y;
    m._32 *= v.y;

    m._13 *= v.z;
    m._23 *= v.z;
    m._33 *= v.z;
}


// Returns a translation matrix given a translation vector.
make_translation_matrix4 :: (v: Vector3) -> Matrix4 {
    m: Matrix4 = ---;
    identity(*m);

    m._14 = v.x;
    m._24 = v.y;
    m._34 = v.z;

    return m;
}

// Apply a translation to the given matrix.
translate :: (using m: Matrix4, t: Vector3) -> Matrix4 {
    result := m;
    inline translate(*result, t);
    return result;
}

// Apply a translation to the given matrix in place.
translate :: (using m: *Matrix4, t: Vector3) {
    m.coef[0][3] += m.coef[0][0] * t.x + m.coef[0][1] * t.y + m.coef[0][2] * t.z;
    m.coef[1][3] += m.coef[1][0] * t.x + m.coef[1][1] * t.y + m.coef[1][2] * t.z;
    m.coef[2][3] += m.coef[2][0] * t.x + m.coef[2][1] * t.y + m.coef[2][2] * t.z;
    m.coef[3][3] += m.coef[3][0] * t.x + m.coef[3][1] * t.y + m.coef[3][2] * t.z;
}


// @Cleanup: Remove this...
// Apply the given quaternion rotation to the given 3x3 matrix.
rotate :: (m: Matrix3, q: Quaternion) -> Matrix3 {
    R := rotation_matrix(Matrix3, q);
    return m * R;
}

// @Cleanup: Remove this...
// Apply the given quaternion rotation to the given 4x4 matrix.
rotate :: (m: Matrix4, q: Quaternion) -> Matrix4 {
    R := rotation_matrix(Matrix3, q);
    return m * R;
}


// make_matrix_from_rows() and make_matrix_from_columns() are
// just convenience functions that can be useful when building
// matrices that transform from one space to another. The classic
// way to do this is put the basis vectors in one matrix as rows,
// in the other as columns, and then multiply them together.

make_matrix_from_rows :: (xprime: Vector3, yprime: Vector3, zprime: Vector3, $T := Matrix4) -> T {
    result: T;
    result._11 = xprime.x;
    result._12 = xprime.y;
    result._13 = xprime.z;

    result._21 = yprime.x;
    result._22 = yprime.y;
    result._23 = yprime.z;

    result._31 = zprime.x;
    result._32 = zprime.y;
    result._33 = zprime.z;

    #if T == Matrix4  result._44 = 1;

    return result;
}

make_matrix_from_columns :: (xprime: Vector3, yprime: Vector3, zprime: Vector3, $T := Matrix4) -> T {
    result: T;
    result._11 = xprime.x;
    result._21 = xprime.y;
    result._31 = xprime.z;

    result._12 = yprime.x;
    result._22 = yprime.y;
    result._32 = yprime.z;

    result._13 = zprime.x;
    result._23 = zprime.y;
    result._33 = zprime.z;

    #if T == Matrix4  result._44 = 1;

    return result;
}


//
// Probably the graphics-centric matrix routines, like make_look_at_matrix, projection_matrix, etc,
// should be somewhere else?
//
make_look_at_matrix :: (viewpoint: Vector3,
                        look_at: Vector3,
                        reference_up_vector: Vector3, $x_is_forward := true) -> Matrix4 {

    forward := look_at - viewpoint;
    normalize(*forward, fallback=.{z=1});

    left := cross_product(reference_up_vector, forward);
    normalize(*left, fallback=.{z=1});

    up := cross_product(forward, left);
    normalize(*up, fallback=.{z=1});  // Just for accuracy's sake.

    // We are making the inverse of the transform that takes axis_forward to the forward vector.
    // So we use make_matrix_from_rows to get the inverse rotation, then multiply the translation
    // negation on the right-hand side.

    #if x_is_forward {
        rotation := make_matrix_from_rows(forward, left, up);
    } else {
        rotation := make_matrix_from_rows(left * -1, up, forward * -1);
    }

    //translation := Matrix4_Identity;
    //translation._14 = -viewpoint.x;
    //translation._24 = -viewpoint.y;
    //translation._34 = -viewpoint.z;
    //result := rotation * translation;
    result := translate(rotation, -viewpoint);

    return result;
}

orthographic_projection_matrix :: (left: float, right: float, bottom: float, top: float, near: float, far: float, depth_range_01:=false) -> Matrix4
{
    m : Matrix4;

    m._11 = 2.0 / (right - left);
    m._14 = - (right + left) / (right - left);

    m._22 = 2.0 / (top - bottom);
    m._24 = - (top + bottom) / (top - bottom);

    // if depth_range_01 {
    //     m._33 = -1 / (far - near);
    //     m._34 = near / (far - near);
    // }
    // else {
        m._33 = -2 / (far - near);
        m._34 = - (far + near) / (far - near);
    // }
    m._44 = 1.0;

    if depth_range_01 {
        // To map -1,1 depth range to 0,1 we transform z as follows: z' = z * 0.5 + 0.5
        m._33 = m._33 * 0.5 + m._43 * 0.5;
        m._34 = m._34 * 0.5 + m._44 * 0.5;
    }

    return m;
}

//
// This makes a minus-z-forward projection matrix.
// Minus-z-forward is a super dumb and confusing standard, but it is what most people use.
// In the engine we use x-forward for everything, and apply a fixup to the
// projection matrix returned here, to swizzle around the result of the
// x-forward view matrix.
//
make_projection_matrix :: (fov_vertical: float, aspect_ratio_horizontal_over_vertical: float, z_near: float, z_far: float, x_offset:=0.0, y_offset:=0.0, depth_range_01:=false) -> Matrix4 {
    result := Matrix4_Identity;

    tan_theta := tan(fov_vertical * 0.5);
    cot_theta := 1 / tan_theta;

    // this was d3d-style (ndc z 0->1)
    // @Hack 6 August 2016, I just stuck a - in here to put things the right way;
    // clean this up!
//    beta := -z_far / (z_far - z_near);
    f := z_far;
    n := z_near;
    denom := 1 / (f - n);

    result._11 = cot_theta / aspect_ratio_horizontal_over_vertical;
    result._22 = cot_theta;
    result._33 = -(f + n) * denom;
    result._43 = -1;
    result._34 = -2 * f * n * denom;
    result._44 = 0;

    result._13 = x_offset; // / w;
    result._23 = y_offset; // / h;

    // if depth_range_01 {
    //     result._33 = -f * denom;
    //     result._34 = -f * denom * n;
    // }
    // else {
    //     result._33 = -(f + n) * denom;
    //     result._34 = -2 * f * n * denom;
    // }

    if depth_range_01 {
        // To map -1,1 depth range to 0,1 we transform z as follows: z' = z * 0.5 + 0.5
        result._33 = result._33 * 0.5 + result._43 * 0.5;
        result._34 = result._34 * 0.5 + result._44 * 0.5;
        // In you wanna do any derivations with our depth_range_01 projection
        // matrix, the previous 2-line transform produces this:
        // result._33 = 0.5 * (-(f+n)/(f-n)) - 0.5 = 0.5*(-1+(-f-n)/(f-n))
        // result._34 = 0.5 * (-2*f*n / (f-n)) = -f*n / (f-n)
    }

    return result;
}


// IC: Right-handed perspective projection matrix. Maps near plane to z=-1, far to z=1. Looks along the negative Z axis.
make_frustum_matrix :: (l: float, r: float, b: float, t: float, n: float, f: float, depth_range_01:=false) -> Matrix4 {

    double_znear := 2.0 * n;
    one_deltax := 1.0 / (r - l);
    one_deltay := 1.0 / (t - b);
    one_deltaz := 1.0 / (f - n);

    result := Matrix4_Identity;
    result._11 = double_znear * one_deltax;
    result._22 = double_znear * one_deltay;
    result._13 = (r + l) * one_deltax;
    result._23 = (t + b) * one_deltay;
    result._33 = -(f + n) * one_deltaz;
    result._43 = -1;
    result._34 = -f * double_znear * one_deltaz;
    result._44 = 0;

    // if depth_range_01 {
    //     result._33 = -f * one_deltaz;
    //     result._34 = -f * one_deltaz * n;
    // }
    // else {
    //     result._33 = -(f + n) * one_deltaz;
    //     result._34 = -f * double_znear * one_deltaz;
    // }

    if depth_range_01 {
        // To map -1,1 depth range to 0,1 we transform z as follows: z' = z * 0.5 + 0.5
        result._33 = result._33 * 0.5 + result._43 * 0.5;
        result._34 = result._34 * 0.5 + result._44 * 0.5;
    }

    return result;
}

lerp :: (a: Matrix3, b: Matrix3, t: float) -> Matrix3 {
    // We provide lerp on a Matrix3 because we use it for
    // scale/shear matrices. But if you have a Matrix3 that
    // represents a rotation or a general transformation,
    // you *really* should not linearly interpolate it
    // unless you really really really know what you are doing.

    r: Matrix3 = ---;

    // We would like to be able to write the following thing
    // instead of the expanded-out code below, and have full
    // confidence that the compiler generates something efficient
    // for it even in Debug builds.

    // #unroll for 0..8  r.floats[it] = inline lerp(a.floats[it], b.floats[it], t);

    r._11 = a._11 + t*(b._11 - a._11);
    r._12 = a._12 + t*(b._12 - a._12);
    r._13 = a._13 + t*(b._13 - a._13);

    r._21 = a._21 + t*(b._21 - a._21);
    r._22 = a._22 + t*(b._22 - a._22);
    r._23 = a._23 + t*(b._23 - a._23);

    r._31 = a._31 + t*(b._31 - a._31);
    r._32 = a._32 + t*(b._32 - a._32);
    r._33 = a._33 + t*(b._33 - a._33);


    return r;
}


inverse :: (a: Matrix3, epsilon := 0.001) -> (success: bool, result: Matrix3) {
    r: Matrix3 = ---;

    c11 := a._22*a._33 - a._32*a._23;
    c12 := a._21*a._33 - a._31*a._23;
    c13 := a._21*a._32 - a._31*a._22;

    // Determinant.
    det := a._11*c11 - a._12*c12 + a._13*c13;

    if (det < epsilon) && (det > -epsilon)  return false, a;  // Failure... undefined!

    idet := 1/det;

    r._11 =  idet*c11;
    r._12 = -idet*(a._12*a._33 - a._13*a._32);
    r._13 =  idet*(a._12*a._23 - a._13*a._22);
    r._21 = -idet*c12;
    r._22 =  idet*(a._11*a._33 - a._13*a._31);
    r._23 = -idet*(a._11*a._23 - a._13*a._21);
    r._31 =  idet*c13;
    r._32 = -idet*(a._11*a._32 - a._12*a._31);
    r._33 =  idet*(a._11*a._22 - a._12*a._21);

    return true, r;
}



//
// UGLY STUFF!
//

inverse :: (m: Matrix4) -> (success: bool, result: Matrix4) {
    matr := m; // Arguments are immutable, even though the code below compiles fine! -ic 7 August 2019

    k, l, ll: int = ---;
    icol := 0;
    irow := 0;

    indxc: [4] int = ---;
    indxr: [4] int = ---;
    ipiv:  [4] int;

    ident := Matrix4_Identity;

    for i: 0..3 {
        big : float64 = 0.0;
        for j: 0..3 {
            if ipiv[j] != 1 {  // @Cleanup: Invert this nesting w/ a continue.
                for k: 0..3 {
                    if ipiv[k] == 0 {
                        if abs(matr.coef[j][k]) >= big {
                            big = abs(matr.coef[j][k]);
                            irow=j;
                            icol=k;
                        }
                    } else {
                        if ipiv[k] > 1  return false, ident;
                    }
                }
            }
        }

        ipiv[icol] += 1;

        if irow != icol {
            for l: 0..3 Swap(*matr .coef[irow][l], *matr .coef[icol][l]);
            for l: 0..3 Swap(*ident.coef[irow][l], *ident.coef[icol][l]);
        }

        indxr[i] = irow;
        indxc[i] = icol;

        if matr.coef[icol][icol] == 0.0  return false, ident;
        pivinv : float64 = 1 / matr.coef[icol][icol];
        matr.coef[icol][icol] = 1;

        //
        // @Robustness: The auto-casts here on pivinv are losing us
        // precision. How do we notate that we want the * to happen
        // as float64 even though the thing on the left is float32?
        //               -jblow, 1 February 2017.
        //
        // WARNING: I may have destabilized the results of this routine!!!
        //

        // Do not use *= here, because we want to do the multiply in float64,
        // then cast to float32.
        for l: 0..3 { matr .coef[icol][l] = cast(float32)(matr .coef[icol][l] * pivinv); }
        for l: 0..3 { ident.coef[icol][l] = cast(float32)(ident.coef[icol][l] * pivinv); }

        for ll: 0..3 {
            if ll != icol {
                dum := matr.coef[ll][icol];
                matr.coef[ll][icol] = 0;

                for l: 0..3 { matr .coef[ll][l] -= xx (matr .coef[icol][l]*dum); }
                for l: 0..3 { ident.coef[ll][l] -= xx (ident.coef[icol][l]*dum); }
            }
        }
    }

    for #v2 < l: 0..3 {
        if indxr[l] != indxc[l] {
            for k: 0..3 {
                Swap(*matr.coef[k][indxr[l]], *matr.coef[k][indxc[l]]);
            }
        }
    }

    return true, ident;
}

// Inverse using gaussian elimination.
inverse_gaussian_elimination :: (m: Matrix4) -> (success: bool, result: Matrix4) {
    A := m;
    B := Matrix4_Identity;
    det := 1.0;

    for i: 0..3 {                       // eliminate in column i, below diag
        j: int;
        max := -1.0;
        for k: i..3 {                   // find pivot for column i
            if abs(A.coef[k][i]) > max {
                max = abs(A.coef[k][i]);
                j = k;
            }
        }

        if max <= 0 return false, B;           // if no nonzero pivot, PUNT
        
        if j != i {                     // swap rows i and j
            for k: i..3     Swap(*A.coef[i][k], *A.coef[j][k]);
            for k: 0..3     Swap(*B.coef[i][k], *B.coef[j][k]);
            det = -det;
        }

        pivot := A.coef[i][i];
        det *= pivot;
        for k: i+1..3   A.coef[i][k] /= pivot;      // only do elems to right of pivot
        for k: 0..3     B.coef[i][k] /= pivot;
        // we know that A(i, i) will be set to 1, so don't bother to do it

        for j: i+1..3 {                 // eliminate in rows below i
            t := A.coef[j][i];          // we're gonna zero this guy
            for k: i+1..3               // subtract scaled row i from row j
                A.coef[j][k] -= A.coef[i][k]*t;                // (ignore k<=i, we know they're 0)
            for k: 0..3
                B.coef[j][k] -= B.coef[i][k]*t;
        }
    }

    /*---------- backward elimination ----------*/

    for #v2 < i: 1..3 {                 // eliminate in column i, above diag
        for j: 0..i-1 {                 // eliminate in rows above i
            t := A.coef[j][i];          // we're gonna zero this guy
            for k: 0..3                 // subtract scaled row i from row j
                B.coef[j][k] -= B.coef[i][k]*t;
        }
    }

    return true, B;
}


// An efficient inverse for small 4x4 matrices.  Note that it does not try to maximize floating point precision,
// but is faster and  works well enough for most of the well conditioned matrices we have typically have in the game.
//
// For reference, see: 1.7.5 Inverses of Small Matrices in 'Foundations of Game Development: Mathematics' by Eric Lengyel.
inverse_lengyel :: (m: Matrix4, epsilon := 0.0001) -> (success: bool, result: Matrix4) {
    a := Vector3.{m._11, m._21, m._31};
    b := Vector3.{m._12, m._22, m._32};
    c := Vector3.{m._13, m._23, m._33};
    d := Vector3.{m._14, m._24, m._34};

    x := m._41;
    y := m._42;
    z := m._43;
    w := m._44;

    s := cross(a, b);
    t := cross(c, d);
    u := a * y - b * x;
    v := c * w - d * z;

    det := dot(s, v) + dot(t, u);
    
    if abs(det) < epsilon {
        return false, Matrix4_Identity;
    }
    
    inv_det := 1.0 / det;
    s *= inv_det;
    t *= inv_det;
    u *= inv_det;
    v *= inv_det;

    r0 := cross(b, v) + t * y;
    r1 := cross(v, a) - t * x;
    r2 := cross(d, u) + s * w;
    r3 := cross(u, c) - s * z;

    return true,
           .{
            r0.x, r0.y, r0.z, -dot(b, t),
            r1.x, r1.y, r1.z,  dot(a, t),
            r2.x, r2.y, r2.z, -dot(d, s),
            r3.x, r3.y, r3.z,  dot(c, s)};
}

// The adjugate is the inverse of matrix M multiplied by its determinant. The adjugate always exists and is a cheaper to compute than the inverse.
//
// For reference, see: 1.7.5 Inverses of Small Matrices in 'Foundations of Game Development: Mathematics' by Eric Lengyel.
adjugate_lengyel :: (m: Matrix4) -> Matrix4 {

    a := Vector3.{m._11, m._21, m._31};
    b := Vector3.{m._12, m._22, m._32};
    c := Vector3.{m._13, m._23, m._33};
    d := Vector3.{m._14, m._24, m._34};

    x := m._41;
    y := m._42;
    z := m._43;
    w := m._44;

    s := cross(a, b);
    t := cross(c, d);
    u := a * y - b * x;
    v := c * w - d * z;

    r0 := cross(b, v) + t * y;
    r1 := cross(v, a) - t * x;
    r2 := cross(d, u) + s * w;
    r3 := cross(u, c) - s * z;

    return .{
            r0.x, r0.y, r0.z, -dot(b, t),
            r1.x, r1.y, r1.z,  dot(a, t),
            r2.x, r2.y, r2.z, -dot(d, s),
            r3.x, r3.y, r3.z,  dot(c, s)};
}

adjugate :: adjugate_lengyel;

determinant :: (m: Matrix4) -> float {
    // return
    //     m._14 * m._23 * m._32 * m._41 - m._13 * m._24 * m._32 * m._41 - m._14 * m._22 * m._33 * m._41 + m._12 * m._24 * m._33 * m._41 +
    //     m._13 * m._22 * m._34 * m._41 - m._12 * m._23 * m._34 * m._41 - m._14 * m._23 * m._31 * m._42 + m._13 * m._24 * m._31 * m._42 +
    //     m._14 * m._21 * m._33 * m._42 - m._11 * m._24 * m._33 * m._42 - m._13 * m._21 * m._34 * m._42 + m._11 * m._23 * m._34 * m._42 +
    //     m._14 * m._22 * m._31 * m._43 - m._12 * m._24 * m._31 * m._43 - m._14 * m._21 * m._32 * m._43 + m._11 * m._24 * m._32 * m._43 +
    //     m._12 * m._21 * m._34 * m._43 - m._11 * m._22 * m._34 * m._43 - m._13 * m._22 * m._31 * m._44 + m._12 * m._23 * m._31 * m._44 +
    //     m._13 * m._21 * m._32 * m._44 - m._11 * m._23 * m._32 * m._44 - m._12 * m._21 * m._33 * m._44 + m._11 * m._22 * m._33 * m._44;

    a := m.v[0].xyz;
    b := m.v[1].xyz;
    c := m.v[2].xyz;
    d := m.v[3].xyz;

    x := m.v[0].w;
    y := m.v[1].w;
    z := m.v[2].w;
    w := m.v[3].w;

    s := cross(a, b);
    t := cross(c, d);
    u := a * y - b * x;
    v := c * w - d * z;

    return dot(s, v) + dot(t, u);
}

isometry_inverse :: (m: Matrix4) -> Matrix4 {
    result := Matrix4_Identity;

    // transposed 3x3 upper left matrix
    for i: 0..2 {
        for j: 0..2 {
            result.coef[i][j] = m.coef[j][i];
        }
    }

    // translate by the negative offsets
    t := Vector3.{-m.coef[0][3], -m.coef[1][3], -m.coef[2][3]};

    //return translate(result, t);

    // This is slightly more efficient, because we know the last row is (0,0,0,1)
    result.coef[0][3] = result.coef[0][0] * t.x + result.coef[0][1] * t.y + result.coef[0][2] * t.z;
    result.coef[1][3] = result.coef[1][0] * t.x + result.coef[1][1] * t.y + result.coef[1][2] * t.z;
    result.coef[2][3] = result.coef[2][0] * t.x + result.coef[2][1] * t.y + result.coef[2][2] * t.z;
    return result;
}

// For reference:
// https://github.com/erich666/GraphicsGems/blob/master/gemsiv/polar_decomp/Decompose.c

// @@ Is the adjoint_transpose == adjugate ?
adjoint_transpose :: (m: Matrix3) -> Matrix3 {
    r: Matrix3 = ---;
    r.v[0] = cross(m.v[1], m.v[2]);
    r.v[1] = cross(m.v[2], m.v[0]);
    r.v[2] = cross(m.v[0], m.v[1]);
    return r;
}

// Compute either the 1 or infinity norm of M, depending on tpose
mat_norm :: (M: Matrix3, tpose: bool) -> float {
    max := 0.0;
    for i: 0..2 {
        sum: float;
        if tpose sum = abs(M.coef[0][i]) + abs(M.coef[1][i]) + abs(M.coef[2][i]);
        else     sum = abs(M.coef[i][0]) + abs(M.coef[i][1]) + abs(M.coef[i][2]);
        if (max < sum) max = sum;

    }
    return max;
}

norm_inf :: #bake_arguments mat_norm(tpose=false);
norm_one :: #bake_arguments mat_norm(tpose=true);

/** Setup u for Householder reflection to zero all v components but first **/
make_reflector :: (v: Vector3) -> (u: Vector3) {
    s := sqrt(dot_product(v, v));

    u: Vector3 = ---;
    u.x = v.x;
    u.y = v.y;
    u.z = v.z + ifx v.z<0 then -s else s;

    s = sqrt(2/dot_product(u, u));

    return u * s;
}

/** Apply Householder reflection represented by u to column vectors of M **/
reflect_cols :: (M: *Matrix3, u: Vector3) {
    for i: 0..2 {
        s := u.x*M.coef[0][i] + u.y*M.coef[1][i] + u.z*M.coef[2][i];
        for j: 0..2 M.coef[j][i] -= u.component[j]*s;
    }
}

/** Apply Householder reflection represented by u to row vectors of M **/
reflect_rows :: (M: *Matrix3, u: Vector3) {
    for i: 0..2 {
        s := dot_product(u, M.v[i]);
        for j: 0..2 M.coef[i][j] -= u.component[j]*s;
    }
}


/*
/** Return index of column of M containing maximum abs entry, or -1 if M=0 **/
int find_max_col(HMatrix M)
{
    float abs, max;
    int i, j, col;
    max = 0.f; col = -1;
    for (i=0; i<3; i++) for (j=0; j<3; j++) {
    abs = M[i][j]; if (abs<0.f) abs = -abs;
    if (abs>max) {max = abs; col = j;}
    }
    return col;
}

/** Find orthogonal factor Q of rank 1 (or less) M **/
void do_rank1(HMatrix M, HMatrix Q)
{
    float v1[3], v2[3], s;
    int col;
    /* If rank(M) is 1, we should find a non-zero column in M */
    col = find_max_col(M);
    if (col<0) {mat_copy(Q,=,mat_id,4); return;} /* Rank is 0 */
    v1[0] = M[0][col]; v1[1] = M[1][col]; v1[2] = M[2][col];
    make_reflector(v1, v1); reflect_cols(M, v1);
    v2[0] = M[2][0]; v2[1] = M[2][1]; v2[2] = M[2][2];
    make_reflector(v2, v2); reflect_rows(M, v2);
    s = M[2][2];
    mat_copy(Q,=,mat_id,4);
    if (s<0.f) Q[2][2] = -1.f;
    reflect_cols(Q, v1); reflect_rows(Q, v2);
}

/** Find orthogonal factor Q of rank 2 (or less) M using adjoint transpose **/
void do_rank2(HMatrix M, HMatrix MadjT, HMatrix Q)
{
    float v1[3], v2[3];
    float w, x, y, z, c, s, d;
    int col;
    /* If rank(M) is 2, we should find a non-zero column in MadjT */
    col = find_max_col(MadjT);
    if (col<0) {do_rank1(M, Q); return;} /* Rank<2 */
    v1[0] = MadjT[0][col]; v1[1] = MadjT[1][col]; v1[2] = MadjT[2][col];
    make_reflector(v1, v1); reflect_cols(M, v1);
    vcross(M[0], M[1], v2);
    make_reflector(v2, v2); reflect_rows(M, v2);
    w = M[0][0]; x = M[0][1]; y = M[1][0]; z = M[1][1];
    if (w*z>x*y) {
    c = z+w; s = y-x; d = sqrtf(c*c+s*s); c = c/d; s = s/d;
    Q[0][0] = Q[1][1] = c; Q[0][1] = -(Q[1][0] = s);
    } else {
    c = z-w; s = y+x; d = sqrtf(c*c+s*s); c = c/d; s = s/d;
    Q[0][0] = -(Q[1][1] = c); Q[0][1] = Q[1][0] = s;
    }
    Q[0][2] = Q[2][0] = Q[1][2] = Q[2][1] = 0.f; Q[2][2] = 1.f;
    reflect_cols(Q, v1); reflect_rows(Q, v2);
}
*/


// Polar matrix decomposition.
// This returns an orthogonal matrix Q, and a matrix S such that M=Q*S.
polar_decomp :: (M: Matrix3) -> (Q: Matrix3, S: Matrix3, det: float) {  // Note: If we just made this polymorphic, it could automatically work on Matrix4 or Matrix3 arguments, and you wouldn't need to care or make an intermediate temporary variable.
    do_rank2 :: (M: *Matrix3, MadjT: Matrix3) -> Matrix3 {
        Q: Matrix3;

        v1: Vector3;

        /* If rank(M) is 2, we should find a non-zero column in MadjT */
        col := 0;//find_max_col(MadjT); // @@
        //if (col<0) {do_rank1(M, Q); return;} /* Rank<2 */

        //v1 = column(Madj, col);
        v1.x = MadjT.coef[0][col];
        v1.y = MadjT.coef[1][col];
        v1.z = MadjT.coef[2][col];
        v1 = make_reflector(v1);
        reflect_cols(M, v1);

        v2 := cross(M.v[0], M.v[1]);
        v2 = make_reflector(v2);
        reflect_rows(M, v2);

        w := M.coef[0][0];
        x := M.coef[0][1];
        y := M.coef[1][0];
        z := M.coef[1][1];
        if w*z > x*y {
            c := z+w;
            s := y-x;
            d := sqrt(c*c+s*s);
            c /= d;
            s /= d;
            Q.coef[0][0], Q.coef[1][1] = c;
            Q.coef[0][1] = -s;
            Q.coef[1][0] = s;
        } else {
            c := z-w;
            s := y+x;
            d := sqrt(c*c+s*s);
            c /= d;
            s /= d;
            Q.coef[0][0] = -c;
            Q.coef[1][1] = c;
            Q.coef[0][1], Q.coef[1][0] = s;
        }

        Q.coef[0][2], Q.coef[2][0], Q.coef[1][2], Q.coef[2][1] = 0.0;
        Q.coef[2][2] = 1.0;

        reflect_cols(*Q, v1);
        reflect_rows(*Q, v2);
        return Q;
    }

    TOL :: 1.0e-6;

    Mk := transpose(M);

    det: float;
    E_one := FLOAT32_MAX;
    M_one := norm_one(Mk);
    M_inf := norm_inf(Mk);

    while E_one > M_one*TOL {
        MadjTk := adjoint_transpose(Mk);

        det = dot(Mk.v[0], MadjTk.v[0]);
        if det == 0.0 {
            Mk = do_rank2(*Mk, MadjTk);
            break;
        }

        MadjT_one := norm_one(MadjTk);
        MadjT_inf := norm_inf(MadjTk);

        gamma := sqrt(sqrt((MadjT_one*MadjT_inf)/(M_one*M_inf))/abs(det));
        g1 := gamma * 0.5;
        g2 := 0.5 / (gamma*det);

        Ek := Mk;
        Mk = g1 * Mk + g2 * MadjTk;
        Ek -= Mk;

        E_one = norm_one(Ek);
        M_one = norm_one(Mk);
        M_inf = norm_inf(Mk);
    }

    Q := transpose(Mk);
    S := Mk * M;

    for i: 0..2 for j: 0..2 {
        S.coef[i][j] = 0.5 * (S.coef[i][j] + S.coef[j][i]);
        S.coef[j][i] = S.coef[i][j];
    }

    return Q, S, det;
}

rotation_matrix :: ($T: Type, q: Quaternion) -> T {
    m: T;

    #if T == Matrix4  m._44 = 1;

    xs := q.x * 2;
    ys := q.y * 2;
    zs := q.z * 2;

    wx := q.w * xs;
    wy := q.w * ys;
    wz := q.w * zs;

    _xx := q.x * xs;
    xy := q.x * ys;
    xz := q.x * zs;

    yy := q.y * ys;
    yz := q.y * zs;
    zz := q.z * zs;

    m._11 = 1.0 - (yy + zz);
    m._12 = xy - wz;
    m._13 = xz + wy;

    m._21 = xy + wz;
    m._22 = 1.0 - (_xx + zz);
    m._23 = yz - wx;

    m._31 = xz - wy;
    m._32 = yz + wx;
    m._33 = 1.0 - (_xx + yy);

    return m;
}

identity_of :: ($T: Type) -> T {
    result: T;
    identity(*result);
    return result;
}


identity :: (m: *$T/interface AnyMatrix) {
    // Pass a pointer to an uninitialized matrix.
    // We fill out out as the identity.

    memset(m, 0, size_of(T));
    m._11 = 1;
    m._22 = 1;

    #if T.coef.count > 2 then m._33 = 1;
    #if T == Matrix4     then m._44 = 1;
}
