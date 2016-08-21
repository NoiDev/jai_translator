#import "Basic"
#import "Print"
#import "Sort"
#import "Math"
#import "Crc"

#import "Mixer"
#import "Entity_Manager"
#import "Wav_File"
#import "Cached_Decoder"
#import "stb_vorbis"
#import "GL"

Entity_Issued_Sound :: struct {  // @Mixer
    using entity: *Entity;

    rate_scale: float = 1;
    inner_radius: float = 1;
    outer_radius: float = 10;
    volume_scale: float = 1;
    flags: u32;
    sound_category: u32;
    sound_name: string;
    sound_data: *Sound_Data;
    sound_data_if_streaming: *Sound_Data;
    pre_play_silence: float;
    repeat_start_position: s64;
    duration_total: float;
    my_time: float;
    stereo_source_left: Vector3;
    stereo_source_right: Vector3;

    my_lifetime: float = 1;
}

to_vec3 :: (v: Vector2) -> Vector3 {  // @Mixer
    return make_vector3(v.x, v.y, 0);
}

object_to_world_space :: (e: *Entity, p: Vector3) -> Vector3 {
    // @Incomplete
    // This is just here to make Mixer happy but we will not yet spatialize
    // so let's just return the point itself.

    return p;

//    q := e.orientation;
//    return add(multiply(rotate(p, q), e.scale), e.position);
}





// Here are just some simple values to give us somewhere easy
// to start with regard to looking at the compiler messages.

greeting     :: "Hello, Sailor!";

value_int   :: 99;
value_float :: 42.0;
value_bool  :: true;


// Some procedures, now.


sierpinski_cursor : Vector2;

// MISRA
sierpinski_curve :: () {
    // Half-heartedly translated from example at https://en.wikipedia.org/wiki/Sierpi%C5%84ski_curve

    line :: (name: string, x: float, y: float) {
        // We do not actually draw the line for now; this is
        // just an example!

        sierpinski_cursor.x += x;
        sierpinski_cursor.y += y;
    }

    dist : float : 0.1;
    
    sierpA :: (level: int) {
        if level <= 0 return;

        sierpA(level - 1);
        line("A", +dist, +dist);
        sierpB(level - 1);
        line("A", +2 * dist, 0);
        sierpD(level - 1);
        line("A", +dist, -dist);
        sierpA(level - 1);
    }

    sierpB :: (level: int) {
        if level <= 0 return;

        sierpB(level - 1);
        line("B", -dist, +dist);
        sierpC(level - 1);
        line("B", 0, +2 * dist);
        sierpA(level - 1);
        line("B", +dist, +dist);
        sierpB(level - 1);
    }

    sierpC :: (level: int) {
        if level <= 0 return;

        sierpC(level - 1);
        line("C", -dist, -dist);
        sierpD(level - 1);
        line("C", -2 * dist, 0);
        sierpB(level - 1);
        line("C", -dist, +dist);
        sierpC(level - 1);
    }

    sierpD :: (level: int) {
        if level <= 0 return;

        sierpD(level - 1);
        line("D", +dist, -dist);
        sierpA(level - 1);
        line("D", 0, -2 * dist);
        sierpC(level - 1);
        line("D", -dist, -dist);
        sierpD(level - 1);
    }
}


math_stuff :: () {
    factorial :: (x: int) -> int { // MISRA
        if x == 1 return 1;
        return x * factorial(x-1);
    }

    factorial_iterative :: (x: int) -> int {
        result := 1;
        for 2..x  result *= it;
        
        return result;
    }

    print("factorial(5) = %\n", factorial(5));  // MISRA
    print("factorial_iterative(5) = %\n", factorial_iterative(5));

    // MISRA
    sierpinski_curve();
}

Piece_A :: "Hello, Sailor!";
Piece_B :: "These strings are authentic, I swear.";

Pre_Hash :: struct {
    name: string;
    crc:  u64;
}

pre_hashes: [4] SOA Pre_Hash;

#run init_strings();

init_strings :: () {
    print("Initting strings.\n");

    make_pre_hash :: (index: s64, s: string) {
        crc := crc64(s);
        
        pre_hashes[index].name = s;
        pre_hashes[index].crc = crc;

        print("Computed crc %\n", formatInt(crc, base=64));
    }

    make_pre_hash(0, Piece_A);
    make_pre_hash(1, Piece_B);
    make_pre_hash(2, sprint("%  %", Piece_A, Piece_B));
    make_pre_hash(3, sprint("%  %", Piece_B, Piece_A));
}

print_strings_and_crcs :: () {
//    for pre_hashes  print("pre_hash [%] = '%' crc %\n", it_index, it.name, formatInt(it.crc, base=64));
/*
    for pre_hashes {
        hash := pre_hashes[it_index];
        print("pre_hash [%] = '%' crc %\n", it_index, hash.name, formatInt(hash.crc, base=64));
    }
*/

    for pre_hashes {
        print("index %\n", it_index);
    }
    
    for it_index : 0..pre_hashes.count-1  {
        hash := pre_hashes[it_index];
        print("pre_hash [%] = '%' crc %\n", it_index, hash.name, formatInt(hash.crc, base=64));
    }
}

main :: () {
    math_stuff();

    print_strings_and_crcs();
    
    x := 10;
    while x >= 0 {
        print("x = %\n", x);
        x -= 1;
    }

    f : float64 = 5.0;
    g : float64 = 6.0;

    epsilon : float64 = 0.0001;

    // if (f >= g - epsilon) && (f <= g + epsilon) {
    if f == g {  // MISRA
        print("f and g are the same.\n");
    } else {
        print("f and g are not the same.\n");
    }


    a := *f;
    b := *a;
    c := *b;  // MISRA

    print("f is: %\n", << << b);


    phrases: [..] string;

    array_add(*phrases, "Hello, Sailor!");
    array_add(*phrases, "hello, sailor!");
    array_add(*phrases, "Sailor, Hello!");
    array_add(*phrases, "I forgot armed robbery was against the law.");
    array_add(*phrases, "Even a stopped clock is right once a week.");
    array_add(*phrases, "This is the best pizza in a cup ever. This guy's unbelievable.");
    array_add(*phrases, "What do you care what other people think?");
    array_add(*phrases, "A bird in the hand is worth ... something.");

    bubble_sort(phrases, compare_strings);

    print("\n");
    for phrases print("%\n", it);


    numbers: [..] float;

    array_add(*numbers, 111.222);
    array_add(*numbers, -42.42);
    array_add(*numbers, 0);
    array_add(*numbers, 69105);
    array_add(*numbers, 22.0 / 7.0);
    array_add(*numbers, TAU);

    bubble_sort(numbers, compare_floats);
    
    print("\n");
    for numbers print("%\n", it);


    // Let's not bother to sort these; I just wanted another instance of array_add.
    integers: [..] int;
    array_add(*integers, 3);
    array_add(*integers, 2);
    array_add(*integers, 1);

    
    print("\n");
}
