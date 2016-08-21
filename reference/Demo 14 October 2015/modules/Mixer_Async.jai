/*

All code in this file must be threadsafe.

Be careful reading local variables!

Do not call procedures outside this file unless they are vetted!

 */

TEST_K :: 1.0;
DELTA_RATE_MAX :: #run { 18.0 * (1.0 / 40000.0) * TEST_K; };
DELTA_RATE_MIN :: #run { -DELTA_RATE_MAX; };

TYPICAL_NEEDED_SAMPLES  :: #run { cast(s64) (OUTPUT_SAMPLING_RATE * DEFAULT_FILL_AHEAD_TIME) * 2; };
ACCUMULATOR_SAMPLES_MAX :: #run { OUTPUT_SAMPLING_RATE / 2; };

the_accumulator: [ACCUMULATOR_SAMPLES_MAX] Audio_Dest_Sample;
accumulator_element_size :: #run { size_of(Audio_Dest_Sample); };

Clamp :: (pointer: *$T, low: T, high: T) {
    if <<pointer < low   { <<pointer = low; };
    if <<pointer > high  { <<pointer = high; };
}

lerp :: (a: float, b: float, t: float) -> float { // @Cleanup: When we have operator overloading, put lerp in Math.jai
    return a + (b - a) * t;
}


/*
  Sound_Data is a record for a single loaded sound effect.
*/

load :: (using sound_data: *Sound_Data, data: string) -> bool {  // Load a raw asset.
    // @Incomplete
    assert(false);
    return false;
}

unload :: (using sound_data: *Sound_Data) {
    assert(false);  // @Incomplete
}

destroy :: (using sound_data: *Sound_Data) {
    assert(false);  // @Incomplete
}

Sound_Data :: struct {
    Type :: enum {
        UNINITIALIZED,
        LINEAR_SAMPLE_ARRAY,
        OGG_COMPRESSED,
        ADPCM_COMPRESSED
    };

    type := Type.UNINITIALIZED;

    name: string;
    nsamples_times_nchannels : s64;   // How many samples long is this effect?   (a stereo sample actually counts as 2 here, against the convention the sound player uses... confusing!  @Cleanup)

    nchannels: u16 = 1;       // How many channels are in this effect?
    sampling_rate: u32 = 44100;

    // Note that each sample counted in 'nsamples' is a mono sample.
    // So a 1-second long, stereo sound effect will have a value of
    // 'nsamples' that is twice that of a 1-second long, mono sound effect.

    buffer: string;      // buffer where the sound data is stored (this class owns this buffer)
    samples: *s16;       // points where sound sample data is inside buffer_ptr (treat this as (void *) if OGG_COMPRESSED ())
    

    volume_scale : float = 1;  // This is in perceptual units; 2.0 means "sounds twice as loud".
    inner_radius : float = SOUND_INNER_RADIUS_DEFAULT;
    outer_radius : float = SOUND_OUTER_RADIUS_DEFAULT;
    random_volume : float = 0;
    random_pitch : float = 0;
    silence_before_repeat : float = 0;

	//
	// If streaming:
	//

	filename_to_stream_from : string;
    source_directions: [MAX_CHANNELS_PER_SOUND] Sound_Source_Directions.strict;

    nBlockAlign : s32 = 0;       // Copied from the wave format.
    wSamplesPerBlock : s32 = 0;  // Copied from the wave format.

    got_tweaks := false;
};

Buffer_Bounds :: struct {
    start, end: s64;
    memory: *void;
};

get_buffer_bounds :: (stream: *Sound_Stream, data: *Sound_Data, index: s64, result: *Buffer_Bounds) -> success: bool , no_overflow: bool {  // @Cleanup: Eliminate 'no_overflow'.
    if stream.decoder {
        // print("decoder on % index %\n", data.name, index);

        extra_samples: int;
        success, start, end, memory := find_page_containing_cursor(stream.decoder, index);
        if !success return false, false;

        result.start = start;
        result.end = end;
        result.memory = memory;

        return success, true;
    } else {
        result.start = 0;
        result.end = data.nsamples_times_nchannels / data.nchannels;
        result.memory = cast(*void)data.samples;

        return true, true;
    }
}


add :: (v0: *Audio_Sample_Base, v1: *Audio_Sample_Base, nchannels: s64) -> Audio_Sample_Base {
    result: Audio_Sample_Base = ---;

    for 0..nchannels-1
        result.channels[it] = v0.channels[it] + v1.channels[it];

    return result;
}

