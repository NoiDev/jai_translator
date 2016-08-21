/*

  Note: Code compressed with this ADPCM encoder will play back incorrectly in vlc
  and other players that use libavcodec, and if you compress an ADPCM file with
  someone that uses libavcodec (like ffmpeg), you will get something that will
  play back in-game incorrectly (it will have clicking and other noise), so
  don't do it!

  The reason is because libavcodec's adpcm handling is buggy, and ffmpeg has
  additional problems in wav packaging (for example, ffmpeg outputs an incorrect 
  'fact' chunk.) However, every other audio program we have tested agrees with the 
  adpcm compression here, and it plays back correctly in Windows Media Player and
  on iOS. So the conclusion is that ffmpeg is just wrong and buggy.

  Trying to move data in the opposite direction has the same problem. So, sorry,
  you can't make adpcm files with ffmpeg and play them here and have them come
  out properly. Take it up with the ffmpeg people and/or the libavcodec people
  and get them to fix their junk.

           -jblow, 2 October 2015.

*/

ADPCM_CHANNELS_MAX :: 9;  // Maybe it is an 8.1 sound?

Adpcm_Info :: struct {
    nChannels:        s32;
    nBlockAlign:      s32;
    wSamplesPerBlock: s32;
};

ADPCM_State :: struct {
    sample: s32;
    index:  s8;
};

IMA_ADPCM_decode :: (info: Adpcm_Info, block_start: *u8, block_len: s64,    // @Cleanup: block_start + block_len should possibly just be a string?
                     dest: *u8, dest_bytes_needed: s64, dest_len_including_waste: s64) -> s32 
{
    channels         := info.nChannels;
    nBlockAlign      := info.nBlockAlign;
    wSamplesPerBlock := info.wSamplesPerBlock;
    
    assert((dest_len_including_waste % (2 * channels)) == 0);
    assert((dest_bytes_needed        % (2 * channels)) == 0);

    /* Check to make sure we have enough variables in the state array */

    assert(channels <= ADPCM_CHANNELS_MAX);

    /* Allocate the proper sized output buffer */
    encoded_len := block_len;
    encoded     := block_start;

    decoded_length_max := (encoded_len / nBlockAlign) *
        wSamplesPerBlock *
        channels * size_of(s16);

    decoded := dest;
    decoded_orig := decoded;


    decode_state: [ADPCM_CHANNELS_MAX] ADPCM_State = ---;

    /* Get ready... Go! */
    while (encoded_len >= nBlockAlign) || (encoded_len == channels * 2) {  // The second case is if we have EXTRA_TRAILING_SAMPLES == 1. Easy to fill that one without putting an if in the main decoder loop.
        /* Grab the initial information for this block */
        for c : 0..channels-1 {
            state := *decode_state[c];

            /* Fill the state information for this block */
            state.sample = ((cast(s16) encoded[1]) << 8) | encoded[0];
            encoded += 2;

            state.index = cast(s8) <<encoded;
            encoded += 1;
            /* Reserved byte in buffer header, should be 0 */
            if ((<<encoded) != 0) {
                /* Uh oh, corrupt data?  Buggy code? */ ;
            }
            encoded += 1;

            /* Store the initial sample we start with */
            decoded[0] = cast (u8) (state.sample & 0xFF);
            decoded[1] = cast (u8) (state.sample >> 8) & 0xFF;  // @Cleanup: & 0xFF is unnecessary?
            decoded += 2;
        }

        if encoded_len == channels * 2  break;   // We may break here for EXTRA_TRAILING_SAMPLES.

        /* Decode and store the other samples in this block */
        samplesleft := (wSamplesPerBlock - 1) * channels;
        while samplesleft > 0 {
            // if ((decoded - decoded_orig) >= dest_bytes_needed) break;   // @Speed

            for c : 0..channels-1 {
                Fill_IMA_ADPCM_block(decoded, encoded,
                                     c, channels, *decode_state[c]);
                encoded += 4;
                samplesleft -= 8;
            }

            decoded += channels * 8 * 2;
        }

        encoded_len -= nBlockAlign;
    }

    decoded_bytes := decoded - decoded_orig;
    assert(decoded_bytes <= dest_len_including_waste);

    return cast(s32) decoded_bytes;
}



step_table : [89] s32;

