#import "Basic"
#import "Print"
#import "GL"
#import "Pool"
#import "Math"
#import "File"
#import "Compiler"
#import "Font"
#import "Random"
#import "Math"
#import "Mixer"
#import "Wav_File"
#import "Entity_Manager"

#import "Cached_Decoder"

#import "stb_image"
#import "stb_vorbis"

#load "entities.jai"
#load "levels.jai"

//
// @Cleanup: Incorporate these into Entity_Manager in some
// prefab way:
//

live_invaders : [..] * Invader;
live_emitters : [..] * Particle_Emitter;
live_pickups  : [..] * Pickup;

bullets : [..] * Bullet;


DIR :: "/jai/traveller";

WINDOW_WIDTH  :: 3200; 
WINDOW_HEIGHT :: 1800;

BIG_FONT_SIZE :: 116;
CHINESE_FONT_SIZE :: 120;


key_left : u32;
key_right : u32;
key_up : u32;
key_down : u32;

should_quit_game := false;

current_dt : float = 0.016667;
last_time : float64;
DT_MAX : float : 0.15;

live_y_max := 1.0;
live_y_min := -0.1;

num_desired_invaders : int = 15;
INVADER_RADIUS :: 0.03;
BULLET_RADIUS :: 0.003;

PICKUP_SPEED :: -0.15;
PICKUP_SIZE :: 0.01;

SHIP_RADIUS :: 0.03;
SHIP_INVINCIBILITY_TIME :: 8.0;
SHIP_V_SHOT_TIME :: 20.0;

shot_index : int = 0;

num_invaders_destroyed : int = 0;

entity_manager : Entity_Manager;

level_index : int = 0;

the_font : *Dynamic_Font;
italics_font : *Dynamic_Font;
italics_font_small : *Dynamic_Font;
chinese_font : *Dynamic_Font;

back_buffer_width:  int;
back_buffer_height: int;

Shot_Type :: enum u32 {
    STRAIGHT_SINGLE : 0,
    STRAIGHT_DOUBLE,
    STRAIGHT_TRIPLE,
}


ship_position : Vector2;
ship_destroyed := false;
ship_shot_type := Shot_Type.STRAIGHT_SINGLE;               
ship_shot_cooldown := 0.0;
ship_shot_cooldown_per_bullet := 0.4;
ship_invincibility_countdown := 0.0;
ship_v_shot_countdown := 0.0;

end_game_countdown : float = -1.0;

sound_player : *Sound_Player;

Sound_Catalog_Entry :: struct {
    name: string;
    sound_data: *Sound_Data;
}

Sound_Catalog :: struct {
    entries: [..] Sound_Catalog_Entry;
}

the_sound_catalog: *Sound_Catalog;


find_or_load :: (using catalog: *Sound_Catalog, name: string, extension: string) -> *Sound_Data {
    for entries {
        if it.name == name return it.sound_data;
    }

    if extension == "wav" || !extension {
        wav_name := sprint("%.wav", name);
        defer free(wav_name.data);

        data := load_wav_file(name, wav_name);
        if data {
            entry : Sound_Catalog_Entry;
            entry.name = copy_string(name);
            entry.sound_data = data;

            array_add(*entries, entry);
        }

        return data;
    } else if extension == "ogg" {
        ogg_name := sprint("%.ogg", name);
        defer free(ogg_name.data);

        result, success := read_entire_file(ogg_name);
        assert(success);

        if !result return null;

        data := new Sound_Data;
        data.name = copy_string(name);
        data.type = Sound_Data.Type.OGG_COMPRESSED;
        data.buffer = result;
        
/*
        channels, sample_rate: s32;
        output: *s16;

        num_samples := stb_vorbis_decode_filename(c_ogg_name, *channels, *sample_rate, *output);

        print("name is '%'; num_samples is %\n", ogg_name, num_samples);

        num_bytes := num_samples * channels * size_of(s16);   // @Hardcode @Volatile, must change with type of output.

        data.type = Sound_Data.Type.LINEAR_SAMPLE_ARRAY;
        data.buffer.data = cast(*u8) output;
        data.buffer.count = num_bytes;
        data.samples = output;
        data.nsamples_times_nchannels = num_samples * channels;
        data.nchannels = cast(u16) channels;
        data.sampling_rate = cast(u32) sample_rate;
*/
        return data;
    } else {
        print("Unknown extension '%' in find_or_load!\n", extension);
        assert(false);
        return null;
    }
}