plus_equals :: (v0: *Audio_Sample_Base, v1: *Audio_Sample_Base, nchannels: s64) {
    for 0..nchannels-1
        v0.channels[it] += v1.channels[it];
}

multiply :: (v0: *Audio_Sample_Base, v1: *Audio_Sample_Base) -> Audio_Sample_Base {
    result: Audio_Sample_Base;

    for v0.channels
        result.channels[it_index] = it * v1.channels[it_index];

    return result;
}

multiply :: (v0: *Audio_Sample_Base, k: float) -> Audio_Sample_Base {
    result: Audio_Sample_Base;

    for v0.channels
        result.channels[it_index] = it * k;

    return result;
}

multiply :: (k: float, v0: *Audio_Sample_Base) -> Audio_Sample_Base {
    return multiply(v0, k);
}

times_equals :: (v0: *Audio_Sample_Base, k: float) {
    for v0.channels
        v0.channels[it_index] *= k;
}


/*
sine_offset :s64= 0;

do_sine_wave :: (dest: *s16, num_samples: int, player: *Sound_Player) {
    amplitude := 8000.0;
    omega := 100.0;

    b := player.handler.fill_buffer_size_in_bytes / (2 * 2);
    for i: 0..num_samples-1 {
        t := cast(float)sine_offset / cast(float)b;

        fresult := amplitude * cos(omega * t * 2 * 3.1415926);
        result := cast(s16) fresult;

        dest[i*2 + 0] = result;
        dest[i*2 + 1] = result;

        sine_offset += 1;
    }

    if sine_offset > b sine_offset -= b;  // It's a precision thing, so the sine wave doesn't degrade.
}
*/


get_icursor_and_remainder :: (source_cursor: float64) -> icursor: s64, remainder: float64 {
    icursor   := cast(s64) floor(source_cursor);
    remainder := source_cursor - icursor;

//    assert(remainder >= 0);

    return icursor, remainder;
}

sample_n_channels :: (stream: *Sound_Stream, samples: *s16, page_start: s64, page_end: s64, source_cursor: float64, samples_return: [] float, no_overflow: bool) {
    nchannels := stream.num_channels;

    icursor, remainder := get_icursor_and_remainder(source_cursor);

    //assert(icursor >= page_start);
    //assert(icursor < page_end);

    icursor -= page_start;
    page_size := page_end - page_start;


    i_0 := icursor;
    i_1 := icursor+1;

    if (i_1 >= page_size) && no_overflow  i_1 = i_0;

    for k : 0..nchannels-1 {
        s0 := cast(float) samples[i_0 * nchannels + k];
        s1 := cast(float) samples[i_1 * nchannels + k];

        s := lerp(s0, s1, cast(float) remainder);

        samples_return[k] = s;
    }
}

mix_sample_into_output_streams :: (player: *Sound_Player, stream: *Sound_Stream, source: *Audio_Source_Sample, dest: *Audio_Dest_Sample) {
    for i : 0..stream.num_channels-1 {

        source_value := source.channels[i];
        target := *stream.input_scale_mappings[i];

        for j : 0..player.handler.num_channels-1 {
            factor := source_value * target.interpolated_source_scale_for_this_output_index[j];
            
            if i == 0 {
                dest.channels[j] = factor;
            } else {
                dest.channels[j] += factor;
            }

            target.interpolated_source_scale_for_this_output_index[j] += target.dvolume_dsample[j];
        }
    }
}

maybe_wrap_play_cursor :: (stream: *Sound_Stream) {
    if !(stream.flags & Sound_Stream.REPEATING) return;
    
    data := stream.sound_data;
    t := stream.play_cursor;

    if (t > 0) && stream.repeat_end_position && ((cast(s64) t) >= stream.repeat_end_position) {
        t = fmod(t, cast(float64) stream.repeat_end_position);
        t += cast(float64) stream.repeat_start_position;
        stream.play_cursor = t;
    }
}

catch_up_volumes :: (handler: *Sound_Handler, stream: *Sound_Stream) {
    for i : 0..stream.num_channels-1 {
        target := *stream.input_scale_mappings[i];

        for j : 0..handler.num_channels {
            goal := target.source_scale_for_this_output_index[j];
            target.interpolated_source_scale_for_this_output_index[j] = goal;
        }
    }
}

