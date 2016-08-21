#import "Mixer_Win32";
#import "Mixer_Async";

#import "Math";
#import "Thread";

DEFAULT_FILL_AHEAD_TIME :: #run { 2.4 / 60.0; };

UNIVERSE_USUAL    :: 0;
UNIVERSE_PARALLEL :: 1;
UNIVERSE_MENU     :: 2;

ACHANNEL_FRONT_LEFT  :: 0;
ACHANNEL_FRONT_RIGHT :: 1;
ACHANNEL_CENTER      :: 2;
ACHANNEL_SUBWOOFER   :: 3;
ACHANNEL_REAR_LEFT   :: 4;
ACHANNEL_REAR_RIGHT  :: 5;
ACHANNEL_EXTEND_LEFT :: 6;
ACHANNEL_EXTEND_RIGHT:: 7;

ACHANNEL_MAX         :: 8;
OUTPUT_CHANNELS_MAX  :: 8;

MAX_CHANNELS_PER_SOUND :: 8;

Sound_Source_Directions :: enum {
    SOUND_SOURCE_MONO : 0,
    SOUND_SOURCE_LEFT,
    SOUND_SOURCE_RIGHT,
    SOUND_SOURCE_FRONT_LEFT,
    SOUND_SOURCE_FRONT_RIGHT,
    SOUND_SOURCE_REAR_LEFT,
    SOUND_SOURCE_REAR_RIGHT,
    SOUND_SOURCE_CENTER_FORWARD,
    SOUND_SOURCE_SUBWOOFER_CENTER_FORWARD,
    SOUND_SOURCE_EXTEND_LEFT,
    SOUND_SOURCE_EXTEND_RIGHT,

    NUM_SOUND_SOURCE_DIRECTIONS
};

SOUND_INNER_RADIUS_DEFAULT ::  2.0;  // Multiplied by volume log scale
SOUND_OUTER_RADIUS_DEFAULT :: 50.0;  // Multiplied by volume log scale


CACHED_OGG_DECODE_THREADED :: true;



Audio_Sample_Base :: struct {
    channels: [MAX_CHANNELS_PER_SOUND] float;
}

//
// We define Audio_Source_Sample and Audio_Dest_Sample just so
// we can have typechecking... but we want all the same operators,
// etc.
//
// But note that the indexing is different between these!  The indexing
// for Dest_Sample is ACHANNEL_*; the indexing for Source_Sample
// is SOUND_SOURCE_*.
//
//     -jblow, 3 December 2011
//

Audio_Source_Sample :: struct {
    using base: Audio_Sample_Base;
}

Audio_Dest_Sample :: struct {
    using base: Audio_Sample_Base;
}

Scale_Mapping :: struct {
    //
    // According to VBAP we only need 2 speakers at once; the problem is,
    // we need to smoothly interpolate (potentially per-sample), so
    // hey, we get to think about all channels per sample.
    //

    source_scale_for_this_output_index: [OUTPUT_CHANNELS_MAX] float;
    interpolated_source_scale_for_this_output_index: [OUTPUT_CHANNELS_MAX] float;
    dvolume_dsample: [OUTPUT_CHANNELS_MAX] float;
}

Sound_Stream :: struct {
    num_channels : s32 = 2;

    // The manager_id along with the portable_id provides a unique identifier for who created the sound (not unique across all time, but unique at any time t).
    portable_id: Pid;
    manager_id:  Manager_Id; 
    player: *Sound_Player;
    
    sound_name: string;

    REPEATING   :: 0x1;
    SPATIALIZED :: 0x2;
    IS_MUSIC    :: 0x10;
    FADING_OUT  :: 0x20;
    DO_NOT_KILL :: 0x80;
    PAUSED_DUE_TO_MENU     :: 0x100;
    WAS_PAUSED_DUE_TO_MENU :: 0x200;
    AMBIENT     :: 0x400;
    SLOW_STOP   :: 0x800;
    WAITING_FOR_INITIAL_DECODER_PAGES :: 0x8000;

    flags: s64;  // @Cleanup: Do we want typechecking on these flags? We probably need a little work on flag enums.
    
    sound_data : *Sound_Data;
    my_player:   *Sound_Player;
    decoder:     *Cached_Decoder;


    repeat_start_position: s64;
    repeat_end_position:   s64;

    samples_streamed_since_entity_update: s64;
    universe: s64;

    position:    Vector3;
    orientation: Quaternion;

    current_rate: float = 1;
    desired_rate: float = 1;
    debug_display_volume: float = 0;

    play_cursor: float64 = 0;
    silent_samples_at_start_of_play: s64 = 0; // Not included in any repeats...

    marked              := false;
    please_swap_buffers := false;
    inaudible           := false;
    debug_watch         := false;

    input_scale_mappings: [MAX_CHANNELS_PER_SOUND] Scale_Mapping;  // One target per channel.  Each target has an array of output loudnesses.

    max_gain: float   = 0;  // For debugging.
    last_plane_dir: Vector2;

    volume_scale_due_to_entity_manager: float = 1.0;
    initial_samples_fetched: s64;
    samples_needed_to_start_playing: s64;

    silent_this_frame  := false;  // Set this to true if all input_scale_mappings are 0.
    // These are input and output histories, used for filtering.
/*

  Filtering temporarily disabled because it got a little more complicated in the new refactoring where I
  am clearly disambiguating between input and output samples.  We weren't using it yet anyway.

  When re-implementing filters I will probably do it in a 2nd pass over the samples, rather than inline
  as I had done it before.  The code will be way more maintainable.

     -jblow, 3 December 2011

    Audio_Source_Sample x0, x1;
    Audio_Source_Sample y0, y1;
*/
};


Sample_Output_History :: struct {
    low:  [OUTPUT_CHANNELS_MAX] float;
    high: [OUTPUT_CHANNELS_MAX] float;
};

HISTORY_LENGTH :: 1000;  // samples
DEFAULT_AUDIO_SAMPLES_PER_HISTORY_SAMPLE :: 128;


Sound_Player :: struct {
    streams: [..]  *Sound_Stream;

    async_thread: *Thread;
    sound_mutex:  *Mutex;
    handler:      *Sound_Handler;

    handler_initted := false;

    listener_position    : Vector3;
    listener_orientation : Quaternion;

    axis_forward : Vector3;
    axis_left    : Vector3;
    axis_up      : Vector3;

    listener_forward : Vector3;
    listener_left    : Vector3;
    listener_up      : Vector3;

    listener_theta: float;  // In the 2D speaker plane

    listener_indoor_zone_scale: float;
    listener_outdoor_zone_scale: float;

    have_listener := false;

    
    master_volume: float = 1;

    async_thread_should_exit := false;
    async_thread_has_exited  := false;
 
    history: [HISTORY_LENGTH] Sample_Output_History;
    history_cursor:    s64;
    history_subcursor: s64;
    audio_samples_per_history_sample: s64;
    history_paused := false;

    stereo_base : float = 1;

    mix_all: float = 1;
    mix_props: float = 1;
    mix_footsteps: float = 1;
    mix_ui: float = 1;
    mix_ambiences: float = 1;
};


//
// After playing around with decibels / etc for a while I decided that they are not an
// appropriate scale for thinking about sound volumes for games.  Most audio references
// just unthinkingly start telling you about decibels and what they do and why they are good,
// but I find most of these things aren't true.  They are just a wacky unintuitive unit
// that got widely adopted.
//
// Instead, here we are using a perceptual unit where scaling by 2.0 means "it sounds twice as loud", 
// etc.  This ends up being an exponentiation just like we do for HDR rendering (but with a different
// exponent).  
//
// So, for example, 0.5 means "half as loud", which is -10dB, which is a linear scale factor of 0.316.
//
// To derive this math, you start with Loudness = 20 log(p / p0), the standard decibel equation.
// Then we presume that +10dB really means "twice as loud".  Let's call R the perceptual scale factor.
// Then R = pow(2, Loudness/10).  And you solve for that.  What we are using here is the reciprocal
// because for volume tweaks we are going in the other direction (perceptual to wave pressure, whereas
// R defines wave pressure to perceptual).
//
//              -jblow, 9 November 2011
//
perceptual_to_linear :: (x: float) -> float {
    LOG10_OF_2 :: 0.30103;
    EXPONENT :float= (1 / (2 * LOG10_OF_2));

    return pow(x, EXPONENT);
}

