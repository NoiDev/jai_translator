entity_managers : [..] *Entity_Manager;  // @Mixer

Entity_Manager :: struct {
    batches: [..] *Entity_Batch;

    entities_to_clean_up: [..] *Entity;

    issued_sounds: [..] *Entity_Issued_Sound;

    my_manager_id:     Manager_Id;
    time_passage_rate: float = 1;

    next_portable_id:  Pid = 1;
}

ENTITIES_PER_BATCH :: 20;

Entity_Batch :: struct {
    data : [ENTITIES_PER_BATCH] Entity;
    occupied: [ENTITIES_PER_BATCH] bool;  // @Incomplete: Make this a bit field! Or use the Entity ID ... ??

    batch_index : int;
}



/*

Stuff that we need for interfacing with the Mixer for now (will be cleaned up!)

*/

Entity :: struct SOA {
    using position: Vector2;
    velocity: Vector2;

    // To interface with Mixer. @Cleanup:
    orientation: Quaternion;
    scale: float = 1;

    map: *Texture_Map;
    entity_manager: *Entity_Manager;

    batch_index : u16;
    slot_index  : u16;

    portable_id: Pid;  // @Mixer
    entity_flags: u32;
}


Core :: struct { // @Mixer
    time_info: Time_Info;

    developer :: true;
}

Time_Info :: struct { // @Mixer
    current_time : float;
    current_dt   : float;
    current_real_world_dt: float;
}

Manager_Id :: s16;  // @Mixer
Pid :: s32;  // @Mixer



// @Mixer
ISSUED_SOUND_SPATIALIZED :: 0x1;
ISSUED_SOUND_REPEATING   :: 0x2;
ISSUED_SOUND_STEREO_SOURCES :: 0x4;
ISSUED_SOUND_IS_MUSIC    :: 0x8;
ISSUED_SOUND_IS_FOOTSTEP :: 0x10;
ISSUED_SOUND_DO_NOT_KILL :: 0x20;
ISSUED_SOUND_AMBIENT     :: 0x40;

// @Mixer
SOUND_CATEGORY_PROPS     :: 0;
SOUND_CATEGORY_AMBIENCES :: 1;
SOUND_CATEGORY_FOOTSTEPS :: 2;
SOUND_CATEGORY_UI        :: 3;

// @Mixer
ENTITY_INVISIBLE :: 0x1;

// @Mixer
get_entity_manager_audio_volumes :: () -> usual_scale: float, menu_scale: float {
    return 1, 1;
}

use_empty_slot :: (manager : *Entity_Manager, batch : *Entity_Batch) -> *Entity {
    for * batch.occupied {
        if << it continue;

        << it = true;
        
        e := *batch.data[it_index];
        e.batch_index = cast(u16) batch.batch_index;
        e.slot_index = cast(u16) it_index;
        e.portable_id = manager.next_portable_id;
        manager.next_portable_id += 1;

        // printf("New entity: batch %d (%llx), slot %d (it_index: %d, p: %llx)\n", cast(e) e.batch_index, int), batch, cast(e.slot_index, int), it_index;

        return e;
    }

    return null;
}

get_new_entity :: (manager : * Entity_Manager) -> * Entity {
    for manager.batches {
        e := use_empty_slot(manager, it);
        if e != null return e;  // FIX ME: There is a bug in lax_coerce_to_bool.
    }

    new_batch := new Entity_Batch;

    array_add(*manager.batches, new_batch);
    new_batch.batch_index = cast(int) manager.batches.count-1;

    e := use_empty_slot(manager, new_batch);

    print("%1 batches. new_batch is %2\n", manager.batches.count, new_batch);

    return e;
}