accumulate_buffer_f :: (using player: *Sound_Player, accumulator: *Audio_Dest_Sample, num_samples: s64, source_cursor: float64,
                        page: *void, page_start: s64, page_end: s64,
                        stream: *Sound_Stream, no_overflow: bool) -> (cursor: float64, samples_written: s64) {

    if num_samples == 0 return source_cursor, 0;
    // assert(num_samples > 0);

    if (stream.silent_this_frame) {
        stream.current_rate = stream.desired_rate;

        // play_cursor is handled upon return!   stream.play_cursor += num_samples * stream.current_rate;
        // maybe_wrap_play_cursor(stream);

        catch_up_volumes(player.handler, stream);

        stream.samples_streamed_since_entity_update += num_samples;

        fnum_samples := cast(float) num_samples;
        if stream.current_rate < 0 {
            return source_cursor - fnum_samples * stream.current_rate, num_samples;  // @Robustness: Set various 'last_sample_output', etc stuff?
        } else {
            return source_cursor + fnum_samples * stream.current_rate, num_samples;  // @Robustness: Set various 'last_sample_output', etc stuff?
        }
    }

    samples := cast(*s16) page;

    //float K0 = 0, K1 = 0, K2 = 0;
    //int use_filter = 0;

/*
  Left this commented in as an example of how to turn on the filter.

    if (stream.universe == UNIVERSE_PARALLEL) {
        float psi = (300.0f / 44100.0f) * 2 * M_PI;
        float B = (90.0f / 44100.0f) * 2 * M_PI;
        float R = 1 - B / 2;
        float cos_theta = ((2*R) / (1 + R*R)) * cos(psi);
        float sin_theta = sqrt(fabs(1.0f - (cos_theta * cos_theta)));
        float gain = (1 - R*R) * sin_theta;
        

        gain *= 4;

        K0 = gain;
        K1 = 2 * R * cos_theta;
        K2 = -R*R;

        use_filter = 1;
    }
*/

/*
    Audio_Dest_Sample x0, x1, x2;
    Audio_Dest_Sample y0, y1, y2;

    x0 = stream.x0;
    x1 = stream.x1;
        
    y0 = stream.y0;
    y1 = stream.y1;

*/

    rate := stream.current_rate;
    delta_rate := stream.desired_rate - stream.current_rate;


    if stream.flags & Sound_Stream.PAUSED_DUE_TO_MENU {
        // Insta-stop without rate cooldown...

        stream.current_rate = 0;
        delta_rate = 0;
        rate = 0;

        stream.flags |= Sound_Stream.WAS_PAUSED_DUE_TO_MENU;
        catch_up_volumes(player.handler, stream);
    } else {
        if stream.flags & Sound_Stream.WAS_PAUSED_DUE_TO_MENU {
            // Insta-start without warmup.
            stream.current_rate = stream.desired_rate;
            rate = stream.current_rate;
            delta_rate = 0;

            stream.flags &= ~Sound_Stream.WAS_PAUSED_DUE_TO_MENU;
        }
    }

    drate_dsample := delta_rate / num_samples;
    Clamp(*drate_dsample, DELTA_RATE_MIN, DELTA_RATE_MAX);

    dcursor_dsample := rate;
    ddcursor_dsample := drate_dsample;
    


/*
    double delta_scale = desired_scale - scale;

    float dscale_dsample = delta_scale / num_samples;
    if (stream.flags & Sound_Stream.FADING_OUT) {
        Clamp(dscale_dsample, DELTA_SCALE_MUSIC_MIN, DELTA_SCALE_MUSIC_MAX);
    } else {
        Clamp(dscale_dsample, DELTA_SCALE_MIN, DELTA_SCALE_MAX);
    }

*/

    samples_written := num_samples;  // May get overwritten if we break from the loop early.

    tmp: Audio_Source_Sample = ---;

/*
    if (use_filter) {
        for (i = 0; i < num_samples; i++) {
            y2 = y1;
            y1 = y0;

            x2 = x1;
            x1 = x0;

            if (stream.num_channels == 1) {
                sample_mono(samples, page_start, page_end, source_cursor, tmp.channels, no_overflow);
            } else if (stream.num_channels == 4) {
                sample_four(samples, page_start, page_end, source_cursor, tmp.channels, no_overflow);
            } else if (stream.num_channels == 6) {
                sample_six(samples, page_start, page_end, source_cursor, tmp.channels, no_overflow);
            } else if (stream.num_channels == 2) {
                sample_stereo(samples, page_start, page_end, source_cursor, tmp.channels, no_overflow);
            }

            mix_sample_into_output_streams(player, stream, &tmp, &x0);

            y0 = x0 * K0 + y1 * K1 + y2 * K2;

            source_cursor += dcursor_dsample;
            dcursor_dsample += ddcursor_dsample;

            if ((source_cursor >= page_end) || (source_cursor < page_start)) {
                samples_written = i + 1;
                break;
            }
        }
    } else {
*/
    {

        if num_samples > 0 {
            for i : 0..stream.num_channels-1 {
                target := *stream.input_scale_mappings[i];
                for j : 0..handler.num_channels-1 {
                    goal := target.source_scale_for_this_output_index[j];
                    current := target.interpolated_source_scale_for_this_output_index[j];

                    rate = (goal - current) / num_samples;
            
                    limit := 30.0 / OUTPUT_SAMPLING_RATE;  // Can go from volume 0-1 in max 1/30th sec.
                    Clamp(*rate, -limit, limit);

                    target.dvolume_dsample[j] = rate;
                }
            }
        }

        num_output_channels := player.handler.num_channels;
        mix: Audio_Dest_Sample = ---;
        for i : 0..num_samples-1 {
            sample_n_channels(stream, samples, page_start, page_end, source_cursor, tmp.channels, no_overflow);
            mix_sample_into_output_streams(player, stream, *tmp, *mix);

            // @Cleanup
            // accumulator[i] += mix;
//            result := add(*accumulator[i].base, *mix.base);
//            accumulator[i] = << cast(*Audio_Dest_Sample) *result; // Dumb!
            plus_equals(*accumulator[i].base, *mix.base, num_output_channels);
            
            source_cursor += dcursor_dsample;
            dcursor_dsample += ddcursor_dsample;

            icursor := cast(s64) source_cursor;
            if (icursor >= page_end) || (icursor < page_start) {
                samples_written = i + 1;
                break;
            }
        }
    }

    //
    // Update the current_rate and current_scale, potentially topping them off.
    //
    // assert(samples_written > 0);

    stream.samples_streamed_since_entity_update += samples_written;
                            
    stream.current_rate += drate_dsample * samples_written;

    if fabs(stream.desired_rate - stream.current_rate) < 0.001 {
        stream.current_rate = stream.desired_rate;
    }

/* @Experiment
    stream.last_volume_linear += dscale_dsample * samples_written;
    if (fabs(desired_scale - stream.last_volume_linear) < 0.001f) {
        stream.last_volume_linear = desired_scale;
    }
*/

   /*
    stream.x0 = x0;
    stream.x1 = x1;

    stream.y0 = y0;
    stream.y1 = y1;
*/

    return source_cursor, samples_written;
}