retired_decoders: [..] *Cached_Decoder;

// Taking these numbers down a bit, we'll see how it goes...
SECONDS_TO_FETCH_BINK :: 0.4;
SECONDS_TO_FETCH_OGG  :: 0.4;
SECONDS_TO_FETCH_ADPCM:: 0.4;  // In theory we don't need this to be too long, but actually, if we make it shorter we will skip when frame rates are low, which is not great. But if you get down to 0.4s per frame, you probably should not expect anything to be good.

VERY_CLOSE :: 4.0;

vbap_speaker_directions: [ACHANNEL_MAX] Vector2;
vbap_source_directions:  [Sound_Source_Directions.NUM_SOUND_SOURCE_DIRECTIONS] Vector2;

ROOT_2_OVER_2 : float : 0.7071067;
//#run { cast(float) 0.70710678; };

Vbap_Arc :: struct {
    speaker1: s64;
    speaker2: s64;

    l_inverse: Matrix2;
};

NUM_ARCS_6CH: s64 = 5;
/* @Incomplete

static Vbap_Arc arcs_6ch[NUM_ARCS_6CH] = {
    { ACHANNEL_CENTER, ACHANNEL_FRONT_LEFT },
    { ACHANNEL_FRONT_LEFT, ACHANNEL_REAR_LEFT },
    { ACHANNEL_REAR_LEFT, ACHANNEL_REAR_RIGHT },
    { ACHANNEL_REAR_RIGHT, ACHANNEL_FRONT_RIGHT },
    { ACHANNEL_FRONT_RIGHT, ACHANNEL_CENTER }
};
*/

NUM_ARCS_8CH: s64 = 7;
/* @Incomplete

static Vbap_Arc arcs_8ch[NUM_ARCS_8CH] = {
    { ACHANNEL_CENTER, ACHANNEL_FRONT_LEFT },
    { ACHANNEL_FRONT_LEFT, ACHANNEL_REAR_LEFT },
    { ACHANNEL_REAR_LEFT, ACHANNEL_EXTEND_LEFT },
    { ACHANNEL_EXTEND_LEFT, ACHANNEL_EXTEND_RIGHT },
    { ACHANNEL_EXTEND_RIGHT, ACHANNEL_REAR_RIGHT },
    { ACHANNEL_REAR_RIGHT, ACHANNEL_FRONT_RIGHT },
    { ACHANNEL_FRONT_RIGHT, ACHANNEL_CENTER }
};
*/

NUM_ARCS :: NUM_ARCS_8CH;
arcs: [] Vbap_Arc;


count_retired_decoders :: () -> s64 {
    return 0; // @Incomplete
//    return retired_decoders.items;
}

invert :: (using m: *Matrix2, result: *Matrix2) {
    det : float = _11 * _22 - _21 * _12;
    assert(det != 0);

    result._11 = _22 / det;
    result._22 = _11 / det;
    result._12 = -_12 / det;
    result._21 = -_21 / det;
}


clear_scale_accumulation :: (stream: *Sound_Stream, index: s64) {
    assert(index < MAX_CHANNELS_PER_SOUND);

    target := *stream.input_scale_mappings[index];

    for 0..OUTPUT_CHANNELS_MAX-1
        target.source_scale_for_this_output_index[it] = 0;
}


get_target_2_closeness :: (player: *Sound_Player, stream: *Sound_Stream, sound: *Entity_Issued_Sound) -> float {
    //
    // :StereoDot
    // 
    // I did not understand the math happening in target_n, so I wrote a thing for target_2 that just
    // interpolates each dot to 1. We take the len after player, which should work to normalize
    // the volume correctly.  -jblow, 29 April 2015.
    //

    very_close: float = VERY_CLOSE;
    very_close = min(very_close, sound.inner_radius * 0.75);

    a := stream.position;
    b := player.listener_position;

    // Eliminate Z on both since we presume our speakers are in a plane.
    a.z = 0;
    b.z = 0;

    dist := distance(a, b);
    closeness: float = 0;
    if dist < very_close {
        closeness = 1.0 - (dist / very_close);
        Clamp(*closeness, 0, 1);
    }

    return closeness;
}

adjust_stereo_dots_by_closeness :: (dot_left: *float, dot_right: *float, closeness: float) {
    // See :StereoDot.


    if (!closeness) return;

    <<dot_left = lerp(<<dot_left, 1, closeness);
    <<dot_right = lerp(<<dot_right, 1, closeness);
}

/*

  Mixing to stereo is not really VBAP.  It is just kind of a hack.  But,
  I left VBAP in the name to keep things uniform.

  The reason it's not VBAP is because when you don't have a speaker path
  that completely encircles the listener, it doesn't seem to have a way to
  represent objects in parts of space -- you would get negative gain values.
 
*/

accum_scale_target_2_source_mono :: (player: *Sound_Player, stream: *Sound_Stream, sound: *Entity_Issued_Sound, plane_dir: Vector2, gain_scale: float, target: *Scale_Mapping) {
    closeness: float = get_target_2_closeness(player, stream, sound);

    dot_left: float = dot_product(plane_dir, vbap_speaker_directions[ACHANNEL_FRONT_LEFT]);
    dot_right: float = dot_product(plane_dir, vbap_speaker_directions[ACHANNEL_FRONT_RIGHT]);

    Clamp(*dot_left, 0, 1);
    Clamp(*dot_right, 0, 1);

    dot_left += player.stereo_base;
    dot_right += player.stereo_base;

    adjust_stereo_dots_by_closeness(*dot_left, *dot_right, closeness);

    len := sqrt(dot_left * dot_left + dot_right * dot_right);
    assert(len > 0);

    target.source_scale_for_this_output_index[ACHANNEL_FRONT_LEFT] += (dot_left / len) * gain_scale;
    target.source_scale_for_this_output_index[ACHANNEL_FRONT_RIGHT] += (dot_right / len) * gain_scale;
}

