/*
  The Pool is a memory allocator that you can use when you want to
  quickly allocate memory blocks of many different sizes, but all
  those blocks will have approximately the same lifetime.
  With a Pool, you allocate and allocate but you never deallocate
  until you are done with everything; at that time, you deallocate
  the entire Pool at once.
 */

POOL_BUCKET_SIZE_DEFAULT      :: 65536;
POOL_OUT_OF_BAND_SIZE_DEFAULT :: 6554;

pop :: (array: *[..] $T) -> T {
    if array.count == 0 {    // @Cleanup: Should be able to say array.count
        print("Panic: Attempt to pop an empty array.\n");
        assert(false);
        return null;
    }

    result := (<< array)[array.count-1];
    array.count -= 1;

    return result;
}


Pool :: struct {
    memblock_size:    s64 = POOL_BUCKET_SIZE_DEFAULT;
    out_of_band_size: s64 = POOL_OUT_OF_BAND_SIZE_DEFAULT;
    alignment := 8;

    unused_memblocks        : [..] *u8;
    used_memblocks          : [..] *u8;
    out_of_band_allocations : [..] *u8;

    current_memblock : *u8;
    current_pos      : *u8;
    bytes_left       : s64;

    block_allocator      : Allocator;
    block_allocator_data : *void;
};

set_allocators :: (pool: *Pool, 
                   block_allocator      : Allocator = null,
                   block_allocator_data : *void     = null,
                   array_allocator      : Allocator = null,
                   array_allocator_data : *void     = null) {

    if !block_allocator {
        block_allocator      = context.allocator;
        block_allocator_data = context.allocator_data;
    }

    if !array_allocator {
        array_allocator      = context.allocator;
        array_allocator_data = context.allocator_data;
    }

    pool.block_allocator      = block_allocator;
    pool.block_allocator_data = block_allocator_data;

    pool.   unused_memblocks.allocator = array_allocator;
    pool.     used_memblocks.allocator = array_allocator;

    pool.out_of_band_allocations.allocator = array_allocator;

    pool.   unused_memblocks.allocator_data = array_allocator_data;
    pool.     used_memblocks.allocator_data = array_allocator_data;

    pool.out_of_band_allocations.allocator_data = array_allocator_data;
}


// These are the things you may want to call:

get :: (using pool: *Pool, nbytes: s64) -> *void {
    extra := alignment - (nbytes % alignment); 
    nbytes += extra; 

    if nbytes >= out_of_band_size {
        assert(block_allocator != null);
        memory := block_allocator(Allocator_Mode.ALLOCATE, memblock_size, 0, null, block_allocator_data, 0);
        if memory array_add(*out_of_band_allocations, memory);
        return memory;
    }

    if bytes_left < nbytes {
        cycle_new_block(pool);
        if !current_memblock return null;
    }

    retval := current_pos;
    current_pos += nbytes; 
    bytes_left  -= nbytes; 
 
    return retval; 
}

release :: (using pool: *Pool) {
    reset(pool);

    for pool.unused_memblocks free(it);
}


reset :: (using pool: *Pool) {
    if current_memblock {
        array_add(*unused_memblocks, current_memblock);
	    current_memblock = null;
    }

    for used_memblocks array_add(*unused_memblocks, it);
    used_memblocks.count = 0;

    for out_of_band_allocations free(it);
    out_of_band_allocations.count = 0;
}


//
// The stuff below is 'private':
//

cycle_new_block :: (using pool: *Pool) {
    if !block_allocator {
        print("You must call set_allocators on a Pool before using it!\n");
        assert(false);
    }

    if current_memblock {
        array_add(*used_memblocks, current_memblock);
    }

    new_block : *u8;
    if (unused_memblocks.count) {
        new_block = pop(*unused_memblocks);
    } else {
        assert(pool.block_allocator != null);
        new_block = block_allocator(Allocator_Mode.ALLOCATE, memblock_size, 0, null, block_allocator_data, 0);
    }

    bytes_left = memblock_size;
    current_pos = new_block;
    current_memblock = new_block;
}

