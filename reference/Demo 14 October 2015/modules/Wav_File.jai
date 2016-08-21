Waveformatex :: struct {
    wFormatTag       : s16;
    nChannels        : s16;
    nSamplesPerSec   : s32;
    nAvgBytesPerSec  : s32;
    nBlockAlign      : s16;
    wBitsPerSample   : s16;
    cbSize           : s16;
}

Wave_Extra_Info :: struct {
    wSamplesPerBlock : s32;  // Used for IMA ADPCM only.
    wSamplesAccordingToFactChunk: s32;
}

WAVE_FORMAT_PCM       :: 0x0001;
WAVE_FORMAT_DVI_ADPCM :: 0x0011;


big_endian :: () -> bool {
    x : s16 = 1;

    b : *u8 = cast(*u8) *x;

    if b[0] return false;
    return true;
}

swap2 :: (value: *s16) {
    data: *u8 = cast(*u8) value;

    // @Speed: Maybe we should do it the way I usually
    // do it in C++, with one read and one write, but
    // bit operations are a pain right now. So.

    b0 := data[0];
    b1 := data[1];

    data[0] = b1;
    data[1] = b0;
}

swap4 :: (value: *s32) {
    data: *u8 = cast(*u8) value;

    // @Speed: Maybe we should do it the way I usually
    // do it in C++, with one read and one write, but
    // bit operations are a pain right now. So.

    b0 := data[0];
    b1 := data[1];
    b2 := data[2];
    b3 := data[3];

    data[0] = b3;
    data[1] = b2;
    data[2] = b1;
    data[3] = b0;
}

chunk_id_matches :: (data: string, id: string) -> bool {
    assert(id.count   >= 4);
    assert(data.count >= 4);

    result := memcmp(data.data, id.data, 4);
    return result == 0;
}

read_chunk_size :: (data: string) -> s32, bool {
    if data.count < 4 return 0, false;

    value := << cast(*s32) data.data;
    if big_endian() swap4(*value);  // @Speed: Calling big_endian() all the time. We should have a directive.

    return value, true;
}

read_u4b :: (data: string) -> s32, bool {   // @Cutnpaste from read_chunk_size.
    if data.count < 4 return 0, false;

    value := << cast(*s32) data.data;
    if big_endian() swap4(*value);  // @Speed: Calling big_endian() all the time. We should have a directive.

    return value, true;
}

read_u2b :: (data: string) -> s16, bool {   // @Cutnpaste from read_chunk_size.
    if data.count < 2 return 0, false;

    value := << cast(*s16) data.data;
    if big_endian() swap2(*value);  // @Speed: Calling big_endian() all the time. We should have a directive.

    return value, true;
}

advance :: (s: *string, amount: s64) {
    assert(amount >= 0);
    assert(s.count >= amount);

    s.count -= amount;
    s.data += amount;
}

print_bytes :: (data:*u8, count: int) {
    for 0..count-1 {
        print("% ", formatInt(data[it], base=16));
    }

    print("\n");
}

parse_waveformatex :: (data: string) -> Waveformatex, bool, Wave_Extra_Info {
    format: Waveformatex;
    extra:  Wave_Extra_Info;

    WFMTEX_SIZE :: 16;
    // WFMTEX_SIZE_NEWLY_EXTENDED :: 18;

    size := WFMTEX_SIZE;
    if data.count < size return format, false, extra;  // No room.

    memcpy(*format, data.data, size);

    print_bytes(data.data, 20);

    if big_endian() {
        swap2(*format.wFormatTag);
        swap2(*format.nChannels);
        swap4(*format.nSamplesPerSec);
        swap4(*format.nAvgBytesPerSec);
        swap2(*format.nBlockAlign);
        swap2(*format.wBitsPerSample);
        swap2(*format.cbSize);
    }


    if format.wFormatTag == WAVE_FORMAT_PCM {
    } else if format.wFormatTag == WAVE_FORMAT_DVI_ADPCM {
        ok := false;
        cursor := data;
        advance(*cursor, WFMTEX_SIZE + 2);  // Advance to the end of the standard wav header.

        extra.wSamplesPerBlock, ok = read_u2b(cursor);
       // print("********** ok is %, extra.wSamplesPerBlock = %, nBlockAlign is %\n", ok, extra.wSamplesPerBlock, format.nBlockAlign);
    } else {
        return format, false, extra;
    }

    // x : s16 = 1;
    // y : s16 = x;
    // swap2(*y);

    // print("Channels: %, samples per second: %, bits per sample: %\n", 
    // format.nChannels, format.nSamplesPerSec, format.wBitsPerSample);

    return format, true, extra;
}

get_wav_header :: (file_data: string) -> (format: Waveformatex, samples: string, success: bool = false, extra : Wave_Extra_Info) {
    format: Waveformatex;
    extra:  Wave_Extra_Info;

    samples: string;

    cursor := file_data;

    if cursor.count < 12 return format, samples, false, extra;

    success := chunk_id_matches(cursor, "RIFF");
    if !success return format, samples, false, extra;

    advance(*cursor, 4);

    chunk_size, chunk_success := read_chunk_size(cursor);
    if chunk_size < 8 return format, samples, false, extra;

    advance(*cursor, 4);

    if cursor.count < chunk_size return format, samples, false, extra;  // Invalid!
    cursor.count = chunk_size;   // Restrict us to what is in this chunk.

    success = chunk_id_matches(cursor, "WAVE");
    if !success return format, samples, false, extra;

    advance(*cursor, 4);

    //
    // We could have any of several different chunk types.
    // Let's skip what we don't care about.
    //

    valid := false;
    while true {
        if cursor.count < 8 break;

        name := cursor;
        advance(*cursor, 4);

        chunk_size, success := read_chunk_size(cursor);
        advance(*cursor, 4);

        if !success break;
        if chunk_size > cursor.count return format, samples, false, extra;

        if chunk_id_matches(name, "fmt ") {
            chunk := cursor;
            chunk.count = chunk_size;

            format, success, extra = parse_waveformatex(cursor);
            if (!success) return format, samples, false, extra;
        } else if chunk_id_matches(name, "data") {
            samples = cursor;
            samples.count = chunk_size;

            // return format, samples, true, extra;
        } else if chunk_id_matches(name, "cue ") {
        } else if (chunk_id_matches(name, "fact")) {
            // We don't want to increment data or increase len, because
            // we use them to jump to the next chunk, at the bottom of the loop!
            sample_count, success := read_u4b(cursor);
            print("FACT chunk says % samples.\n", sample_count);
            extra.wSamplesAccordingToFactChunk = sample_count;
            if !success return format, samples, false, extra;
        } else {
            // It was a chunk we didn't understand.
        }
	
        advance(*cursor, chunk_size);
    }

    return format, samples, true, extra;
}

