#foreign_library "stb_vorbis"

// From stb_vorbis.cpp:

// int stb_vorbis_decode_filename(const char *filename, int *channels, int *sample_rate, short **output);
// void stb_vorbis_close(stb_vorbis *f);

// int stb_vorbis_seek(stb_vorbis *f, unsigned int sample_number);

// stb_vorbis * stb_vorbis_open_memory(const unsigned char *data, int len,
//                                  int *error, stb_vorbis_alloc *alloc_buffer);

// unsigned int stb_vorbis_stream_length_in_samples(stb_vorbis *f);

// int stb_vorbis_get_samples_short_interleaved(stb_vorbis *f, int channels, short *buffer, int num_shorts);


stb_vorbis       :: struct {}

stb_vorbis_alloc :: struct { 
    // @Incomplete: Fill this out so people can use it.
}

stb_vorbis_decode_filename :: (filename: *u8, channels: *s32, sample_rate: *s32, output: **s16) -> s32 #foreign;

stb_vorbis_close :: (f: *stb_vorbis) #foreign;
stb_vorbis_seek  :: (f: *stb_vorbis, sample_number: u32) -> s32 #foreign;

stb_vorbis_open_memory :: (data: *void, len: s32,
                           error: *s32, alloc_buffer: *stb_vorbis_alloc) -> *stb_vorbis #foreign;


stb_vorbis_stream_length_in_samples :: (f: *stb_vorbis) -> u32 #foreign;

stb_vorbis_get_samples_short_interleaved :: (f: *stb_vorbis, channels: s32, buffer: *s16, num_shorts: s32) -> s32 #foreign;