accum_scale_target_2_source_n :: (player: *Sound_Player, stream: *Sound_Stream, sound: *Entity_Issued_Sound, plane_dir: Vector2, n: s64, gain_scale: float) {
    // @Speed: Lift these constants out; but for now we can't initialize
    // stuff like Vector2 at global scope!

    faux_vbap_stereo_right_front := make_vector2(ROOT_2_OVER_2, -ROOT_2_OVER_2);
    faux_vbap_stereo_right_rear  := make_vector2(-ROOT_2_OVER_2, -ROOT_2_OVER_2);
    faux_vbap_stereo_left_front  := make_vector2( ROOT_2_OVER_2,  ROOT_2_OVER_2);
    faux_vbap_stereo_left_rear   := make_vector2(-ROOT_2_OVER_2,  ROOT_2_OVER_2);


    closeness: float = get_target_2_closeness(player, stream, sound);

    for i: 0..n-1 {
        assert(i < MAX_CHANNELS_PER_SOUND);
        target := *stream.input_scale_mappings[i];
        
        source_dir_index := stream.sound_data.source_directions[i];
        source_dir       := vbap_source_directions[source_dir_index];

        rotate(*source_dir, -player.listener_theta);

        dot_left_front := dot_product(source_dir, faux_vbap_stereo_left_front);
        dot_left_rear  := dot_product(source_dir, faux_vbap_stereo_left_rear);

        dot_right_front := dot_product(source_dir, faux_vbap_stereo_right_front);
        dot_right_rear  := dot_product(source_dir, faux_vbap_stereo_right_rear);

        Clamp(*dot_left_front, 0, 1);
        Clamp(*dot_left_rear, 0, 1);
        Clamp(*dot_right_front, 0, 1);
        Clamp(*dot_right_rear, 0, 1);

        dot_left  := ROOT_2_OVER_2 * (dot_left_front + dot_left_rear);
        dot_right := ROOT_2_OVER_2 * (dot_right_front + dot_right_rear);

        Clamp(*dot_left, 0, 1);
        Clamp(*dot_right, 0, 1);

        adjust_stereo_dots_by_closeness(*dot_left, *dot_right, closeness);

/*
        if (stream.debug_watch) {
            Log.print("accum %d, source_dir is %d (%.3f, %.3f), dot_left: [%.2f, %.2f], %.2f; dot_right: [%.2f, %.2f], %.2f\n", i, source_dir_index, source_dir.x, source_dir.y,
                       dot_left_front, dot_left_rear, dot_left, dot_right_front, dot_right_rear, dot_right);
        }
*/


        dot_left  += player.stereo_base;
        dot_right += player.stereo_base;

        len := sqrt(dot_left * dot_left + dot_right * dot_right);
        assert(len > 0);

        target.source_scale_for_this_output_index[ACHANNEL_FRONT_LEFT] += (dot_left / len) * gain_scale;
        target.source_scale_for_this_output_index[ACHANNEL_FRONT_RIGHT] += (dot_right / len) * gain_scale;

/*
        if (stream.debug_watch) {
            Log.print("channel %d: Left %.3f, Right %.3f", i, target.gain[ACHANNEL_FRONT_LEFT], target.gain[ACHANNEL_FRONT_RIGHT]);
        }
*/
    }
}

add_vbap_gain_for_direction :: (player: *Sound_Player, target: *Scale_Mapping, plane_dir: Vector2, gain_scale: float) {

    highest_low    := -FLT_MAX;
    best_arc_index : s64 = -1;

    for arc: arcs {
        gain := multiply(arc.l_inverse, plane_dir);
        low  := min(gain.x, gain.y);

        if low > highest_low {
            highest_low = low;
            best_arc_index = it_index;
        }
    }

    if best_arc_index == -1 return;  // Assert here?  This really should not happen.

    arc := *arcs[best_arc_index];
    gain := multiply(multiply(arc.l_inverse, plane_dir), gain_scale);

    target.source_scale_for_this_output_index[arc.speaker1] += max(gain.x, 0);
    target.source_scale_for_this_output_index[arc.speaker2] += max(gain.y, 0);
}


skip_this_output_channel :: (index: s64, sound: *Entity_Issued_Sound) -> bool {
    if sound.flags & ISSUED_SOUND_IS_FOOTSTEP {
        if index == ACHANNEL_REAR_LEFT return true;
        if index == ACHANNEL_REAR_RIGHT return true;
    }

    return false;
}

accum_scale_target_all_source_mono :: (player: *Sound_Player, stream: *Sound_Stream, sound: *Entity_Issued_Sound, plane_dir: Vector2, gain_scale: float, target: *Scale_Mapping) {
    tmp_target: Scale_Mapping;

    // Don't put gain_scale in until later, as otherwise this would affect computation of orig_len2 below.
    add_vbap_gain_for_direction(player, *tmp_target, plane_dir, 1.0);

    //
    // If the source is close to the listener, fill all speakers (so that we don't get discontinuities as the sound passes close by).
    //

    very_close := VERY_CLOSE;
    very_close = min(very_close, sound.inner_radius * 0.75);

    dist := distance(stream.position, player.listener_position);
    if dist < very_close {
        t := 1.0 - (dist / very_close);
        Clamp(*t, 0, 1);

        orig_len2 : float;
        for i: 0..OUTPUT_CHANNELS_MAX-1 {
            if i == ACHANNEL_SUBWOOFER continue;
            if skip_this_output_channel(i, sound) continue;

            s := tmp_target.source_scale_for_this_output_index[i];
            orig_len2 += s * s;

            tmp_target.source_scale_for_this_output_index[i] = lerp(s, 1, t);
        }

        len := sqrt(orig_len2);
        if !len return;

        for i : 0..OUTPUT_CHANNELS_MAX-1 {
            if i == ACHANNEL_SUBWOOFER continue;
            if skip_this_output_channel(i, sound) continue;

            tmp_target.source_scale_for_this_output_index[i] /= len;
        }
    }

    for i : 0..OUTPUT_CHANNELS_MAX-1 {
        target.source_scale_for_this_output_index[i] += tmp_target.source_scale_for_this_output_index[i] * gain_scale;
    }
}

accum_scale_target_all_source_n :: (player: *Sound_Player, stream: *Sound_Stream, sound: *Entity_Issued_Sound, plane_dir: Vector2, n: s64, gain_scale: float) {
    //
    // In this case we actually ignore plane_dir and use listener_theta to rotate the channels around...
    // 

    using Sound_Source_Directions.members;
    
    for i: 0..n-1 {
        source_dir_index := stream.sound_data.source_directions[i];

        if source_dir_index == SOUND_SOURCE_SUBWOOFER_CENTER_FORWARD {
            assert(i < MAX_CHANNELS_PER_SOUND);
            stream.input_scale_mappings[i].source_scale_for_this_output_index[ACHANNEL_SUBWOOFER] = 1;
            continue;
        }

        if skip_this_output_channel(i, sound) continue;

        revised_dir := vbap_source_directions[source_dir_index];
            
        //
        // Override direction for stereo sources so that they come from straight-left and straight-right...
        //
            
        rotate(*revised_dir, -player.listener_theta);

        assert(i < MAX_CHANNELS_PER_SOUND);

        target := *stream.input_scale_mappings[i];
        add_vbap_gain_for_direction(player, target, revised_dir, gain_scale);
    }
}

get_plane_dir :: (player: *Sound_Player, sound: *Entity_Issued_Sound, position: Vector3) -> Vector2 {
    if (!player.have_listener) || !(sound.flags & ISSUED_SOUND_SPATIALIZED) {
        return make_vector2(1, 0);
    }

    pos := subtract(position, player.listener_position);
    up  := player.listener_up;

    // Put the sound into a 2D plane.

    pos = subtract(pos, multiply(up, dot_product(pos, up)));
    normalize_or_zero(*pos);

    plane_dir := make_vector2(dot_product(pos, player.listener_forward),
                              dot_product(pos, player.listener_left));

    return plane_dir;
}


source_dir_to_target_dir :: (handler: *Sound_Handler, source_dir_index: Sound_Source_Directions.strict) -> s64 {
    assert(handler.num_channels >= 6);  // For now we only handle 5.1 through 8.1 in this routine.

    using Sound_Source_Directions.members;
    
    // This could really use a switch statement. Or maybe a lookup table.
    if source_dir_index == SOUND_SOURCE_MONO return ACHANNEL_CENTER;
    if source_dir_index == SOUND_SOURCE_MONO             return ACHANNEL_CENTER;
    if source_dir_index == SOUND_SOURCE_LEFT             return ACHANNEL_FRONT_LEFT;
    if source_dir_index == SOUND_SOURCE_RIGHT             return ACHANNEL_FRONT_RIGHT;
    if source_dir_index == SOUND_SOURCE_FRONT_LEFT             return ACHANNEL_FRONT_LEFT;
    if source_dir_index == SOUND_SOURCE_FRONT_RIGHT             return ACHANNEL_FRONT_RIGHT;
    if source_dir_index == SOUND_SOURCE_REAR_LEFT             return ACHANNEL_REAR_LEFT;
    if source_dir_index == SOUND_SOURCE_REAR_RIGHT             return ACHANNEL_REAR_RIGHT;
    if source_dir_index == SOUND_SOURCE_CENTER_FORWARD             return ACHANNEL_CENTER;
    if source_dir_index == SOUND_SOURCE_SUBWOOFER_CENTER_FORWARD             return ACHANNEL_SUBWOOFER;

    if source_dir_index == SOUND_SOURCE_EXTEND_LEFT {
        if handler.num_channels >= 8 {
            return ACHANNEL_EXTEND_LEFT;
        } else {
            return ACHANNEL_REAR_LEFT;
        }
    }

    if source_dir_index == SOUND_SOURCE_EXTEND_RIGHT {
        if handler.num_channels >= 8 {
            return ACHANNEL_EXTEND_RIGHT;
        } else {
            return ACHANNEL_REAR_RIGHT;
        }
    }
    
    assert(false);
    return -1;
}

