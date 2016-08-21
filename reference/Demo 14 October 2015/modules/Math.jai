Vector2 :: struct {
    x, y: float;
}

Vector3 :: struct {
    x, y, z: float;
}

Vector4 :: struct {
    x, y, z, w: float;
}

Quaternion :: struct {
    x, y, z, w: float;
}


Matrix2 :: struct {
    _11, _12 : float;
    _21, _22 : float;
}

dot_product :: (a: Vector2, b: Vector2) -> float {
    return a.x*b.x + a.y*b.y;
}

dot_product :: (a: Vector3, b: Vector3) -> float {
    return a.x*b.x + a.y*b.y + a.z*b.z;
}

make_vector2 :: (x: float, y: float) -> Vector2 {
    v: Vector2;
    v.x = x;
    v.y = y;

    return v;
}

make_vector3 :: (x: float, y: float, z: float) -> Vector3 {
    v: Vector3;
    v.x = x;
    v.y = y;
    v.z = z;
    
    return v;
}

make_vector4 :: (x: float, y: float, z: float, w: float) -> Vector4 {
    v: Vector4;
    v.x = x;
    v.y = y;
    v.z = z;
    v.w = w;

    return v;
}

make_quaternion :: (x: float, y: float, z: float, w: float) -> Quaternion {
    v: Quaternion;
    v.x = x;
    v.y = y;
    v.z = z;
    v.w = w;

    return v;
}

/*
Until we have operator overloading, don't define this because
we can't use it for vectors, etc.
lerp :: (a: $R, b: R, t: float) -> R {
    return a + (b - a) * t;
}
*/

/*
floor :: (a: $T) -> T {
    // @Incomplete: Get strict about the type?
    return cast(T) cast(s64) a;
}
*/

//
// @Incomplete: We do not overload operators yet!
//

multiply :: (m: Matrix2, v: Vector2) -> Vector2 {
    x := m._11 * v.x + m._12 * v.y;
    y := m._21 * v.x + m._22 * v.y;

    return make_vector2(x, y);
}

multiply :: (v: Vector2, f: float) -> Vector2 {
    return make_vector2(v.x * f, v.y * f);
}

multiply :: (v: Vector3, f: float) -> Vector3 {
    return make_vector3(v.x*f, v.y*f, v.z*f);
}

distance :: (a: Vector3, b: Vector3) -> float {
    dx := b.x - a.x;
    dy := b.y - a.y;
    dz := b.z - a.z;

    return sqrt(dx*dx + dy*dy + dz*dz);
}


normalize_or_zero :: (using v: *Vector3) -> float {
    sq := sqrt(x*x + y*y + z*z);
    if sq == 0 return sq;

    factor := 1.0 / sq;
    x *= factor;
    y *= factor;
    z *= factor;

    return sq;
}

normalize_or_zero :: (using v: *Vector2) -> float {
    sq := sqrt(x*x + y*y);
    if sq == 0 return sq;

    factor := 1.0 / sq;
    x *= factor;
    y *= factor;

    return sq;
}

rotate :: (v: *Vector2, theta: float) {
    ct := cos(theta);
    st := sin(theta);

    x := v.x * ct + v.y * -st;
    y := v.x * st + v.y * ct;

    v.x = x;
    v.y = y;
}

add :: (a: Vector3, b: Vector3) -> Vector3 {
    return make_vector3(a.x+b.x, a.y+b.y, a.z+b.z);
}

add :: (a: Vector2, b: Vector2) -> Vector2 {
    return make_vector2(a.x+b.x, a.y+b.y);
}

subtract :: (a: Vector3, b: Vector3) -> Vector3 {
    return make_vector3(a.x-b.x, a.y-b.y, a.z-b.z);
}

cross_product :: (a: Vector3, b: Vector3) -> Vector3 {
    n: Vector3 = ---;

    n.x = a.y * b.z - a.z * b.y;
    n.y = a.z * b.x - a.x * b.z;
    n.z = a.x * b.y - a.y * b.x;

    return n;
}

rotate :: (v: Vector3, q: Quaternion) -> Vector3 {
    // For derivation, see: http://mollyrocket.com/forums/viewtopic.php?t=833&sid=3a84e00a70ccb046cfc87ac39881a3d0

    axis := make_vector3(q.x, q.y, q.z);
    t := multiply(cross_product(axis, v), 2);

    return add(v, add(multiply(t, q.w), cross_product(axis, t)));
}

FLT_DIG       ::  6;
FLT_EPSILON   ::  1.192092896e-07;
FLT_GUARD     ::  0;
FLT_MANT_DIG  ::  24;
FLT_MAX       ::  3.402823466e+38;
FLT_MAX_10_EXP::  38; 
FLT_MAX_EXP   ::  128;
FLT_MIN       ::  1.175494351e-38;
FLT_MIN_10_EXP::  -37;
FLT_MIN_EXP   ::  -125;
FLT_NORMALIZE ::  0;
FLT_RADIX     ::  2;
FLT_ROUNDS    ::  1;

F64_DIG       ::  15;                      // # of decimal digits of precision
F64_EPSILON   ::  2.2204460492503131e-016; // smallest such that 1.0+F64_EPSILON != 1.0 
F64_MANT_DIG  ::  53;                      // # of bits in mantissa 
F64_MAX       ::  1.7976931348623158e+308; // max value 
F64_MAX_10_EXP::  308;                     // max decimal exponent 
F64_MAX_EXP   ::  1024;                    // max binary exponent 
F64_MIN       ::  2.2250738585072014e-308; // min positive value 
F64_MIN_10_EXP::  -307;                    // min decimal exponent 
F64_MIN_EXP   ::  -1021;                   // min binary exponent 
F64_RADIX     ::  2;                       // exponent radix 
F64_ROUNDS    ::  1;                       // addition rounding: near 