accumulate_stream :: (player: *Sound_Player, stream: *Sound_Stream, accumulator: [] Audio_Dest_Sample, num_samples: s64) -> bool {
    data := stream.sound_data;
    if !data return false;

/* Temporary test hack:
	if (stream.flags & Sound_Stream.WAITING_FOR_INITIAL_DECODER_PAGES) {
		if (stream.decoder && (stream.decoder.pages.items > 1)) stream.flags &= ~Sound_Stream.WAITING_FOR_INITIAL_DECODER_PAGES;
	}
*/

    // Don't go forward with this stream if we haven't started getting decoder pages yet.
	if stream.flags & Sound_Stream.WAITING_FOR_INITIAL_DECODER_PAGES {
		return false;
	}

    num_source_samples := data.nsamples_times_nchannels / data.nchannels;

    direction : s64 = 1;
    if stream.current_rate < 0 direction = -1;

    dest_cursor : s64 = 0;

    while num_samples {
        // assert(num_samples >= 0);
        range := stream.repeat_end_position - stream.repeat_start_position;
        if range <= 0 {
            // Nothing to play!
            break;
        }

        maybe_wrap_play_cursor(stream); // Do this BEFORE copying stream.play_cursor into source_cursor!
        source_cursor := stream.play_cursor;
        orig_source_cursor := source_cursor;

        si, remainder := get_icursor_and_remainder(source_cursor);

        //
        // If we should play silence samples, do so here...
        //
        silence_samples : s64 = 0;
        if si < 0 {
            if direction < 0  silence_samples = num_samples;
            else silence_samples = (0 - si + direction - 1) / direction;
        } else if si >= num_source_samples {
            if direction < 0  silence_samples = (si - num_source_samples + 1 + (-direction) + 1) / (-direction);
            else silence_samples = num_samples;
        }
                
        // assert(silence_samples >= 0);
        if silence_samples < 0 silence_samples = 0;

        if silence_samples {
            to_subtract := silence_samples;
            Clamp(*to_subtract, 0, num_samples);

            num_samples -= to_subtract;
            dest_cursor += to_subtract;
            source_cursor += cast(float64) (to_subtract * direction);
            stream.play_cursor += cast(float64) (to_subtract * direction);

            // assert(num_samples >= 0);

            stream.samples_streamed_since_entity_update += to_subtract;

            stream.current_rate = stream.desired_rate;
            catch_up_volumes(player.handler, stream);

            continue;
        }


        //
        // Do actual data samples.
        //

        no_overflow: bool;
        bounds: Buffer_Bounds;

        if !stream.silent_this_frame {
            success: bool;
            success, no_overflow = get_buffer_bounds(stream, data, cast(s64) source_cursor, *bounds);

			if !success {
				stream.silent_this_frame = true;  // Failed to decompress audio in time?
			}
        }

        if stream.silent_this_frame {
            // If it is silent_this_frame, pointer for 'bounds' will be unused.
            bounds.start = cast(s64) source_cursor;
            bounds.end = bounds.start + num_samples;
            bounds.memory = null;
        }



        to_copy: s64 = ---;
        if direction > 0 {
            to_copy = bounds.end - cast(s64) source_cursor;
        } else {
            // assert(direction < 0);
            to_copy = cast(s64) source_cursor - bounds.start + 1;
        }

        // assert(to_copy >= 0);
        if to_copy > num_samples  to_copy = num_samples;
        if to_copy == 0 {
            to_copy = 1;  // @Incomplete, decide what to do here.
        }

        accum2 := *accumulator[dest_cursor];
        samples_written: s64;
        source_cursor, samples_written =
            accumulate_buffer_f(player, accum2, to_copy, source_cursor,
                                bounds.memory, bounds.start, bounds.end,
                                stream, no_overflow);

        stream.play_cursor += (source_cursor - orig_source_cursor);
		maybe_wrap_play_cursor(stream);

        // assert(samples_written > 0);
        // assert(samples_written <= to_copy);
        // assert(samples_written <= num_samples);

        num_samples -= samples_written;
        // assert(num_samples >= 0);


        dest_cursor += samples_written;

        // assert(num_samples >= 0);
    }

    return false;
}