update_panning_helper_for_locked_output :: (player: *Sound_Player, stream: *Sound_Stream, sound: *Entity_Issued_Sound, gain_scale: float) {
    //
    // This used to work by generally passing these sounds through the same pipeline as spatialized sounds.
    // It was less code, but very complicated and confusing and I kept making mistakes. So, now it is
    // more code but busted out into its own thing, and we'll see how it goes.
    //
    //    -jblow, 10 October 2015.
    //
    if player.handler.num_channels == 2 {
       if stream.num_channels == 1 {
           // This case probably does not happen; a mono locked sound?! But ... we'll do something.
           mapping := *stream.input_scale_mappings[0];
           mapping.source_scale_for_this_output_index[0] = gain_scale*.5;
           mapping.source_scale_for_this_output_index[1] = gain_scale*.5;
       } else if stream.num_channels == 2 {
           left_mapping  := *stream.input_scale_mappings[0];
           right_mapping := *stream.input_scale_mappings[1];
           
           left_mapping.source_scale_for_this_output_index[0]  = gain_scale;
           right_mapping.source_scale_for_this_output_index[1] = gain_scale;
       } else {
           for i : 0..stream.num_channels-1 {
               mapping := *stream.input_scale_mappings[i];

               source_dir_index := stream.sound_data.source_directions[i];
               source_dir := vbap_source_directions[source_dir_index];

               // We assume these are quad ambiences so they will all have y != 0.
               if source_dir.y > 0 {
                   mapping.source_scale_for_this_output_index[0] = gain_scale;
               } else {
                   mapping.source_scale_for_this_output_index[1] = gain_scale;
               }
           }
       }
    } else {
        assert(player.handler.num_channels >= 6);
            
        for i : 0..stream.num_channels-1 {
            mapping := *stream.input_scale_mappings[i];
            
            source_dir_index := stream.sound_data.source_directions[i];
            target_dir_index := source_dir_to_target_dir(player.handler, source_dir_index);

            if target_dir_index != -1 {
                mapping.source_scale_for_this_output_index[target_dir_index] = gain_scale;
            }
        }
    }
}    

update_panning_helper :: (player: *Sound_Player, stream: *Sound_Stream, sound: *Entity_Issued_Sound, gain_scale: float) {

    locked_output := (stream.flags & Sound_Stream.AMBIENT) || (sound.sound_category == SOUND_CATEGORY_UI);
    if locked_output {
        update_panning_helper_for_locked_output(player, stream, sound, gain_scale);
        return;
    }

    //
    // plane_dir is the direction in the 2D plane that the sound is coming from.
    // (We assume we are outputting for horizontal-plane speaker configurations).
    // (1, 0) is forward.  (0, 1) is to the left.
    //


    //
    // The gain_scale is for static stuff (or smoothly changing stuff!) like speaker volume.
    // Dynamic volume changes are interpolated per sample and so are not computed here.
    //
    // @Cleanup: Except that now that we do this gain stuff, maybe they ought to be --
    // the gain factors should probably get interpolated per sample, but currently
    // they do not (and doing that may be slow!)  If we do interpolate them per
    // sample, then this volume scale stuff can definitely go in there.
    // If we don't, we are probably producing clicks, right?  (For the same reason
    // that we interpolate volume_scale per sample instead of per frame!)
    //

    plane_dir, plane_dir_left, plane_dir_right: Vector2;
    gain_scale_right: float;
    plane_dir_left_is_set := false;
    
    if (stream.num_channels == 2) && (sound.flags & ISSUED_SOUND_STEREO_SOURCES) {
        //
        // Use stereo sources to compute plane_dir, plane_dir_right.
        //
 
        pos_left  := object_to_world_space(sound.entity, sound.stereo_source_left);
        pos_right := object_to_world_space(sound.entity, sound.stereo_source_right);

        plane_dir = get_plane_dir(player, sound, pos_left);
        plane_dir_left = plane_dir;
        plane_dir_right = get_plane_dir(player, sound, pos_right);
        plane_dir_left_is_set = true;
        
        // @Refactor: Override the gain_scale that was passed in.
        gain_scale = perceptual_to_linear(get_desired_volume_perceptual(player, sound, stream, pos_left));
        gain_scale_right = perceptual_to_linear(get_desired_volume_perceptual(player, sound, stream, pos_right));
    } else {
        //
        // Use point position to compute plane_dir.
        //

        plane_dir = get_plane_dir(player, sound, stream.position);

        if stream.flags & Sound_Stream.AMBIENT {
            plane_dir = make_vector2(1, 0);  // No rotation with viewporotation: s64, but we do want e.g. stereo channels to stay stereo, 5.1 to stay mapped appropriately, etc.
            plane_dir_right = plane_dir;
			plane_dir_left_is_set = true;
        }
    }

    stream.last_plane_dir = plane_dir;

    if player.handler.num_channels == 0 return;  // Did not initialize properly!

    if player.handler.num_channels == 2 {
        // VBAP targets for other channels will have been cleared already by the Sound_Stream constructor.
        if stream.num_channels == 1 {
            accum_scale_target_2_source_mono(player, stream, sound, plane_dir, gain_scale, *stream.input_scale_mappings[0]);
        }
        else if stream.num_channels == 2 {
            //
            // Stereo is different from source_n, since we treat stereo posources: s64
            // as actually two differently positioned posources: s64 in space.
            //

            left_target  := *stream.input_scale_mappings[0];
            right_target := *stream.input_scale_mappings[1];

            accum_scale_target_2_source_mono(player, stream, sound, plane_dir, gain_scale, left_target);
            accum_scale_target_2_source_mono(player, stream, sound, plane_dir_right, gain_scale_right, right_target);
        }
        else {
            n := min(stream.num_channels, MAX_CHANNELS_PER_SOUND);
            accum_scale_target_2_source_n(player, stream, sound, plane_dir, n, gain_scale);
        }
    } else {
        assert(player.handler.num_channels == 6 || player.handler.num_channels == 8);
        if stream.num_channels == 1 {
            accum_scale_target_all_source_mono(player, stream, sound, plane_dir, gain_scale, *stream.input_scale_mappings[0]);
        }
        else if stream.num_channels == 2 {
            //
            // Stereo is different from source_n, since we treat stereo posources: s64
            // as actually two differently positioned posources: s64 in space.
            //

            left_target  := *stream.input_scale_mappings[0];
            right_target := *stream.input_scale_mappings[1];

            accum_scale_target_all_source_mono(player, stream, sound, plane_dir, gain_scale, left_target);
            accum_scale_target_all_source_mono(player, stream, sound, plane_dir_right, gain_scale_right, right_target);
        }
        else {
            n := min(stream.num_channels, MAX_CHANNELS_PER_SOUND);
            accum_scale_target_all_source_n(player, stream, sound, plane_dir, n, gain_scale);
        }
    }
}

