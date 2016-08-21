
/*

  Random_Generator stuff:

*/

RANDRANGE : u32 : 0x10000000;

// @Cleanup: Global variable!!
state: s32 = 0xbeefface;  // Could find a better default state?

random_get :: () -> u32 {
    x := state;

    hi := x / 127773;
    lo := x % 127773;

    t := 16807 * lo - 2836 * hi;
    if t <= 0 then t += 0x7fffffff;

    state = t;
    return cast(u32) t;
}

random_seed :: (new_seed : s32) {
    state = new_seed;
}

random_get_zero_to_one :: () -> float {
    randint := random_get() % RANDRANGE;
    return (cast(float) randint) / cast(float) RANDRANGE;  // @Precedence
}

random_get_within_range :: (min: float, max: float) -> float {
//       printf("=============== get_within_range %f to %f\n", min, max);
    randint := random_get() % RANDRANGE;
//       printf("       =======    randint is %d\n", randint);

//       frandint := cast(aa, float);
//       frandrange := cast(RANDRANGE, float);

//printf("randint %d, frandint %f\n", randint, frandint);
//printf("randrange %d, frandrange %f\n", RANDRANGE, frandrange);

    addition := ((cast(float) randint) / cast(float) RANDRANGE) * (max - min);

    return min + addition;
}