advance_history_cursor :: (player: *Sound_Player) {
    player.history_cursor += 1;
    if player.history_cursor == HISTORY_LENGTH  player.history_cursor = 0;

    player.history_subcursor = 0;

    for j : 0..OUTPUT_CHANNELS_MAX-1 {
        player.history[player.history_cursor].low[j] = 0;
        player.history[player.history_cursor].high[j] = 0;
    }
}

fill_sample_buffer :: (using player: *Sound_Player, buffer: string) {
    if !buffer return;
    
    num_channels := handler.num_channels;
    if !num_channels return;
    assert (num_channels == 2 || num_channels == 6 || num_channels == 8);

    num_samples := buffer.count / (2 * num_channels);
    assert(num_samples <= ACCUMULATOR_SAMPLES_MAX);
    assert(buffer.count / 2 % num_channels == 0);

    accumulator := the_accumulator;
    memset(accumulator.data, 0, num_samples * accumulator_element_size);  // @Feature: Should be able to do size_of(accumulator[0]) in some way.

    for streams {
        if it.inaudible continue;
        // ta := get_time();
        // print("Accum %: %\n", it_index, it.sound_name);
        accumulate_stream(player, it, accumulator, num_samples);
        // tb := get_time();
        // print("Accumulate took % seconds for % samples (% bytes/sec).\n", tb - ta, num_samples, cast(float)num_samples / cast(float)(tb-ta));
    }

    // Copy the accumulator into the buffer...

    dest := cast(*s16) buffer.data;

    if num_channels == 2 {
/*
        for (int i = 0; i < num_samples; i++) {
            for (int j = 0; j < AUDIO_SAMPLE_NUM_CHANNELS; j++) {
                int value = accumulator[i].channels[j];

                Clamp(value, -32767, 32767);
                dest[i*num_channels + j] = value;
            }
        }
*/

        for i : 0..num_samples-1 {
            value0 := accumulator[i].channels[ACHANNEL_FRONT_LEFT];
            value1 := accumulator[i].channels[ACHANNEL_FRONT_RIGHT];

            Clamp(*value0, -32767, 32767);
            Clamp(*value1, -32767, 32767);

            dest[i*2 + 0] = cast(s16) value0;
            dest[i*2 + 1] = cast(s16) value1;
        }
        bytes := num_samples*2*num_channels;
        // print("filled % bytes at %\n", num_samples*2*num_channels, buffer.data);
    } else {

        for i : 0..num_samples-1 {
            for j : 0..num_channels-1 {
                value := accumulator[i].channels[j];

                Clamp(*value, -32767, 32767);

                dest[i*num_channels + j] = cast(s16) value;
            }
        }
    }

/*
    for i : 0 .. num_samples - 1 {
        dest[i * num_channels + 0] = 0;
        //dest[i * num_channels + 1] = 0;
    }
*/
    
    // sierpinski_curve();
    // sierpinski_cursor.x += 1;
    
    if Core.developer {
        scale := 1.0 / 32767.0;

        if !history_paused {
            h := *history[history_cursor];
            
            for i : 0..num_samples-1 {
                for c : 0..num_channels-1 {
                    value := dest[i * num_channels + c];

                    f := value * scale;
                    if f > h.high[c]  h.high[c] = f;
                    if f < h.low[c]   h.low[c]  = f;
                }

                history_subcursor += 1;
                if history_subcursor >= audio_samples_per_history_sample {
                    advance_history_cursor(player);
                    h = *history[history_cursor];
                }
            }
        }
    }

    // do_sine_wave(dest, num_samples, player);
}