update_panning :: (player: *Sound_Player, stream: *Sound_Stream, sound: *Entity_Issued_Sound) {

    for i: 0..stream.num_channels-1  clear_scale_accumulation(stream, i); 


    perceptual: float = get_desired_volume_perceptual(player, sound, stream, stream.position); 
    volume_scale_linear: float = perceptual_to_linear(perceptual);
    stream.debug_display_volume = perceptual;
    update_panning_helper(player, stream, sound, volume_scale_linear);

    
    //
    // Unset silent_this_frame if any VBAP target is nonzero.
    // Also, set the stream's max gain value (this is for debugging).
    //
    stream.silent_this_frame = true;
    stream.max_gain = 0;

    num_output_channels := player.handler.num_channels;

    for i: 0..MAX_CHANNELS_PER_SOUND-1 {
        target := *stream.input_scale_mappings[i];
        for j: 0..num_output_channels-1 {
            if target.source_scale_for_this_output_index[j] {
                stream.silent_this_frame = false;
                if target.source_scale_for_this_output_index[j] > stream.max_gain
                    stream.max_gain = target.source_scale_for_this_output_index[j];
            }
        }
    }
}

destroy :: (using stream: *Sound_Stream) {
    if decoder {
        decoder.stream = null;
        array_add(*retired_decoders, decoder);
        decoder = null;
    }

    if sound_name free(sound_name.data);
}

// @Portability: Get hwnd the hell out of here somehow.
init :: (using player: *Sound_Player, hwnd: HWND, do_async := false, global_focus := false) -> bool {
    axis_forward = make_vector3(1, 0, 0);
    axis_left = make_vector3(0, 1, 0);
    axis_up = make_vector3(0, 0, 1);

    listener_forward = axis_forward;
    listener_left    = axis_left;
    listener_up      = axis_up;
    
    audio_samples_per_history_sample = DEFAULT_AUDIO_SAMPLES_PER_HISTORY_SAMPLE;


    assert(!sound_mutex);
    sound_mutex = new Mutex("sound");
    init(sound_mutex);

    lock(sound_mutex);
    defer unlock(sound_mutex);

    init_sound_player_decode_queue();

    handler = new Sound_Handler();
    handler_initted = init(handler, hwnd, global_focus);  // @Cleanup: Should just be called 'init'.
    if !handler_initted {
        print("WARNING!!!!!! Sound_Handler could not be initialized.\n");
    }

    //
    // Big VBAP init section here...
    //
    {
        dir := vbap_speaker_directions;
        
        //
        // The X axis is straight forward!  Y is to the left.
        //
        if handler.num_channels == 2 {
            // @Incomplete: Change directions depending on whether
            dir[ACHANNEL_FRONT_LEFT] = make_vector2(0, 1);
            dir[ACHANNEL_FRONT_RIGHT] = make_vector2(0, -1);
            dir[ACHANNEL_REAR_LEFT] = make_vector2(0, 0);
            dir[ACHANNEL_REAR_RIGHT] = make_vector2(0, 0);
            dir[ACHANNEL_CENTER] = make_vector2(0, 0);
            dir[ACHANNEL_SUBWOOFER] = make_vector2(0, 0);
            dir[ACHANNEL_EXTEND_LEFT] = make_vector2(0, 0);
            dir[ACHANNEL_EXTEND_RIGHT] = make_vector2(0, 0);
        }
        else if handler.num_channels == 6 {
            dir[ACHANNEL_FRONT_LEFT] = make_vector2(+1, +1);
            dir[ACHANNEL_FRONT_RIGHT] = make_vector2(+1, -1);
            dir[ACHANNEL_REAR_LEFT] = make_vector2(-1, +1);
            dir[ACHANNEL_REAR_RIGHT] = make_vector2(-1, -1);
            dir[ACHANNEL_CENTER] = make_vector2(1, 0);
            dir[ACHANNEL_SUBWOOFER] = make_vector2(1, 0);
            dir[ACHANNEL_EXTEND_LEFT] = make_vector2(0, 0);
            dir[ACHANNEL_EXTEND_RIGHT] = make_vector2(0, 0);
        }
        else if handler.num_channels == 8 {
            dir[ACHANNEL_FRONT_LEFT] = make_vector2(+1, +1);
            dir[ACHANNEL_FRONT_RIGHT] = make_vector2(+1, -1);
            dir[ACHANNEL_REAR_LEFT] = make_vector2(-1, +1);
            dir[ACHANNEL_REAR_RIGHT] = make_vector2(-1, -1);
            dir[ACHANNEL_CENTER] = make_vector2(1, 0);
            dir[ACHANNEL_SUBWOOFER] = make_vector2(1, 0);
            dir[ACHANNEL_EXTEND_LEFT] = make_vector2(-1, +0.5);        //@@ is this the right direction value?
            dir[ACHANNEL_EXTEND_RIGHT] = make_vector2(-1, -0.5);       //@@ is this the right direction value?
        }
        
        for * dir normalize_or_zero(it);
    }

    {
        using Sound_Source_Directions.members;
        
        dir := vbap_source_directions;
        dir[SOUND_SOURCE_MONO] = make_vector2(1, 0);
        dir[SOUND_SOURCE_LEFT] = make_vector2(0, 1);
        dir[SOUND_SOURCE_RIGHT] = make_vector2(0, -1);
        dir[SOUND_SOURCE_FRONT_LEFT] = make_vector2(+1, +1);
        dir[SOUND_SOURCE_FRONT_RIGHT] = make_vector2(+1, -1);
        dir[SOUND_SOURCE_REAR_LEFT] = make_vector2(-1, +1);
        dir[SOUND_SOURCE_REAR_RIGHT] = make_vector2(-1, -1);
        dir[SOUND_SOURCE_CENTER_FORWARD] = make_vector2(1, 0);
        dir[SOUND_SOURCE_SUBWOOFER_CENTER_FORWARD] = make_vector2(1, 0);
        dir[SOUND_SOURCE_EXTEND_LEFT] = make_vector2(-1, +0.5);
        dir[SOUND_SOURCE_EXTEND_RIGHT] = make_vector2(-1, -0.5);

        for * dir normalize_or_zero(it);
    }



    if handler.num_channels > 2 {
        assert(false);  // Incomplete; need to enable VBAP work.
        
        // We will use VBAP...
        // Set up the arcs.
/*
        if handler.num_channels == 6 {
            arcs     = arcs_6ch;
            NUM_ARCS = NUM_ARCS_6CH;
        } else {
            assert(handler.num_channels == 8);
            arcs     = arcs_8ch;
            NUM_ARCS = NUM_ARCS_8CH;
        }

        for i : 0..NUM_ARCS-1 {
            arc := *arcs[i];
            l1 := vbap_speaker_directions[arc.speaker1];
            l2 := vbap_speaker_directions[arc.speaker2];

            // p = L * g

            // so, g = L^-1 * p

            l: Matrix2;
            l._11 = l1.x;
            l._21 = l1.y;
            l._12 = l2.x;
            l._22 = l2.y;
            invert(*l, *arc.l_inverse);
        }
*/
    }

    if do_async {
        async_thread = thread_create(async_audio_update);
        if async_thread {
            async_thread.data = player;
            thread_start(async_thread);
        } else {
            logprint("Mixer", Log_Mode.EVERYDAY, "Thread create failed!\n");
        }
    }
    

    return true;
}


shutdown :: (using player: *Sound_Player) {
    if !sound_mutex return;  // We never initted!

    lock(sound_mutex);

    shutdown(handler);

    if (async_thread) {
        async_thread_should_exit = true;

        for i : 0..20 {
            if (async_thread_has_exited) break;
            sleep_milliseconds(20);
        }

        delete async_thread;
        async_thread = null;
    }

    unlock(sound_mutex);


    // Delete stuff!

    delete handler;
    handler = null;

    delete sound_mutex;
    sound_mutex = null;
}


