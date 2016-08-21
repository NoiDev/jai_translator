bubble_sort :: (array: [] $T, f: (T, T) -> s64) {
    count := array.count;

    last_j := count-2;
    first_j := 0;
    
    while true {
        latest_swap := -1;
        first_swap  := -1;
        for j : first_j..last_j {
            a := array[j];
            b := array[j+1];

            compare := f(a, b);
            if compare > 0 {
                array[j]   = b;
                array[j+1] = a;
                latest_swap = j;
                if first_swap == -1  first_swap = j;
            }
        }

        if latest_swap == -1 return;
        // assert(latest_swap <= last_j);
        last_j = latest_swap - 1;
        first_j = max(first_swap-1, 0);
    }
}


    helper :: (a: *$T, n: s64, f: (T, T) -> s64) {
        if n < 2 return;

        p := a[n / 2];

        i := 0;
        j := n-1;

        while true {
            while f(a[i], p) < 0  {i += 1;}
            while f(p, a[j]) < 0  {j -= 1;}

            if i >= j break;

            t := a[i];
            a[i] = a[j];
            a[j] = t;

            i += 1;
            j -= 1;
        }
        
        helper(a, i, f);
        helper(a + i, n - i, f);
    }
quick_sort :: (array: [] $T, f: (T, T) -> s64) {

    helper(array.data, array.count, f);
}

/*
compare_strings :: (a: string, b: string) -> s64 {
    delta := a.count - b.count;
    if delta return delta;

    for 0..a.count-1 {
        delta := cast(s64) a[it] - cast(s64) b[it];
        if delta return delta;
    }

    return 0;
}
*/

compare_floats :: (a: float, b: float) -> s64 {
    delta := a - b;
    if delta < 0 return -1;
    if delta > 0 return  1;
    return 0;
}

compare_strings :: (a: string, b: string) -> s64 {
    for 0..a.count-1 {
        if it >= b.count return 1;
        
        delta := cast(s64) a[it] - cast(s64) b[it];
        if delta return delta;
    }

    if b.count > a.count return -1;
    return 0;
}