to_vec3 :: (v: Vector2) -> Vector3 {
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

load_wav_file :: (basename: string, name: string) -> *Sound_Data {
    result, success := read_entire_file(name);
    if !result return null;

    // print("File '%' is % bytes.\n", name, result.count);
    
    format, samples, success2, extra := get_wav_header(result);
    if !success2 {
        print("Unable to parse '%' as wav.\n", name);
        return null;
    }

    // print("================ '%' format tag is: %\n", basename, format.wFormatTag);

    data := new Sound_Data;

    if format.wFormatTag == WAVE_FORMAT_PCM {
        data.type = Sound_Data.Type.LINEAR_SAMPLE_ARRAY;
        data.nchannels = cast(u16) format.nChannels;
        data.nsamples_times_nchannels = samples.count/2;
    } else if format.wFormatTag == WAVE_FORMAT_DVI_ADPCM {
        data.type = Sound_Data.Type.ADPCM_COMPRESSED;
        data.wSamplesPerBlock = extra.wSamplesPerBlock;
        data.nBlockAlign = format.nBlockAlign;

        data.nchannels = cast(u16) format.nChannels;
        data.nsamples_times_nchannels = extra.wSamplesAccordingToFactChunk * data.nchannels;
    } else {
        assert(false);
    }

    data.name = copy_string(basename);
    data.buffer = result;
    data.samples = cast(*s16) samples.data;
    data.sampling_rate = cast(u32) format.nSamplesPerSec;
    
    return data;
}

Entity_Issued_Sound :: struct {
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


play_sound :: (manager: *Entity_Manager, data: *Sound_Data, perturb: bool = true) -> *Entity_Issued_Sound {
    sound := new Entity_Issued_Sound;
    sound.entity = get_new_entity();
    sound.sound_name = copy_string(data.name);
    sound.sound_data = data;

    array_add(*manager.issued_sounds, sound);

    if perturb {
        sound.volume_scale = random_get_within_range(0.7, 1.0);
        sound.rate_scale = random_get_within_range(0.7, 1.22);
    }
    
    safety : float : 1.1;

    nsamples := data.nsamples_times_nchannels / data.nchannels;
    
    sound.my_lifetime = ((cast(float) nsamples / cast(float)data.sampling_rate) / sound.rate_scale) * safety;

    return sound;
}

play_sound :: (manager: *Entity_Manager, name: string, perturb: bool = true, extension := "") -> *Entity_Issued_Sound {
    data := find_or_load(the_sound_catalog, name, extension);
    if !data return null;

    if data.nchannels == 0 {
        print("Error: No channels in input sound!\n");
        return null;
    }

    return play_sound(manager, data, perturb);
}



main :: () {
    setcwd(DIR);
    array_add(*entity_managers, *entity_manager);
    invaders();
}

update_proc_nothing :: (self: * Invader) {
    // Do nothing!
}

update_proc_side :: (self: * Invader) {
    rate :: 1.5;
    theta := last_time * TAU64 * rate;
    y := cos(cast(float) theta);

    self.position.y += y * 0.004;
}

update_proc_circle :: (self: * Invader) { 
    rate :: 1.5;
    theta := last_time * TAU64 * rate;
    x := cos(cast(float) theta);
    y := sin(cast(float) theta);

    self.position.x += x * 0.004;
    self.position.y += y * 0.004;
}

NUM_UPDATE_PROCS :: 3;


/*
print_bytes :: (data : * u8, num_bytes : int) {
    if !data then return;

    printf("[print_bytes:]  ");

    for 0..num_bytes-1 printf("%02x ", cast(u32) data[it]);

    printf("\n");

}
*/


get_new_entity :: () -> *Entity {
    e := get_new_entity(*entity_manager);
    e.entity_manager = *entity_manager;
    reset_entity(e);
    return e;
}

reset_entity :: (e : *Entity) {
    e.map = null;
    e.velocity.x = 0;
    e.velocity.y = 0;
}

release_entity :: (e : *Entity) {
    batch := entity_manager.batches[e.batch_index];
    batch.occupied[e.slot_index] = false;
}

Particle :: struct {
    position: Vector2;
    velocity: Vector2;

    size: float = 0;
    lifetime: float = 2;
    drag: float = 1;
    color: Vector4;

    elapsed: float = 0;
}

Particle_Emitter :: struct {
    using entity : * Entity;

    particles: [..] Particle;
    fadeout_period : float = 0.1;
    particles_per_second : float = 150;

    speed0 : float = 0;
    speed1 : float = 0.1;

    size0 : float = 0.001;
    size1 : float = 0.005;

    drag0 : float = 0.9999;
    drag1: float = 0.9;

    lifetime0: float = 0.4;
    lifetime1: float = 1.0;

    emitter_lifetime := -1.0;

    theta0: float = 0;
    theta1: float = TAU;

    color0: Vector4;
    color1: Vector4;

    elapsed : float = 0;
    remainder : float = 0;

    producing := true;
}


invader_maps : [..] *Texture_Map;

ship_map                : *Texture_Map;
ship_bullet_map         : *Texture_Map;
invader_bullet_map      : *Texture_Map;
contrail_map            : *Texture_Map;
pickup_map_v_shot       : *Texture_Map;
pickup_map_shield       : *Texture_Map;
pickup_map_extra_bullet : *Texture_Map;

find_shield_loop :: (manager : *Entity_Manager) -> *Entity_Issued_Sound {
    for manager.issued_sounds
        if it.sound_name == "shield_loop" return it;

    return null;
}

ensure_shield_loop_playing :: (manager: *Entity_Manager) {
    sound := find_shield_loop(manager);
    if sound return;

    sound = play_sound(manager, "shield_loop");
    if sound sound.flags |= ISSUED_SOUND_REPEATING;
}

ensure_shield_loop_not_playing :: (manager: *Entity_Manager) {
    sound := find_shield_loop(manager);
    if !sound return;

    // @Refactor: Put this kind of thing into a more general destroy-entity
    // function that we don't have to think too hard about.
    removed := array_unordered_remove(*manager.issued_sounds, sound);
    assert(removed > 0);

    release_entity(sound.entity);
    delete sound;
}
    
linear_move :: (position : * Vector2, velocity : * Vector2, dt : float) {
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;
}

update_emitter :: (emitter : * Particle_Emitter) {
    dt := current_dt;

    for * emitter.particles {
        sim_particle(it, dt);
        if it.elapsed > it.lifetime remove it;
    }

    dt_per_particle := 1.0 / emitter.particles_per_second;
    if running_at_compile_time() then dt_per_particle *= 4.0;


    emitter.elapsed += dt;
    emitter.remainder += dt;

    if emitter.emitter_lifetime >= 0 then {
        emitter.emitter_lifetime -= dt;
        if emitter.emitter_lifetime < 0 then emitter.producing = false;
    }

    if emitter.producing then {
        while emitter.remainder > dt_per_particle {
            emitter.remainder -= dt_per_particle;
            p := spawn_particle(emitter);
            sim_particle(p, emitter.remainder);
        }
    } else {
        if emitter.particles.count == 0 then {
            array_unordered_remove(*live_emitters, emitter);
            release_entity(emitter.entity);
            delete emitter;
        }
    }
  
    //
    // Helper functions:
    //
    spawn_particle :: (emitter : * Particle_Emitter) -> * Particle {
        p : Particle;
        
        p.position = emitter.position;
        p.velocity = emitter.velocity;

        p.size = random_get_within_range(emitter.size0, emitter.size1);
        p.drag = random_get_within_range(emitter.drag0, emitter.drag1);
        p.lifetime = random_get_within_range(emitter.lifetime0, emitter.lifetime1);

        color_t : float = random_get_within_range(0, 1);
        p.color = lerp(emitter.color0, emitter.color1, color_t);

        speed := random_get_within_range(emitter.speed0, emitter.speed1);
        theta := random_get_within_range(emitter.theta0, emitter.theta1);

        ct := cos(theta);
        st := sin(theta);
        
        v_rel : Vector2;
        v_rel.x = speed * ct;
        v_rel.y = speed * st;
        p.velocity.x += v_rel.x;
        p.velocity.y += v_rel.y;

        array_add(*emitter.particles, p);
        return *emitter.particles[emitter.particles.count - 1];
    }

    sim_particle :: (p : * Particle, dt : float) {
        linear_move(*p.position, *p.velocity, dt);

        // @Incomplete: Apply correct drag over time.
        drag: float = p.drag;

        p.velocity.x *= drag;
        p.velocity.y *= drag;

        p.elapsed += dt;
    }
}


init_invader :: (invader : * Invader) {
    init_target(invader);

    INITIAL_Y := 0.8;
    invader.x = invader.target_position.x;
    invader.position.y = INITIAL_Y;
}

init_target :: (invader : * Invader) {
    b := 0.05;
    invader.target_position.x = random_get_within_range(b, 1.0-b);
    invader.target_position.y = random_get_within_range(.2, .7);
}

add_invader :: () {
    invader := new Invader;
    invader.entity = get_new_entity();

    which := random_get() % invader_maps.count;
    invader.map = invader_maps[which];

    init_invader(invader);
    array_add(*live_invaders, invader);

    // Update procs:

    update_roll := random_get() % NUM_UPDATE_PROCS;

    if update_roll == 1 then invader.update_proc = update_proc_side;
    if update_roll == 2 then invader.update_proc = update_proc_circle;
}

ilength :: (x: float, y: float) -> float {
    length := x * x + y * y;
    denom := 1.0 / sqrt(length);
    return denom;
}

distance :: (a: Vector2, b: Vector2) -> float {
    dx := b.x - a.x;
    dy := b.y - a.y;

    return sqrt(dx*dx + dy*dy);
}

simulate_invaders :: () {
    for live_invaders {
        if it.sleep_countdown < 0 {
            speed := 0.3;
            delta := speed * current_dt;

            dx := it.target_position.x - it.position.x;
            dy := it.target_position.y - it.position.y;

            denom := ilength(dx, dy);
            dx *= denom;
            dy *= denom;

            if distance(it.position, it.target_position) <= delta then {
                it.sleep_countdown = random_get_within_range(0.1, 1.5);

                it.position.x = it.target_position.x;
                it.position.y = it.target_position.y;
            } else {
                it.position.x += dx * delta;
                it.position.y += dy * delta;
            }
        }

        if it.sleep_countdown >= 0 then {
            it.sleep_countdown -= current_dt;
            if it.sleep_countdown < 0 then {
                roll := random_get() % 100;
                if roll < 60 {
                    invader_fire_bullet(it);
                    init_target(it);
                }
            }
        }

        if it.update_proc then (it.update_proc)(it);
    }
}

make_emitter :: () -> *Particle_Emitter {
    emitter := new Particle_Emitter;
    emitter.entity = get_new_entity();

    return emitter;
}

destroy_invader :: (invader : * Invader) {
    num_invaders_destroyed += 1;

    array_unordered_remove(*live_invaders, invader);

    {
        emitter := make_emitter();
        array_add(*live_emitters, emitter);

        emitter.size0 = 0.0004;
        emitter.size1 = 0.005;

        emitter.speed0 = 0.1;
        emitter.speed1 = 0.3;

        emitter.color0 = make_vector4(1, 1, 0.3, 1);
        emitter.color1 = make_vector4(1, 1, 1, 1);

        emitter.fadeout_period = 0.1;
        emitter.emitter_lifetime = 0.2;

        emitter.position = invader.position;
    }

    {
        emitter := make_emitter();
        array_add(*live_emitters, emitter);

        emitter.size0 = 0.01;
        emitter.size1 = 0.04;
    
        emitter.color0 = make_vector4(1, 1, 1, 1);
        emitter.color1 = make_vector4(1, 0.7, 0.1, 1);

        emitter.fadeout_period = 0.3;
        emitter.emitter_lifetime = 0.3;

        emitter.position = invader.position;
    }

    drop_roll := random_get() % 100;
    if drop_roll < 50 {
        pickup := new Pickup;
        pickup.entity = get_new_entity();
        array_add(*live_pickups, pickup);


        roll := random_get() % 100;

        pickup.position = invader.position;
        pickup.velocity = make_vector2(0, PICKUP_SPEED * random_get_within_range(0.7, 1.7));

        if roll < 10 {
            pickup.type = Pickup_Type.SHIELD;
            pickup.map = pickup_map_shield;
        } else if roll < 25 {
            pickup.type = Pickup_Type.V_SHOT;
            pickup.map = pickup_map_v_shot;
        } else {
            pickup.type = Pickup_Type.EXTRA_BULLET;
            pickup.map = pickup_map_extra_bullet;
        }
    }

    play_sound(*entity_manager, "alien_dies");
}

destroy_ship :: () {
    num_invaders_destroyed += 1;

    ship_destroyed = true;
    end_game_countdown = 3.0;

    position := ship_position;
    {
        emitter := make_emitter();
        array_add(*live_emitters, emitter);

        emitter.size0 = 0.0004;
        emitter.size1 = 0.005;
    
        emitter.speed0 = 0.1;
        emitter.speed1 = 0.3;

        emitter.color0 = make_vector4(1, 1, 0.3, 1);
        emitter.color1 = make_vector4(1, 1, 1, 1);

        emitter.fadeout_period = 0.1;
        emitter.emitter_lifetime = 0.2;

        emitter.position = position;
    }

    {
        emitter := make_emitter();
        array_add(*live_emitters, emitter);

        emitter.size0 = 0.01;
        emitter.size1 = 0.04;
    
        emitter.color0 = make_vector4(1, 1, 1, 1);
        emitter.color1 = make_vector4(.94, 1, 0.05, 1);

        emitter.fadeout_period = 0.3;
        emitter.emitter_lifetime = 0.3;

        emitter.position = position;
    }

    play_sound(*entity_manager, "player_dies");
}

test_against_invaders :: (bullet: * Bullet) -> bool {
    for live_invaders {
        if distance(bullet.position, it.position) < INVADER_RADIUS then {
            destroy_invader(it);
            return true;
        }
    }

    return false;                              
}

test_against_ship :: (position : Vector2, radius: float) -> bool {
    if ship_destroyed then return false;

    return distance(position, ship_position) < radius + SHIP_RADIUS;

//    if distance(position, ship_position) < radius + SHIP_RADIUS then return true;

//    return false;
}

player_got_pickup :: (pickup : * Pickup) {
    if pickup.type == Pickup_Type.EXTRA_BULLET {
        if ship_shot_type == Shot_Type.STRAIGHT_SINGLE then ship_shot_type = Shot_Type.STRAIGHT_DOUBLE;
        else if ship_shot_type == Shot_Type.STRAIGHT_DOUBLE then ship_shot_type = Shot_Type.STRAIGHT_TRIPLE;
        else if ship_shot_type == Shot_Type.STRAIGHT_TRIPLE then {
            ship_shot_type = Shot_Type.STRAIGHT_SINGLE;
            play_sound(*entity_manager, "too_many_bullets");
        }
    } else if pickup.type == Pickup_Type.SHIELD {
        if ship_invincibility_countdown <= 0   {
            play_sound(pickup.entity_manager, "shield_begin");
            ensure_shield_loop_playing(pickup.entity_manager);
        }

        ship_invincibility_countdown = SHIP_INVINCIBILITY_TIME;
    } else if pickup.type == Pickup_Type.V_SHOT {
        ship_v_shot_countdown += SHIP_V_SHOT_TIME;
    }
}


ship_is_shielded :: () -> bool {
    if ship_invincibility_countdown > 0 then return true;
    return false;
}

simulate_pickups :: () {

    simulate_pickup :: (pickup : * Pickup) -> bool {
        linear_move(*pickup.position, *pickup.velocity, current_dt);

        if pickup.position.y > live_y_max then return true;
        if pickup.position.y < live_y_min then return true;

        if test_against_ship(pickup.position, PICKUP_SIZE) then {
            if ship_is_shielded() {
                play_sound(pickup.entity_manager, "pickup_fail");
            } else {
                player_got_pickup(pickup);
                play_sound(pickup.entity_manager, "pickup_succeed");
            }

            return true;
        }

        return false;
    }


    for live_pickups {
        done := simulate_pickup(it);
        if done then {
            release_entity(it.entity);
            remove it;
            delete it;
        }
    }
}


simulate_bullets :: () {
    simulate_bullet :: (bullet : * Bullet) -> bool {
        linear_move(*bullet.position, *bullet.velocity, current_dt);

        if bullet.position.y > live_y_max then return true;
        if bullet.position.y < live_y_min then return true;

        bullet.emitter.position = bullet.position;
        bullet.emitter.velocity = bullet.velocity;

        if bullet.player_friendly then {
            if test_against_invaders(bullet) then return true;
        } else {
            if test_against_ship(bullet.position, BULLET_RADIUS) {
                if !ship_is_shielded() then destroy_ship();
                return true;
            }
        }

        return false;
    }


    for bullets {
        done := simulate_bullet(it);
        if done then {
            it.emitter.producing = false;
            remove it;
            release_entity(it.entity);
            delete it;
        }
    }
}


do_fire_bullets :: () {

    fire_bullet :: () -> * Bullet {
        bullet := new Bullet;
        bullet.entity = get_new_entity();

        bullet.position = ship_position;

        bullet.velocity.x = 0;
        bullet.velocity.y = 0.4;

        bullet.emitter = make_emitter();
        bullet.emitter.theta0 = TAU * 0.6;
        bullet.emitter.theta1 = TAU * 0.9;
        bullet.emitter.drag0 = 0.9;
        bullet.emitter.drag1 = 0.97;

        bullet.map = ship_bullet_map;

        array_add(*live_emitters, bullet.emitter);

        k0 := 1.0;
        k1 := 0.1;

        bullet.emitter.color0 = make_vector4(k0, k0, k0, 1);
        bullet.emitter.color1 = make_vector4(k1, k1, k1, 1);

        array_add(*bullets, bullet);

        return bullet;
    }

    num_shots_fired := 0;
    shot_index += 1;

    if ship_shot_type == Shot_Type.STRAIGHT_SINGLE || ship_shot_type == Shot_Type.STRAIGHT_TRIPLE {
        front := fire_bullet();
        front.position.y += 0.015;
        
        num_shots_fired += 1;

        if ship_v_shot_countdown && ship_shot_type == Shot_Type.STRAIGHT_SINGLE {
            LATERAL := 0.025;
            if shot_index % 2 then front.velocity.x = LATERAL;
            else front.velocity.x = -LATERAL;
        }
    }

    if ship_shot_type == Shot_Type.STRAIGHT_DOUBLE || ship_shot_type == Shot_Type.STRAIGHT_TRIPLE {
        left := fire_bullet();
        right := fire_bullet();

        offset := 0.023;

        left.position.x -= offset;
        right.position.x += offset;

        if ship_v_shot_countdown {
            LATERAL := 0.04;
            left.velocity.x = -LATERAL;
            right.velocity.x = LATERAL;
        }

        num_shots_fired += 2;
    }

    ship_shot_cooldown += (cast(float) num_shots_fired) * ship_shot_cooldown_per_bullet;  // @Precedence

    sound_name := sprint("fire_bullet%", num_shots_fired);
    defer free(sound_name.data);
    play_sound(*entity_manager, sound_name);
}

maybe_fire_bullets :: () {
    if ship_shot_cooldown > 0 return;
    do_fire_bullets();
}

invader_fire_bullet :: (invader : * Invader) {

    fire_bullet :: () -> * Bullet {
        bullet := new Bullet;
        bullet.entity = get_new_entity();

        bullet.velocity.x = 0;

        if random_get() % 2 then bullet.velocity.y = -0.4;
        else bullet.velocity.y = -0.2; 

        bullet.emitter = make_emitter();
        bullet.emitter.theta0 = TAU * 0.6;
        bullet.emitter.theta1 = TAU * 0.9;
        bullet.emitter.drag0 = 0.9;
        bullet.emitter.drag1 = 0.97;

        bullet.emitter.size0 *= 0.5;
        bullet.emitter.size1 *= 0.5;

        bullet.emitter.speed1 = 0.05;

        bullet.emitter.lifetime0 = 0.2;
        bullet.emitter.lifetime1 = 0.5;

        array_add(*live_emitters, bullet.emitter);

        k0 := 0.7;
        k1 := 0.1;

        bullet.emitter.color0 = make_vector4(k0, k0, k0, 1);
        bullet.emitter.color1 = make_vector4(0.2, 1.0, 0.1, 1);
        bullet.map = invader_bullet_map;

        array_add(*bullets, bullet);

        return bullet;
    }


    bullet := fire_bullet();
    bullet.player_friendly = false;
    bullet.position = invader.position;
    play_sound(*entity_manager, "invader_fire_bullet");
}

sounds_simulate :: (manager: *Entity_Manager) {
    dt := Core.time_info.current_real_world_dt;

    for manager.issued_sounds {
        if it.flags & ISSUED_SOUND_REPEATING continue;
        
        it.my_lifetime -= dt;
        if it.my_lifetime < 0 {
            remove it;

            release_entity(it.entity);
            delete it;
        }
    }
}

invaders_simulate :: () {
    now := get_time();

    delta : float64 = now - last_time;
    current_dt = cast(float) delta;
    if current_dt > DT_MAX then current_dt = DT_MAX;
    Core.time_info.current_dt = current_dt;
    Core.time_info.current_real_world_dt = cast(float) delta;
    Core.time_info.current_time = cast(float) now;

    last_time = now;

    countdown :: (value: float) -> float {        
        value -= current_dt;
        if value < 0 then value = 0;

        return value;
    };

    old_invincibility := ship_invincibility_countdown;

    ship_shot_cooldown = countdown(ship_shot_cooldown);
    ship_invincibility_countdown = countdown(ship_invincibility_countdown);
    ship_v_shot_countdown = countdown(ship_v_shot_countdown);

    if ship_invincibility_countdown <= 0 && old_invincibility > 0 {
        play_sound(*entity_manager, "shield_end");
        ensure_shield_loop_not_playing(*entity_manager);
    }

    if end_game_countdown >= 0 {
        end_game_countdown -= current_dt;
        if end_game_countdown < 0 then should_quit_game = true;
    }

    // Read input:
    while 1 {
          if live_invaders.count == 0 {
              level_index += 1;
              init_new_level(level_index);
          }

          event: Event;
          received := get_next_event(*event);
          if !received then break;

          if event.type == Event_Type.QUIT then {
              should_quit_game = true;
              return;
          }

          if !ship_destroyed then {
/*
          printf("*event.type = %x\n", *event.type);
          printf("*event.key_pressed = %x\n", *event.key_pressed);
          printf("*event.key_code = %x\n", *event.key_code);
          printf("Type: %d\n", event.type);
          if event.type == Event_Type.UNINITIALIZED then { event.type = Event_Type.KEYBOARD; event.key_pressed = 0; }
          printf("Retype: %d\n", event.type);
*/

              if event.type == Event_Type.KEYBOARD then {
                  // printf("Key: %d pressed: %d\n", event.key_code, event.key_pressed);
                  key := event.key_code;

                  if key == Key_Code.ARROW_LEFT then
                      key_left = event.key_pressed;
                  if key == Key_Code.ARROW_RIGHT then
                      key_right = event.key_pressed;
                  if key == Key_Code.ARROW_DOWN then
                      key_down = event.key_pressed;
                  if key == Key_Code.ARROW_UP then
                      key_up = event.key_pressed;
    
                  if key == Key_Code.SHIFT then
                      if event.key_pressed then maybe_fire_bullets();

              }
          }

          if event.key_code == Key_Code.ESCAPE then
              if event.key_pressed then should_quit_game = true;
    }

    dx := 0.3 * current_dt;
    x0 := 0.01;
    x1 := 0.99; // 1.0 - x0;
    y0 := 0.02;
    y1 := 0.15;

    if key_left then
    ship_position.x -= dx;

    if key_right then 
    ship_position.x += dx;

    if key_down then
    ship_position.y -= dx;

    if key_up then 
    ship_position.y += dx;

    if ship_position.x < x0 then ship_position.x = x0;
    if ship_position.x > x1 then ship_position.x = x1;

    if ship_position.y < y0 then ship_position.y = y0;
    if ship_position.y > y1 then ship_position.y = y1;


    simulate_bullets();
    simulate_invaders();
    simulate_pickups();

    for live_emitters update_emitter(it);
}


init_textures :: () {

    make_texture :: (filename: string) -> *Texture_Map {  // We leave the Bitmap attached in this case.
        width:  s32 = 0;
        height: s32 = 0;
    
        // printf("About to load: %s\n", filename);

        data := stbi_png_load(to_c_string(filename), *width, *height, null, 0);
        // @Temporary @Hack!!! FFI doesn't quite work right with
        // pointers to locals.

        width = 512;
        height = 512;
        // printf("Data is %x; width %d, height %d\n", data, width, height);
        if !data {
            print("FAILED to load bitmap '%1'\n", filename);
            return null;
        }

//        swap_r_with_b(data, width, height);

        result := new Bitmap;
        result.width = width;
        result.height = height;
        result.data = data;
        result.length_in_bytes = width*height*4;  // @Temporary @Hack
        // printf("Bitmap %s is %dx%d\n", filename, width, height);

        texture := create_texture(result);
        return texture;
    }

    ship_map = make_texture("ship.png");
    ship_bullet_map = make_texture("bullet.png");
    invader_bullet_map = make_texture("invader_bullet.png");
    contrail_map = make_texture("contrail.png");
    pickup_map_v_shot = make_texture("pickup_v_shot.png");
    pickup_map_shield = make_texture("pickup_shield.png");
    pickup_map_extra_bullet = make_texture("pickup_extra_bullet.png");

    bug1 := make_texture("bug1.png");
    bug2 := make_texture("bug2.png");
    bug3 := make_texture("bug3.png");
    bug4 := make_texture("bug4.png");

    array_add(*invader_maps, bug1);
    array_add(*invader_maps, bug2);
    array_add(*invader_maps, bug3);
    array_add(*invader_maps, bug4);
}

draw_gradient :: () {
    glDisable(_GL_TEXTURE_2D);

    p0 := make_vector2(0, 0);
    p1 := make_vector2(1, 0);
    p2 := make_vector2(1, 1);
    p3 := make_vector2(0, 1);

    r0 : float = 0.0;
    g0 : float = 89.0 / 255.0;
    b0 : float = 131.0 / 255.0;

    r1 := 40.0 / 255.0;
    g1 := 49.0 / 255.0;
    b1 := 95.0 / 255.0;
 
    k0 := 0.7;
    k1 := 0.3;
 
    r0 *= k0;
    g0 *= k0;
    b0 *= k0;

    r1 *= k1;
    g1 *= k1;
    b1 *= k1;

    z := 0.0;

    glBegin(_GL_TRIANGLES);
    glColor3f(r0, g0, b0);
    glVertex3f(p0.x, p0.y, z);
    glColor3f(r0, g0, b0);
    glVertex3f(p1.x, p1.y, z);
    glColor3f(r1, g1, b1);
    glVertex3f(p2.x, p2.y, z);

    glColor3f(r0, g0, b0);
    glVertex3f(p0.x, p0.y, z);
    glColor3f(r1, g1, b1);
    glVertex3f(p2.x, p2.y, z);
    glColor3f(r1, g1, b1);
    glVertex3f(p3.x, p3.y, z);

    glEnd();

    glEnable(_GL_TEXTURE_2D);
}

invaders :: () -> int {
    the_sound_catalog = new Sound_Catalog;

    the_font = load_font(".", "KarminaBold.otf", BIG_FONT_SIZE);
    font := the_font;

    italics_font = load_font(".", "KarminaBoldItalic.otf", BIG_FONT_SIZE);
    italics_font_small = load_font(".", "KarminaBoldItalic.otf", BIG_FONT_SIZE/3);
    chinese_font = load_font(".", "tchinese.ttf", CHINESE_FONT_SIZE);

    last_time = get_time();

    width := WINDOW_WIDTH;
    height := WINDOW_HEIGHT;

    back_buffer_width = width;
    back_buffer_height = height;

    font_update_back_buffer_width(width, height);

    window_handle: *void;
    create_window(xx width, xx height, to_c_string("Invaders!"), *window_handle);
    init_textures();


    glEnable(_GL_BLEND);
    glBlendFunc(_GL_SRC_ALPHA, _GL_ONE_MINUS_SRC_ALPHA);

    aspect := (cast(float64) height) / cast(float64) width;  // @Precedence
    glOrtho(0, 1, 0, aspect, -1, 1);

    ship_position.x = 0.5;
    ship_position.y = 0.1;

    level_index = 0;
    init_new_level(level_index);

    sound_player = new Sound_Player;
    init(sound_player, cast(HWND) window_handle, true);


    sound := play_sound(*entity_manager, "commando", false, "ogg");
    if sound sound.flags |= ISSUED_SOUND_REPEATING;
    if sound sound.volume_scale = 0.4;


//    too_many := play_sound(*entity_manager, "too_many_bullets");
/*
    {
        print("============================\n");
        print("============================\n");
        print("============================\n");
        decoder := create_adpcm_decoder(too_many.sound_data);
        n0 := 12000;
        n1 := 18000;
        mark_relevant_pages(*decoder.base, n0, n1);
        found, start, end, data := find_page_containing_cursor(*decoder.base, n0 + 5000);
        print("found % start % end % data %\n", found, start, end, data);

        shorts := cast(*s16) data;
        for 0..20 print("% ", shorts[it]);
        print("\n");
        print("============================\n");
        print("============================\n");
        print("============================\n");
        for 0..88 print("step_table[%] = %\n", it, step_table[it]);
        print("============================\n");
    }
*/

    while 1 {
        if should_quit_game then return num_invaders_destroyed;

        k := 0.05;
        window_clear(k, k, k, 1);
        
        draw_gradient();

        invaders_simulate();
        sounds_simulate(*entity_manager);

        {
            camera_position: Vector3;
            camera_orientation: Quaternion;
            update_from_main_thread(sound_player, camera_position, camera_orientation);
        }

        if !ship_destroyed then draw_ship_at(ship_position, ship_map, 0.04);

        for live_pickups draw_image_at(it.position, it.map, PICKUP_SIZE);

        for live_invaders draw_image_at(it.position, it.map, 0.028);

/*
        font_pos: Vector2;
        font_pos.x = 0.35;
        font_pos.y = 0.35;
        font_map := font_pages[0].map;
        if bit_and(font_map.flags, Texture_Map.DIRTY) {
            font_map.flags = cast(u32) bit_xor(font_map.flags, Texture_Map.DIRTY);
            update_texture(font_map);
        }

        draw_image_at(font_pos, font_map, 0.2);
*/


        yy := back_buffer_height - the_font.character_height * 2;
        text := sprint("Score: %", num_invaders_destroyed);
        defer free(text.data);

        width := get_string_width_in_pixels(the_font, text, FONT_EFFECT_SMALLCAPS);
        margin := cast(s64) (cast(float) back_buffer_width * 0.03);

        color := make_vector4(1, 1, 1, 1);
        draw_text(the_font, back_buffer_width - width - margin, yy, color, text, FONT_EFFECT_SMALLCAPS);
        
        if fader_alpha > 0 {
            alpha := fader_alpha * 256.0;
            Clamp(*alpha, 0, 255);
            ialpha := (cast(u32) alpha) << 24;

            color := make_vector4(0.4, 1, 1, fader_alpha);

            effect : u32 = 0;
            width := get_string_width_in_pixels(the_font, fader_text, effect);
            yy := (back_buffer_height * 3) / 5;
            draw_text(the_font, (back_buffer_width - width)/2, yy, color, fader_text, effect);
            
            
            if fader_alpha > 0 {
                dt := Core.time_info.current_real_world_dt;

                fader_alpha -= dt * 0.2;
                if fader_alpha < 0  fader_alpha = 0;
            }
        }

/*
        title := "Testing!";
        width := get_string_width_in_pixels(the_font, title, FONT_EFFECT_SMALLCAPS);
        draw_text(the_font, (back_buffer_width - width)/2, yy, 0xffffffff, title, FONT_EFFECT_SMALLCAPS);

        yy -= 100;
        width = get_string_width_in_pixels(italics_font, "Testing!", 0);
        draw_text(italics_font, (back_buffer_width - width)/2, yy, 0xffffffff, title, 0);

        yy -= 80;
        s := "Rigningin á Spáni fellur aðallega í dalnum.";
        width = get_string_width_in_pixels(italics_font_small, s, 0);
        draw_text(italics_font_small, (back_buffer_width - width)/2, yy, 0xffffffff, s, 0);

        yy -= 160;
        s = "來吧無畏！取得迅速進展！";
        width = get_string_width_in_pixels(chinese_font, s, 0);
        draw_text(chinese_font, (back_buffer_width - width)/2, yy, 0xffffffff, s, 0);
*/
        
        for live_emitters draw_emitter(it);
        for bullets draw_bullet(it);

        swap_buffers();

        sleep_milliseconds(5);

        update_window_events();
    }
};



test :: (x: float, y: float, z: ..) -> float { 
     y = 4.0;

     return x * x; 
};


lerp :: (a: Vector4, b: Vector4, t: float) -> Vector4 {
    r: Vector4;

    r.x = a.x + t * (b.x - a.x);
    r.y = a.y + t * (b.y - a.y);
    r.z = a.z + t * (b.z - a.z);
    r.w = a.w + t * (b.w - a.w);

    return r;
}


draw_quad :: (p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) {
    z := 0.0;

/*
    printf("Quad: %.2f %.2f, %.2f %.2f, %.2f %.2f, %.2f %.2\n",
    p0.x, p0.y,
    p1.x, p1.y,
    p2.x, p2.y,
    p3.x, p3.y);
*/
        
    // @TODO: Texture coordinates here are flipped because
    // the textures are loaded right-handed. Sigh.

    
    glTexCoord2f(0, 1);
    glVertex3f(p0.x, p0.y, z);
    glTexCoord2f(1, 1);
    glVertex3f(p1.x, p1.y, z);
    glTexCoord2f(1, 0);
    glVertex3f(p2.x, p2.y, z);

    glTexCoord2f(0, 1);
    glVertex3f(p0.x, p0.y, z);
    glTexCoord2f(1, 0);
    glVertex3f(p2.x, p2.y, z);
    glTexCoord2f(0, 0);
    glVertex3f(p3.x, p3.y, z);
}



moved_vector2 :: (x: float, y: float,
                  ox: float, oy: float,
                  scale: float, position: Vector2) -> Vector2 {
//    printf("moved: x %.2f, y %.2f\n", x, y);

    x += ox;
    y += oy;

    x *= scale;
    y *= scale;
        
    x += position.x;
    y += position.y;

    result: Vector2;
    result.x = x;
    result.y = y;

//    printf("result: x %.2f, y %.2f\n", result.x, result.y);
    return result;
};

draw_quad_centered_at :: (position : Vector2, radius : float) {
    p0 := position;
    p1 := position;
    p2 := position;
    p3 := position;
    b := radius;

    p0.x -= b;
    p0.y -= b;

    p1.x += b;
    p1.y -= b;

    p2.x += b;
    p2.y += b;

    p3.x -= b;
    p3.y += b;

    draw_quad(p0, p1, p2, p3);
}

draw_emitter :: (emitter : * Particle_Emitter) { 
    glBindTexture(_GL_TEXTURE_2D, contrail_map.id);

    glBegin(_GL_TRIANGLES);
             
    for emitter.particles {            
        position := it.position;

        alpha : float = 1;

        // Fade particle if it's time to do so.
        tail_time := it.lifetime - it.elapsed;
        if tail_time < emitter.fadeout_period {
            t := tail_time / emitter.fadeout_period;
            if t < 0 then t = 0;
            if t > 1 then t = 1;
            
            alpha = t;
        }


        c := it.color;
        glColor4f(c.x, c.y, c.z, c.w * alpha);
        draw_quad_centered_at(position, it.size);
    }

    glEnd();
}

draw_bullet :: (bullet: * Bullet) { 
    position := bullet.position;

    glBindTexture(_GL_TEXTURE_2D, bullet.map.id);

    glBegin(_GL_TRIANGLES);

    glColor4f(1, 1, 1, 1);

    p0 := position;
    p1 := position;
    p2 := position;
    p3 := position;
    b := 0.008;

    p0.x -= b;
    p0.y -= b;

    p1.x += b;
    p1.y -= b;

    p2.x += b;
    p2.y += b;

    p3.x -= b;
    p3.y += b;

    draw_quad(p0, p1, p2, p3);

    glEnd();
}

draw_ship_at :: (position : Vector2, map: *Texture_Map, size: float) {
    p0 := position;
    p1 := position;
    p2 := position;
    p3 := position;
    b := size;

    p0.x -= b;
    p0.y -= b;

    p1.x += b;
    p1.y -= b;

    p2.x += b;
    p2.y += b;

    p3.x -= b;
    p3.y += b;

    glBindTexture(_GL_TEXTURE_2D, map.id);
    glEnable(_GL_TEXTURE_2D);
    glBegin(_GL_TRIANGLES);

    if ship_is_shielded() then {
        rate : float64 = 1.5;
        if ship_invincibility_countdown < 1.7 then rate = 4.5;

        theta := last_time * TAU64 * rate;
        y := cos(cast(float) theta);
//        printf("y is %f\n", y);

        k := (y + 1.0) * 0.5;
        if k < 0 then k = 0;

//        b : float = 1;
        if k > 1 then k = 1;

        k *= 0.8;

        glColor4f(1, k, k, 1);
    } else {
        glColor4f(1, 1, 1, 1);
    }

    draw_quad(p0, p1, p2, p3);
    glEnd();
}

draw_image_at :: (position : Vector2, map: *Texture_Map, size: float) {
    p0 := position;
    p1 := position;
    p2 := position;
    p3 := position;
    b := size;

    p0.x -= b;
    p0.y -= b;

    p1.x += b;
    p1.y -= b;

    p2.x += b;
    p2.y += b;

    p3.x -= b;
    p3.y += b;

//    printf("bitmap is %x\n", bitmap);
    glBindTexture(_GL_TEXTURE_2D, map.id);

    glBegin(_GL_TRIANGLES);

    glColor4f(1, 1, 1, 1);

    draw_quad(p0, p1, p2, p3);
    glEnd();
}