samples_to_bytes :: (stream: *Sound_Stream, num_samples: s64) -> s64{
    return num_samples * 2 * stream.sound_data.nchannels;
}


set_master_volume :: (using player: *Sound_Player, value: float) {
    master_volume = value;
}

find :: (using player: *Sound_Player, portable_id: s64, manager_id: s64) -> *Sound_Stream {
    for streams {
        if it.manager_id != manager_id continue;
        if it.portable_id == portable_id return it;
    }

    return null;
}

/*
Sound_Stream *find(sound_name: *char, manager_id: s64) {
    Sound_Stream *stream;
    for stream : streams {
        if (stream.manager_id != manager_id) continue;

        if (!strings_match(sound_name, stream.sound_name)) continue;

        return stream;
    }

    return null;
}
*/

update_desired_rate :: (stream: *Sound_Stream, sound: *Entity_Issued_Sound) {
/*
    if game_is_paused_due_to_menu() && (stream.universe != UNIVERSE_MENU) {
        stream.flags |= Sound_Stream.PAUSED_DUE_TO_MENU;
    } else {
        stream.flags &= ~Sound_Stream.PAUSED_DUE_TO_MENU;
    }
*/
    stream.desired_rate = stream.sound_data.sampling_rate / cast(float) OUTPUT_SAMPLING_RATE;
    stream.desired_rate *= sound.rate_scale * sound.entity_manager.time_passage_rate;
}

get_offset :: (sound: *Entity_Issued_Sound) -> s64 {
    offset: s64 = -4000;
    if (sound.flags & ISSUED_SOUND_IS_MUSIC) offset = -13000;

    return offset;
}

acquire_sound :: (owner: *void, sound_name: string, sound: *Entity_Issued_Sound) -> *Sound_Data {
    // @Cleanup: In the full engine we look this up in the Sound_Catalog,
    // but for now we cheat and have the pointer just be on Issued_Sound.
    assert(sound.sound_data != null);
    return sound.sound_data;
}

release :: (owner: *void, data: *Sound_Data) {
    // Some kind of asset management thing we had in The Witness.
    // For now, do nothing.
}

create_stream :: (using player: *Sound_Player, sound: *Entity_Issued_Sound, universe: s64, is_music: bool, manager: *Entity_Manager) -> *Sound_Stream {
    // Temporarily release the sound mutex then get it back, while we are loading
    // this Sound_Data (since it could take nontrivial time).  That way we won't
    // stop the previous song, or whatever, from refreshing.  This is a little
    // bit icky (in that we are overriding the ScopedLock stuff from higher scopes)
    // but, what the heck.

    data := sound.sound_data_if_streaming;
    if !data { 
        if sound.sound_name {
            unlock(sound_mutex);
            data = acquire_sound(null, sound.sound_name, sound);  // sound streams acquired by a stream don't have an owner, so they always add a reference to the sound
            lock(sound_mutex);
        }
    }

    if !data return null;  // Nothing to play.
	if (!data.buffer) && !data.filename_to_stream_from {
        print("reject %\n", sound.sound_name);
        release(sound, data);
        return null;  // Nothing to play.
    }

    if data.nchannels == 0 {
        release(sound, data);
        // Log.print("Error: Attempt to play sound with 0 channels: %s\n", sound.sound_name);
        return null;  // IC: Avoid division by zero. Is there a better fix?
    }

    stream := new Sound_Stream;


    //
    // For now I am just going to cut-and-paste ogg-decoder structure to ADPCM as well.
    // If they are similar enough in the end maybe we unify them. I don't know, man.
    //   -jblow, 20 May 2015.
    //
    {
        if data.type == Sound_Data.Type.OGG_COMPRESSED {
            page_size: s64 = 8000;
            decoder := create_ogg_decoder(data, page_size);
            stream.decoder = decoder;
            decoder.stream = stream;

            decoder.add_decode_queue_item = add_decode_queue_item;

            if CACHED_OGG_DECODE_THREADED {
                decoder.do_not_queue = false;
            } else {
                decoder.do_not_queue = true;
            }

//            sound_data := stream.sound_data;
//            print("***** channels %, samples %\n", sound_data.nchannels, sound_data.nsamples_times_nchannels);
        }

        if data.type == Sound_Data.Type.ADPCM_COMPRESSED {
            decoder := create_adpcm_decoder(data);
            stream.decoder = *decoder.base;
            decoder.stream = stream;

            decoder.add_decode_queue_item = add_decode_queue_item;
        }


        if stream.decoder {
            if !stream.decoder.do_not_queue  stream.flags |= Sound_Stream.WAITING_FOR_INITIAL_DECODER_PAGES;
        }

    }




    stream.player = player;
    array_add(*streams, stream);

    stream.universe = universe;


    num_source_samples: s64 = data.nsamples_times_nchannels / data.nchannels;

    stream.silent_samples_at_start_of_play = cast(int) floor(sound.pre_play_silence * OUTPUT_SAMPLING_RATE + 0.5);
    stream.sound_data = data;
    stream.portable_id = sound.portable_id;
    stream.manager_id = manager.my_manager_id;
    stream.num_channels = stream.sound_data.nchannels;  // @Cleanup: Redundant?
    stream.position = to_vec3(sound.position);
    stream.repeat_start_position = sound.repeat_start_position;
//    stream.repeat_end_position = num_source_samples + data.silence_before_repeat * OUTPUT_SAMPLING_RATE;  Feature disabled because it wasn't working and I have to ship.
    stream.repeat_end_position = num_source_samples;

    if sound.flags & ISSUED_SOUND_REPEATING    stream.flags |= Sound_Stream.REPEATING;
    if sound.flags & ISSUED_SOUND_SPATIALIZED  stream.flags |= Sound_Stream.SPATIALIZED;
    if sound.flags & ISSUED_SOUND_DO_NOT_KILL  stream.flags |= Sound_Stream.DO_NOT_KILL;
    if sound.flags & ISSUED_SOUND_AMBIENT      stream.flags |= Sound_Stream.AMBIENT;


    update_desired_rate(stream, sound);
    stream.current_rate = stream.desired_rate;

    for i: 0..stream.num_channels-1 {
        assert(i < MAX_CHANNELS_PER_SOUND);
        init(*stream.input_scale_mappings[i]);
    }

    stream.play_cursor = 0;
    if sound.duration_total {
        t := (sound.my_time / sound.duration_total) * num_source_samples;
        //assert(t < 10000000);
        stream.play_cursor = t;
    }

    // print("stream % play_cursor %\n", stream, stream.play_cursor);

    maybe_wrap_play_cursor(stream);

    stream.play_cursor -= cast(float64) stream.silent_samples_at_start_of_play;  // We implement silence by starting with a negative play_cursor.

    if is_music  stream.flags |= Sound_Stream.IS_MUSIC;  // Must happen before volume settings below.

    update_panning(player, stream, sound);

    return stream;
}


stop_all_music :: (using player: *Sound_Player, portable_id_of_exception: s64, universe_designator: s64, abrupt: bool) {
    lock(sound_mutex);
    defer unlock(sound_mutex);

    for stream : streams {
        if stream.portable_id == portable_id_of_exception continue;

        if stream.flags & Sound_Stream.IS_MUSIC {
            if stream.universe != universe_designator continue;

            if abrupt {
                // first remove stream from valid streams and then release sound (release() might call stop_stream_abruptly())
                if stream.sound_name     // if it's catalogued
                    release(null, stream.sound_data);
                remove stream;
                destroy(stream);
                delete stream;
            } else {
                stream.flags |= Sound_Stream.FADING_OUT;
                stream.portable_id = 0;
            }

            continue;
        }
    }    
}