/*
   static :: (s: string) {
    samples := s.count/2;
    dest := cast(*s16) s.data;
    
    for 0..samples-1 {
        // s[it] = cast(u8)random_get();

        t := cast(float)it / 2000.0;
        omega :: 100.0;
        y := cos(omega * t);
        dest[it] = cast(s16) (y * 32767.0);

//        dest[it] = 0x0dcd;
    }
}
*/

/*
sanity :: (s: string, name: string) {
    samples := s.count/2;
    dest := cast(*s16) s.data;

    prev_bad := false;
    for 0..samples-1 {
        bad := false;
        if dest[it] == 0x0dcd bad = true;
        if bad print("Bad\n");
        if bad && prev_bad {
            print("Fail in % sample %\n", name, it);
        }

        prev_bad = bad;
    }
}
*/

update_from_async_thread :: (using player: *Sound_Player, actually_async: bool) {
    //@Hack Ideally, we should lock only where we access shared resources. However, the win32 implementation of 
    //      release_fill_regions() doesn't like it (DirectSoundBuffer.Unlock() complains). 
    //      Have a look after the demo!

    lock(sound_mutex);
    defer unlock(sound_mutex);

    buffered_bytes := count_buffered_bytes(handler);  // This also recomputes handler.min_needed_bytes.

    needed_samples := TYPICAL_NEEDED_SAMPLES;
    min_needed_samples := (handler.minimum_prebuffered_bytes + 3) / (2 * 2);
    min_needed_samples += cast(s64) (OUTPUT_SAMPLING_RATE * 2 * (3.5 / 60.0));  // Add 3.5 60Hz frames worth of safety to the padding here.  This is unusually high but we are doing it for now so we can run from bytecode without problems.
    if needed_samples < min_needed_samples  needed_samples = min_needed_samples;
    
    needed_bytes := needed_samples * (2 * handler.num_channels);
    bytes_to_buffer := needed_bytes - buffered_bytes;

    if bytes_to_buffer > 0 {
        regions, success := get_fill_regions(handler, bytes_to_buffer);
        
        fill_sample_buffer(player, regions.buffer0);
        fill_sample_buffer(player, regions.buffer1);

        // The PS4 C++ version of this code actually heeded the following comment, but as of
        // this Jai port I am currently not:
        
        // it's important that we are not locking the sound_mutex while we are releasing the fill regions. In some
        // platforms (ie.PS4), this call might need to send data to the output hardware which can take a significant amount of time.
        release_fill_regions(handler, regions);
    }

    if !handler.playing play(handler);
}


async_audio_update :: (thread: *Thread) -> s64 {
    player := cast(*Sound_Player) thread.data;

    // print("Entering async_audio_update\n");
//    os_set_thread_priority(THREAD_PRIO_NORMAL);
//    os_set_thread_affinity(THREAD_AFFINITY_LOW_PRIORITY_THREAD);

    while true {
        update_from_async_thread(player, true);
        if player.async_thread_should_exit {
            player.async_thread_has_exited = true;
            return 0;
        }

        sleep_milliseconds(5);
    }

    return 0;
}
