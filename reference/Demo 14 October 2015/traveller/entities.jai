
Pickup_Type :: enum u32 {
    UNINITIALIZED,
    EXTRA_BULLET,
    SHIELD,
    V_SHOT,
}

Pickup :: struct SOA {
    using entity : *Entity;

    type := Pickup_Type.UNINITIALIZED;
}

Invader :: struct SOA {
    using entity : *Entity;

    target_position: Vector2;
    sleep_countdown := -1.0;

    update_proc : (self: * Invader);
}

Bullet :: struct SOA {
    using entity : *Entity;

    color: Vector4;
    emitter: *Particle_Emitter = null;
    player_friendly := true;

    //guy_who_fired_me: *Entity;
    //my_pair_bullets: [] **Bullet;
}