stop_stream_abruptly :: (using player: *Sound_Player, id: s64) {
    lock(sound_mutex);
    defer unlock(sound_mutex);

    for stream : streams {
        if stream.portable_id != id continue;

        // first remove stream from valid streams and then release sound (release() might call stop_stream_abruptly())
        remove stream;

        if stream.sound_name     // if it's catalogued
            release(null, stream.sound_data);
        delete stream;
    }    
}

stop_stream_abruptly :: (using player: *Sound_Player, data: *Sound_Data) {
    lock(sound_mutex);
    defer unlock(sound_mutex);

    for stream : streams {
        if stream.sound_data != data continue;
        // first remove stream from valid streams and then release sound (release() might call stop_stream_abruptly())
        remove stream;
        
        if stream.sound_name     // if it's catalogued
            release(null, stream.sound_data);
        delete stream;
    }    
}

stop_all_sounds_abruptly :: (using player: *Sound_Player, manager_id: s64) {
    lock(sound_mutex);
    defer unlock(sound_mutex);

    for stream : streams {
        if stream.manager_id != manager_id continue;

        // first remove stream from valid streams and then release sound (release() might call stop_stream_abruptly())
        remove stream;

        if stream.sound_name {    // if it's catalogued
            release(null, stream.sound_data);
        }
        
        delete stream;
    }    
}


find_music_stream :: (streams: [] *Sound_Stream, sound_name: string, universe: s64) -> *Sound_Stream {
    for stream: streams {
        if !stream.sound_data continue;
        if stream.universe != universe continue;
        if stream.sound_data.name == sound_name return stream;
    }

    return null;
}

stream_is_done :: (using player: *Sound_Player, sound: *Entity_Issued_Sound) -> bool {
    manager_id  := sound.entity_manager.my_manager_id;
    portable_id := sound.portable_id;

    stream := find(player, portable_id, manager_id);
    if !stream return false;

    if stream.flags & Sound_Stream.REPEATING return false;

    data := stream.sound_data;
    num_source_samples := data.nsamples_times_nchannels / data.nchannels;

    if sound.rate_scale < 0 {
        if stream.play_cursor < 0 return true;
    } else {
        if stream.play_cursor >= cast(float64) num_source_samples return true;
    }

    return false;
}



get_desired_volume_perceptual :: (player: *Sound_Player, sound: *Entity_Issued_Sound, stream: *Sound_Stream,
                                  position: Vector3) -> float {
    if stream.flags & Sound_Stream.FADING_OUT return 0;

    volume := stream.sound_data.volume_scale * sound.volume_scale;

    // Scale volume by category.

    scale := player.mix_all;
    if sound.sound_category == SOUND_CATEGORY_PROPS  scale *= player.mix_props;
    else if sound.sound_category == SOUND_CATEGORY_FOOTSTEPS  scale *= player.mix_footsteps;
    else if sound.sound_category == SOUND_CATEGORY_UI  scale *= player.mix_ui;
    else if sound.sound_category == SOUND_CATEGORY_AMBIENCES  scale *= player.mix_ambiences;

    volume *= scale;

    volume *= stream.volume_scale_due_to_entity_manager;

    volume *= player.master_volume;

    if (!player.have_listener) return volume;


    if (stream.flags & Sound_Stream.SPATIALIZED) {
        dist: float = distance(player.listener_position, position);
        t: float = (dist - sound.outer_radius) / (sound.inner_radius - sound.outer_radius);
        Clamp(*t, 0, 1);
        //t *= t;

        volume *= t;
    }

    return volume;
}


do_stream_entity_pass :: (using player: *Sound_Player, manager: *Entity_Manager, volume: float) {
    if !manager return;

    //
    // Add streams for any audio event that we aren't currently tracking.
    //

    for sound : manager.issued_sounds {
        portable_id: s64 = sound.portable_id;
        
        stream := find(player, portable_id, manager.my_manager_id);

        if !stream {
            is_music := false;
            universe := UNIVERSE_USUAL;
            
//            if sound.entity_manager == globals.menu_audio_entity_manager
//                universe = UNIVERSE_MENU;

            stream = create_stream(player, sound, universe, is_music, manager);

            if stream {
                stream.sound_name = copy_string(sound.sound_name);
            }

                
        }

        if !stream continue;  // We failed to make it, for some reason.

        assert(stream != null);

        stream.marked = true;
        stream.orientation = sound.orientation;
        stream.position = to_vec3(sound.position);

        stream.inaudible = cast(bool) (sound.entity_flags & ENTITY_INVISIBLE);

        usual_scale, menu_scale := get_entity_manager_audio_volumes();

        if stream.universe == UNIVERSE_MENU {
            stream.volume_scale_due_to_entity_manager = menu_scale;
        } else {
            stream.volume_scale_due_to_entity_manager = usual_scale;
        }

        update_desired_rate(stream, sound);
        update_panning(player, stream, sound);

        if stream.decoder {
            // Prefetch any data we may need to play. (The decompression will happen on another core, maybe!)

            decoder := stream.decoder;
            data    := stream.sound_data;

            seconds_to_fetch := SECONDS_TO_FETCH_OGG;
            if decoder.type == Decoder_Type.DECODER_ADPCM  seconds_to_fetch = SECONDS_TO_FETCH_ADPCM;

            samples_to_fetch := cast(s64) (stream.current_rate * data.sampling_rate * seconds_to_fetch);
            if samples_to_fetch > stream.repeat_end_position  samples_to_fetch = stream.repeat_end_position;

            at_least := stream.decoder.page_size_in_samples * 3;  // We want to make sure we are reading some pages ahead, otherwise we can miss deadlines. Some videos, for example, with mono audio, end up being late a lot.

            if samples_to_fetch < at_least  samples_to_fetch = at_least;

            forward_sample := cast(s64) stream.play_cursor + samples_to_fetch;

            // Casting to float just to do math with int is a pain in the ass.
            // I am pretty sure I am going to change the coercion rules so that
            // you can just do this without casting.
            TOO_MANY_PAGES_PENDING := cast(s64) (data.sampling_rate / decoder.page_size_in_samples * seconds_to_fetch * 4.0);

            if stream.flags & Sound_Stream.WAITING_FOR_INITIAL_DECODER_PAGES {
                stream.samples_needed_to_start_playing =  ((samples_to_fetch * 4) / 5);
            }


            unmark_all_pages(decoder);

            if (decoder.issued_start_addresses.count > TOO_MANY_PAGES_PENDING) {
                //
                // We are falling behind and unable to process audio as quickly as we need to.
                // Just let this drain out, don't ask for new pages.
                //
            } else {
                mark_relevant_pages(decoder, cast(s64) stream.play_cursor, forward_sample);

                if stream.flags & Sound_Stream.REPEATING {
                    if forward_sample > stream.repeat_end_position {
                        forward_sample -= stream.repeat_end_position;
                        mark_relevant_pages(decoder, stream.repeat_start_position, forward_sample);
                    }
                }
            }

            delete_unmarked_pages(decoder);
        }


        stream.samples_streamed_since_entity_update = 0;
        offset: s64 = 0;
    }

/*  
    We can switch to a loop like this later when it becomes too slow to iterate over all sounds.
    The thing is, we need to make sure the sounds' radii get properly set for the Entity_Manager::find to work.
    Or create a new find function just for sounds.

    zones: [] Entity;
    if (have_listener) {
        manager.find(listener_position, 0, &zones);

        Entity *e;
        Array_Foreach(&zones, e) {
            if (e.portable_type != &ptype_Ambient_Sound_Zone) continue;
            Entity_Ambient_Sound_Zone *zone = (Entity_Ambient_Sound_Zone *)e;
            if (!zone.sound_name) continue;
        }
    }
*/
}