#run init_step_table();
init_step_table :: () {
    // @Cleanup! We need us some array literals!
    // When we get array literals, let's re-copy the step_table
    // from Adpcm_Decoder.cpp in The Witness rather than reconstructing
    // this horrible thing.   -jblow, 27 September 2015

    index := 0;

    step_table[index] = 7;
    index += 1; step_table[index] = 8;
    index += 1; step_table[index] = 9;
    index += 1; step_table[index] = 10;
    index += 1; step_table[index] = 11;
    index += 1; step_table[index] = 12;
    index += 1; step_table[index] = 13;
    index += 1; step_table[index] = 14;
    index += 1; step_table[index] = 16;
    index += 1; step_table[index] = 17;
    index += 1; step_table[index] = 19;
    index += 1; step_table[index] = 21;
    index += 1; step_table[index] = 23;
    index += 1; step_table[index] = 25;
    index += 1; step_table[index] = 28;
    index += 1; step_table[index] = 31;
    index += 1; step_table[index] = 34;
    index += 1; step_table[index] = 37;
    index += 1; step_table[index] = 41;
    index += 1; step_table[index] = 45;
    index += 1; step_table[index] = 50;
    index += 1; step_table[index] = 55;
    index += 1; step_table[index] = 60;
    index += 1; step_table[index] = 66;
    index += 1; step_table[index] = 73;
    index += 1; step_table[index] = 80;
    index += 1; step_table[index] = 88;
    index += 1; step_table[index] = 97;
    index += 1; step_table[index] = 107;
    index += 1; step_table[index] = 118;
    index += 1; step_table[index] = 130;
    index += 1; step_table[index] = 143;
    index += 1; step_table[index] = 157;
    index += 1; step_table[index] = 173;
    index += 1; step_table[index] = 190;
    index += 1; step_table[index] = 209;
    index += 1; step_table[index] = 230;
    index += 1; step_table[index] = 253;
    index += 1; step_table[index] = 279;
    index += 1; step_table[index] = 307;
    index += 1; step_table[index] = 337;
    index += 1; step_table[index] = 371;
    index += 1; step_table[index] = 408;
    index += 1; step_table[index] = 449;
    index += 1; step_table[index] = 494;
    index += 1; step_table[index] = 544;
    index += 1; step_table[index] = 598;
    index += 1; step_table[index] = 658;
    index += 1; step_table[index] = 724;
    index += 1; step_table[index] = 796;
    index += 1; step_table[index] = 876;
    index += 1; step_table[index] = 963;
    index += 1; step_table[index] = 1060;
    index += 1; step_table[index] = 1166;
    index += 1; step_table[index] = 1282;
    index += 1; step_table[index] = 1411;
    index += 1; step_table[index] = 1552;
    index += 1; step_table[index] = 1707;
    index += 1; step_table[index] = 1878;
    index += 1; step_table[index] = 2066;
    index += 1; step_table[index] = 2272;
    index += 1; step_table[index] = 2499;
    index += 1; step_table[index] = 2749;
    index += 1; step_table[index] = 3024;
    index += 1; step_table[index] = 3327;
    index += 1; step_table[index] = 3660;
    index += 1; step_table[index] = 4026;
    index += 1; step_table[index] = 4428;
    index += 1; step_table[index] = 4871;
    index += 1; step_table[index] = 5358;
    index += 1; step_table[index] = 5894;
    index += 1; step_table[index] = 6484;
    index += 1; step_table[index] = 7132;
    index += 1; step_table[index] = 7845;
    index += 1; step_table[index] = 8630;
    index += 1; step_table[index] = 9493;
    index += 1; step_table[index] = 10442;
    index += 1; step_table[index] = 11487;
    index += 1; step_table[index] = 12635;
    index += 1; step_table[index] = 13899;
    index += 1; step_table[index] = 15289;
    index += 1; step_table[index] = 16818;
    index += 1; step_table[index] = 18500;
    index += 1; step_table[index] = 20350;
    index += 1; step_table[index] = 22385;
    index += 1; step_table[index] = 24623;
    index += 1; step_table[index] = 27086;
    index += 1; step_table[index] = 29794;
    index += 1; step_table[index] = 32767;

    assert(index == 89 - 1);
};

index_table: [16] s8;

#run init_index_table();
init_index_table :: () {
    i := 0;

    index_table[i] = -1;
    i += 1; index_table[i] = -1;
    i += 1; index_table[i] = -1;
    i += 1; index_table[i] = -1;
    i += 1; index_table[i] = 2;
    i += 1; index_table[i] = 4;
    i += 1; index_table[i] = 6;
    i += 1; index_table[i] = 8;
    i += 1; index_table[i] = -1;
    i += 1; index_table[i] = -1;
    i += 1; index_table[i] = -1;
    i += 1; index_table[i] = -1;
    i += 1; index_table[i] = 2;
    i += 1; index_table[i] = 4;
    i += 1; index_table[i] = 6;
    i += 1; index_table[i] = 8;

    assert(i == 16 - 1);
};

IMA_ADPCM_nibble :: (state: *ADPCM_State, nybble: u8) -> s32 {
    max_audioval : s32 = ((1 << (16 - 1)) - 1);
    min_audioval : s32 = -(1 << (16 - 1));
    delta, step: s32;

    /* Compute difference and new sample value */
    if state.index > 88 {
        state.index = 88;
    } else if state.index < 0 {
        state.index = 0;
    }

    step = step_table[state.index];
    delta = step >> 3;
    if nybble & 0x04
        delta += step;
    if nybble & 0x02
        delta += (step >> 1);
    if nybble & 0x01
        delta += (step >> 2);
    if nybble & 0x08
        delta = -delta;
    state.sample += delta;

    /* Update index value */
    state.index += index_table[nybble];

    /* Clamp output sample */
    if state.sample > max_audioval {
        state.sample = max_audioval;
    } else if state.sample < min_audioval {
        state.sample = min_audioval;
    }

    return state.sample;
}


/* Fill the decode buffer with a channel block of data (8 samples) */
Fill_IMA_ADPCM_block :: (decoded: *u8, encoded: *u8,
                         channel: s64, numchannels: s64,
                         state: *ADPCM_State) {

    decoded += (channel * 2);
    for i : 0..3 {
        nybble := (<<encoded) & 0x0F;  // @CheckMe
        new_sample := IMA_ADPCM_nibble(state, nybble);
        decoded[0] = cast(u8)(new_sample & 0xFF);
        new_sample = new_sample >> 8;
        // new_sample >>= 8;  // @Incomplete: Need >>= operator.
        decoded[1] = cast(u8) (new_sample & 0xFF);
        decoded += 2 * numchannels;

        nybble = (<<encoded) >> 4;
        new_sample = IMA_ADPCM_nibble(state, nybble);
        decoded[0] = cast(u8) (new_sample & 0xFF);
        new_sample = new_sample >> 8;
        // new_sample >>= 8;  // @Incomplete: Need >>= operator.
        decoded[1] = cast(u8) (new_sample & 0xFF);
        decoded += 2 * numchannels;

        encoded += 1;
    }
}