update_from_main_thread :: (using player: *Sound_Player, camera_position: Vector3, camera_orientation: Quaternion) {
    lock(sound_mutex);
    defer unlock(sound_mutex);

    listener_position = camera_position;
    have_listener = true;
    
    ori := camera_orientation;
    listener_orientation = ori;

    listener_forward = rotate(axis_forward, ori);
    listener_left    = rotate(axis_left,    ori);
    listener_up      = rotate(axis_up,      ori);

    listener_theta = -atan2(-listener_left.y, -listener_left.x);  // @Temporary @FixMe: Why -atan2?

/*
    e := get_the_player_entity();

    if e && (e.portable_type == *ptype_Human) {
        human := cast(*Entity_Human)e;  // @Note: I think this is deprecated, but if it isn't, this won't work during the flythrough unless we move Human around.
        listener_indoor_zone_scale = human.interior_zone_volume;
        listener_outdoor_zone_scale = human.exterior_zone_volume;
    }
*/

    // Clear all markers.
    for streams it.marked = false;

    for entity_managers 
        do_stream_entity_pass(player, it, 1.0);

    for stream : streams {
        if (stream.flags & Sound_Stream.FADING_OUT) {
            if (stream.silent_this_frame) {
                stream.flags &= ~Sound_Stream.IS_MUSIC;
                stream.marked = false;
            }
        }

        if (!stream.marked) {
            // Music streams in UNIVERSE_USUAL get a pass...
            if (stream.flags & Sound_Stream.IS_MUSIC) {
            } else if (stream.flags & Sound_Stream.DO_NOT_KILL) {
            } else {
                // first remove stream from valid streams and then release sound (release() might call stop_stream_abruptly())
                if stream.sound_name     // if it's catalogued
                    release(null, stream.sound_data);
                remove stream;
                delete stream;
                continue;
            }
        }

    }

    //
    // Look for any pages that are done decompressing; pull them in if so.
    //

    while (1) {
    /*

      This part is still going to be ugly for a little bit until I combine the
      decoder classes. So far I have only combined decoder pages.

    */

        page := get_next_completed_decode_queue_item();
        if !page break;

        assert(page.owner != null);

        found := array_unordered_remove(*page.owner.issued_start_addresses, page.start_address);
        assert(found >= 0);

        array_add(*page.owner.pages, page);

        if page.owner.stream && (page.owner.stream.flags & Sound_Stream.WAITING_FOR_INITIAL_DECODER_PAGES) {
            page.owner.stream.initial_samples_fetched += page.num_samples_contained;
        }
	}

    //
    // Wake up any streams that are ready.
    // We used to do this only when pages come in, which is the most efficient
    // thing, but there were some complexities regarding sounds that have
    // silence at the beginning, etc.   -jblow, 22 May 2015
    //

    for stream : streams {
        if !(stream.flags & Sound_Stream.WAITING_FOR_INITIAL_DECODER_PAGES) continue;

        fetched: s64 = stream.initial_samples_fetched;

        if stream.play_cursor < 0 { // We have this much silence to count!
            fetched += cast(s64) (-(stream.play_cursor + 0.5));
        }

        //
        // Note: This is maybe not really right since it doesn't ensure that all these pages
        // are sequential from the beginning, and it's unclear whether there are some cases
        // in which that might not happen.   -jblow, 22 May 2015
        //

        // print("Stream % fetched % needed %\n", stream.sound_data.name, fetched, stream.samples_needed_to_start_playing);
        
        if fetched >= stream.samples_needed_to_start_playing {
            stream.flags &= ~Sound_Stream.WAITING_FOR_INITIAL_DECODER_PAGES;
        }
    }


    //
    // Check the retired_decoders array to see if anyone is done.
    //

    for decoder : retired_decoders {
        clear_pages(decoder); // In case new pages have come in.

        if decoder.issued_start_addresses.count continue; // This guy still has work out, can't delete him.
        remove decoder;
        delete decoder;
    }

    if !handler_initted {
        // Just advance the streams as though they were playing.
        dt := Core.time_info.current_real_world_dt;

        for stream : streams {
            stream.current_rate = stream.desired_rate;
            stream.play_cursor += dt * cast(float)(stream.sound_data.sampling_rate) * stream.current_rate;
            maybe_wrap_play_cursor(stream);
        }
    } else {
        if handler {
            if needs_async_update_from_main_thread(handler) {
                update_from_async_thread(player, false);
            }
        }
    }
}


get_audio_sampling_rate :: () -> s64 {
    return OUTPUT_SAMPLING_RATE;
}


get_audio_output_channel_names :: (handler: *Sound_Handler, names: *[..] string) {
    if !names return;

    for handler.channel_names array_add(names, it);
}

init :: (using target: *Scale_Mapping) {
    for i: 0..OUTPUT_CHANNELS_MAX-1 {
        source_scale_for_this_output_index[i] = 0;
        interpolated_source_scale_for_this_output_index[i] = 0;
    }
}

/*

    Decode Queue management ... handles the asynchronous decompression of
    compressed pages of audio.

*/


decode_queue_initted := false;

decode_queue: [..] *Cached_Decoder_Page;
decode_queue_lock: Mutex;
decode_condition: Condition;

completed_queue: [..] *Cached_Decoder_Page;
completed_queue_lock: Mutex;



init_sound_player_decode_queue :: () {
    if decode_queue_initted return;

    init(*decode_queue_lock);
    init(*completed_queue_lock);
    init(*decode_condition);    // Ugh ... we don't have condition variables yet! This is going to be interesting.

	decode_queue_initted = true;

    if CACHED_OGG_DECODE_THREADED {
        thread := thread_create(thread_proc);
        if thread  thread_start(thread);
    }
}



process_one_page :: (page: *Cached_Decoder_Page) {
    if page.type == Decoder_Type.DECODER_OGG {
        owner := cast (*Cached_Ogg_Decoder) page.owner;
        owner.recompute_page(page.owner, page);
    } else {
        assert(page.type == Decoder_Type.DECODER_ADPCM);
        assert(false);  // We are not handling ADPCM yet.
    }        

    lock(*completed_queue_lock);
    array_add(*completed_queue, page);
    unlock(*completed_queue_lock);
}

thread_proc :: (thread: *Thread) -> s64 {
    // @Incomplete: Provide hooks for us to set thread priority.

    // os_set_thread_priority(THREAD_PRIO_NORMAL);
    // os_set_thread_affinity(THREAD_AFFINITY_LOW_PRIORITY_THREAD);

    while true {
        while true {
            page: *Cached_Decoder_Page;

            lock(*decode_queue_lock);
            assert(decode_queue.count >= 0);

            if decode_queue.count {
                page = decode_queue[0];
                array_ordered_remove_by_index(*decode_queue, 0);
            }

            unlock(*decode_queue_lock);

            handled := false;
            if page {
                process_one_page(page);
                handled = true;
            }

            if !handled break;
        }

        wait_for(*decode_condition);
    }
}


add_decode_queue_item :: (page: *Cached_Decoder_Page) {
    assert(decode_queue_initted);

    if CACHED_OGG_DECODE_THREADED {
        lock(*decode_queue_lock);
        array_add(*decode_queue, page);
        unlock(*decode_queue_lock);

        signal(*decode_condition);
    } else {
        process_one_page(page);  // This will add it to the completed queue.
    }
}

get_next_completed_decode_queue_item :: () -> *Cached_Decoder_Page {
    assert(decode_queue_initted);

    result: *Cached_Decoder_Page;

    lock(*completed_queue_lock);

    if completed_queue.count {
        result = completed_queue[0];
        array_ordered_remove_by_index(*completed_queue, 0);
    }
    
    unlock(*completed_queue_lock);

	return result;
}


