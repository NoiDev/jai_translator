#import "Mixer"
#import "Entity_Manager"
#import "Wav_File"
#import "Cached_Decoder"
#import "stb_vorbis"
#import "Random"
#import "Sort"

the_entity_manager : *Entity_Manager;
sound_player : *Sound_Player;
got_done_message := false;

current_filename: string;
current_filepath: string;
current_line_number: s64;

bananas_executable_name: string;
bananas_executable_size: s64;

BY_SIZE         :: 0;
BY_FILE_BY_SIZE :: 1;
BY_NAME         :: 2;

NUM_SORT_METHODS :: BY_NAME;

sort_method := BY_NAME;
Entity_Issued_Sound :: struct {  // @Mixer
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

to_vec3 :: (v: Vector2) -> Vector3 {  // @Mixer
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



//COMPILE_WINDOW_WIDTH  :: 640;
//COMPILE_WINDOW_HEIGHT :: 400;
COMPILE_WINDOW_WIDTH  :: 1920;
COMPILE_WINDOW_HEIGHT :: 1080;
COMPILE_FONT_SIZE :: 80;
COMPILE_SMALL_FONT_SIZE :: 54;
COMPILE_SMALLER_FONT_SIZE :: 30;

compile_font: *Dynamic_Font;
compile_small_font: *Dynamic_Font;
compile_smaller_font: *Dynamic_Font;
compile_window_handle: *void;

compile_back_buffer_width : s64;
compile_back_buffer_height : s64;

STAT_FONT_SIZE :: 55;
stat_font: *Dynamic_Font;

bananas_proc_should_exit := false;
bananas_thread: *Thread;

bananas_messages : [..] *Compiler_Message;
bananas_message_mutex : Mutex;

bananas_start :: () {
    if !GO_BANANAS return;

    timeBeginPeriod(1);

    init(*bananas_message_mutex);
    bananas_thread = thread_create(bananas_proc);
    if bananas_thread {
        SetThreadPriority(bananas_thread.windows_thread, THREAD_PRIORITY_HIGHEST);
        thread_start(bananas_thread);
    }
}

bananas_wait_for_exit :: () {
    if !GO_BANANAS return;

    wait_for_gui_exit();
}

bananas_update :: () {
}

stop_bananas_thread :: () {
    if !bananas_thread return;
    bananas_proc_should_exit = true;

    while !thread_is_done(bananas_thread) { sleep_milliseconds(1); }
    thread_destroy(bananas_thread);
}

bananas_proc :: (thread: *Thread) -> s64 {
    start_window();

    while true {
        if bananas_proc_should_exit break;

        for 1..2 {  // N at a time...
            more := bananas_receive_procedure_stats();
            if !more break;
        }
        
        update_my_gui();

        camera_position: Vector3;
        camera_orientation: Quaternion;
        update_from_main_thread(sound_player, camera_position, camera_orientation);

        sleep_milliseconds(4);
    }

    return 0;
}

start_window :: () {
    timeBeginPeriod(1);
    
    width := COMPILE_WINDOW_WIDTH;
    height := COMPILE_WINDOW_HEIGHT;
    
    create_window(xx width, xx height, to_c_string("Compiler!"), *compile_window_handle);
    fg_hwnd := GetForegroundWindow();
    print("compile_window_handle %, hwnd %\n", formatInt(cast(u64)compile_window_handle, base = 16), formatInt(cast(u64)fg_hwnd, base = 16));
    if !compile_window_handle compile_window_handle = xx fg_hwnd;
    
    compile_back_buffer_width = width;
    compile_back_buffer_height = height;
    
    compile_font =         get_font_at_size(#filepath, "KarminaBold.otf", COMPILE_FONT_SIZE);
    compile_small_font =   get_font_at_size(#filepath, "KarminaBold.otf", COMPILE_SMALL_FONT_SIZE);
    compile_smaller_font = get_font_at_size(#filepath, "KarminaBold.otf", COMPILE_SMALLER_FONT_SIZE);
    stat_font =            get_font_at_size(#filepath, "KarminaBold.otf", STAT_FONT_SIZE);

    start_music();
}

start_music :: () {
    name := "traveller/lux_aeterna";
    ogg_name := sprint("%.ogg", name);
    defer free(ogg_name.data);

    result, success := read_entire_file(ogg_name);
    assert(success);

    if !result return;

    data := new Sound_Data;
    data.name = copy_string(name);
    data.type = Sound_Data.Type.OGG_COMPRESSED;
    data.buffer = result;

    the_entity_manager = new Entity_Manager;
    sound := play_sound(the_entity_manager, data, false);
    if sound sound.flags |= ISSUED_SOUND_REPEATING;
    if sound sound.my_time = 22;

    if sound sound.duration_total = 234.475;  // @Temporary @Hack! We do not get the duration by default from an ogg file...
    if sound sound.sound_category = SOUND_CATEGORY_UI;
//    print("time % duration %\n", sound.my_time, sound.duration_total);
    
    sound_player = new Sound_Player;
    array_add(*entity_managers, the_entity_manager);

    print("sound_player init hwnd %\n", compile_window_handle);
    init(sound_player, cast(HWND) compile_window_handle, true, true);
}

play_sound :: (manager: *Entity_Manager, data: *Sound_Data, perturb: bool = true) -> *Entity_Issued_Sound {
    sound := new Entity_Issued_Sound;
    sound.entity = get_new_entity(manager);
    sound.sound_name = copy_string(data.name);
    sound.sound_data = data;
    sound.entity_manager = manager;

    array_add(*manager.issued_sounds, sound);

    if perturb {
        sound.volume_scale = random_get_within_range(0.7, 1.0);
        sound.rate_scale = random_get_within_range(0.7, 1.22);
    }
    
    safety : float : 1.1;

    nsamples := data.nsamples_times_nchannels / data.nchannels;
    
    sound.my_lifetime = ((nsamples / cast(float)data.sampling_rate) / sound.rate_scale) * safety;

    return sound;
}

stat_declarations: [..] *Code_Declaration;
stat_declarations_are_dirty := false;

// @Cutnpaste from our demo program...
bananas_send_procedure_stats :: (message : *Compiler_Message) {
    if !GO_BANANAS return;

    // Filter out Code_Typechecked messages of constants/etc, since there are a lot of these
    // and we do not care about them right now.

    if message.kind == message.Kind.CODE_TYPECHECKED {
        code := cast(*Compiler_Message_Code_Typechecked) message;
        decl := code.declaration;
        if decl.expressions.count < 2  return;
    }

    // Handle POST_WRITE_EXECUTABLE here since file operations
    // might block and we don't want to block the UI thread.
    if message.kind == message.Kind.COMPILATION_PHASE {
        phase_message := cast (*Compiler_Message_Compilation_Phase) message;
        phase := phase_message.phase;
        
        if phase == Compilation_Phase.POST_WRITE_EXECUTABLE {
            name := phase_message.executable_name;
            s, success := read_entire_file(name);
            bananas_executable_name = name;
            bananas_executable_size = s.count;
            return;
        }
    }
    
    // Pass it on.
    
    lock(*bananas_message_mutex);
    array_add(*bananas_messages, message);
    unlock(*bananas_message_mutex);
}

bananas_receive_procedure_stats :: () -> bool {
    message: *Compiler_Message;

    lock(*bananas_message_mutex);
    if bananas_messages.count {
        message = bananas_messages[0];
        array_ordered_remove_by_index(*bananas_messages, 0);  // @Speed!!!
    }
    unlock(*bananas_message_mutex);

    if !message return false;
    
    using Compiler_Message.Kind.members;

    if message.kind == COMPLETE {
        got_done_message = true;
        return true;
    }

    if message.kind == CODE_TYPECHECKED {
        code := cast(*Compiler_Message_Code_Typechecked) message;
        decl := code.declaration;

        polymorph_source_header : *Code_Declaration;

        if decl.root_expression {
            if decl.root_expression.kind == Code_Node.Kind.PROCEDURE {
                proc := cast(*Code_Procedure) decl.root_expression;
                if proc.procedure_flags & PROCEDURE_IS_FOREIGN return true;

                polymorph_source_header = proc.polymorph_source_header;
            }
        }
        
        if (decl.expressions.count > 1) { // && !polymorph_source_header {
            array_add(*stat_declarations, decl);
            stat_declarations_are_dirty = true;
        }
/*
        if polymorph_source_header {
            record := find_or_add_polymorph_record(polymorph_source_header);
            record.instances += 1;
            record.expressions += decl.expressions.count;
        }
*/
    }

    return true;
}

draw_stat_declarations :: (p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, fg: Vector4) {
    if stat_declarations_are_dirty {
        stat_declarations_are_dirty = false;

        compare_declarations_by_size :: (a: *Code_Declaration, b: *Code_Declaration) -> s64 {
            delta := b.expressions.count - a.expressions.count;
            if delta return delta;

            return compare_strings(a.name, b.name);
        }

        compare_declarations_by_file_by_size :: (a: *Code_Declaration, b: *Code_Declaration) -> s64 {
            string_diff := compare_strings(a.filename, b.filename);
            if string_diff return string_diff;

            delta := b.expressions.count - a.expressions.count;
            return delta;
        }

        compare_declarations_by_name :: (a: *Code_Declaration, b: *Code_Declaration) -> s64 {
            return compare_strings(a.name, b.name);
        }
/*
        if sort_method == BY_SIZE {
            bubble_sort(stat_declarations, compare_declarations_by_size);
        } else if sort_method == BY_FILE_BY_SIZE {
            bubble_sort(stat_declarations, compare_declarations_by_file_by_size);
        } else if sort_method == BY_NAME {
            bubble_sort(stat_declarations, compare_declarations_by_name);
        }
*/
        if sort_method == BY_SIZE {
            quick_sort(stat_declarations, compare_declarations_by_size);
        } else if sort_method == BY_FILE_BY_SIZE {
            quick_sort(stat_declarations, compare_declarations_by_file_by_size);
        } else if sort_method == BY_NAME {
            quick_sort(stat_declarations, compare_declarations_by_name);
        }

    }

    //fg := make_vector4(0.6, 1, 1, 1);
    // bg := make_vector4(0.1, 0.1, 0.1, 1);
    bg := darken(fg, 0.9);
    
    // cursor_color := make_vector4(1, 0.5, 1, 1);
    cursor_color := whiten(fg, 0.67);
    cursor_color_bg := make_vector4(0, 0, 0, 0.7);
    
    glEnable(_GL_BLEND);
    glBegin(_GL_TRIANGLES);

    glColor4f(bg.x, bg.y, bg.z, bg.w);
    draw_quad(p0, p1, p2, p3);
    glColor4f(fg.x, fg.y, fg.z, fg.w);

    n := stat_declarations.count;
    if !n {
        glEnd();
        return;
    }
    
    ilength := 1 / cast(float) n;

    highest : int = 1;
    for stat_declarations {
        highest = max(highest, it.expressions.count);
    }

    //
    // Figure out cursor position.
    //
    pos: POINT;

    GetCursorPos(*pos);
    ScreenToClient(cast(HWND) compile_window_handle, *pos);

    sx := pos.x / cast(float) compile_back_buffer_width;
    wx := 2 / cast(float) compile_back_buffer_width;

    current_stat_declaration: *Code_Declaration;
    

    x  := p0.x;
    dx := (p1.x - p0.x) * ilength;
    scale := (1 / cast(float) highest) * (p3.y - p0.y);
    
    for stat_declarations {
        x0 := x;
        x1 := x + dx;
        y0 := p0.y;
        
        y1 := y0 + it.expressions.count * scale;
        
        q0, q1, q2, q3: Vector2;
        q0.x = x0;
        q0.y = y0;
        q1.x = x1;
        q1.y = y0;
        q2.x = x1;
        q2.y = y1;
        q3.x = x0;
        q3.y = y1;

        if (sx >= x0) && (sx <= x1) {
            current_stat_declaration = it;
        }
        
        //print("scale % quad % %\n", scale, q0, q2);
        draw_quad(q0, q1, q2, q3);
        
        x = x1;
    }

    current_filename = "";
    if current_stat_declaration {
        it := current_stat_declaration;
        current_filename = it.filename;
        current_filepath = it.filepath;
        current_line_number = it.line_number;
        
        y0 := p0.y;
        y1 := p3.y;

        extra := (y1 - y0) * 0.04;
        
        q0, q1, q2, q3: Vector2;
        q0.x = sx-wx;
        q0.y = y0-extra;
        q1.x = sx+wx;
        q1.y = q0.y;
        q2.x = q1.x;
        q2.y = y1+extra;
        q3.x = q0.x;
        q3.y = q2.y;

        b := 2 / cast(float) compile_back_buffer_width;
        r0, r1, r2, r3 := q0, q1, q2, q3;
        r0.x -= b;
        r1.x += b;
        r2.x += b;
        r3.x -= b;
        
        glColor4f(cursor_color_bg.x, cursor_color_bg.y, cursor_color_bg.z, cursor_color_bg.w);
        draw_quad(r0, r1, r2, r3);
        glColor4f(cursor_color.x, cursor_color.y, cursor_color.z, cursor_color.w);
        draw_quad(q0, q1, q2, q3);
        glEnd();

        // Draw text!
        glEnable(_GL_BLEND);
        glBlendFunc(_GL_SRC_ALPHA, _GL_ONE_MINUS_SRC_ALPHA);
        glEnable(_GL_TEXTURE_2D);

        effect :u32= 0;
        text := current_stat_declaration.name;
        font := stat_font;

        yy := p0.y * compile_back_buffer_width - font.character_height;
        color := make_vector4(1, 1, 1, 1);
        color2 := make_vector4(.6, .6, .6, 1);
        draw_text(font, xx (p0.x * compile_back_buffer_width), xx yy, color, text, effect);


        size_string := sprint("size: %", current_stat_declaration.expressions.count);
        defer free(size_string.data);
        size_width := get_string_width_in_pixels(font, size_string, effect);
        draw_text(font, xx (p1.x * compile_back_buffer_width - size_width), xx yy, color2, size_string, effect);

        yy -= xx font.character_height * 1.2;
        text = sprint("%:%", current_stat_declaration.filename, current_stat_declaration.line_number);
        draw_text(font, xx (p0.x * compile_back_buffer_width), xx yy, color2, text, effect);
        free(text.data);
    } else {
        glEnd();
    }
    
//    draw_mixer_history_samples(p0, p1, p2, p3, 0);
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

    
//    glTexCoord2f(0, 1);
    glVertex3f(p0.x, p0.y, z);
//    glTexCoord2f(1, 1);
    glVertex3f(p1.x, p1.y, z);
//    glTexCoord2f(1, 0);
    glVertex3f(p2.x, p2.y, z);

//    glTexCoord2f(0, 1);
    glVertex3f(p0.x, p0.y, z);
//    glTexCoord2f(1, 0);
    glVertex3f(p2.x, p2.y, z);
//    glTexCoord2f(0, 0);
    glVertex3f(p3.x, p3.y, z);
}


darken :: (color: Vector4, amount: float) -> Vector4 {
    result: Vector4;

    result.x = lerp(color.x, 0, amount);
    result.y = lerp(color.y, 0, amount);
    result.z = lerp(color.z, 0, amount);
    result.w = color.w;

    return result;
}

whiten :: (color: Vector4, amount: float) -> Vector4 {
    result: Vector4;

    result.x = lerp(color.x, 1, amount);
    result.y = lerp(color.y, 1, amount);
    result.z = lerp(color.z, 1, amount);
    result.w = color.w;

    return result;
}

draw_mixer_history :: (p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) {
    glDisable(_GL_TEXTURE_2D);
    glDisable(_GL_BLEND);

    glBegin(_GL_TRIANGLES);
    //    print("Mixer: %; %; %; %\n", p0, p1, p2, p3);
    // font := compile_font;
    // color := make_vector4(1, 1, 1, 1);
    //    draw_text(font, xx p0.x, xx p0.y, color, "Mixer History", 0);

    fg := make_vector4(0.7, 1, 0.7, 1);
    bg := darken(fg, 0.89); // make_vector4(0.1, 0.1, 0.1, 1);

    highest := 0.0;
    highest = max(highest, get_highest_history_value());
    if highest == 0  highest = 0.001;
    
                      
    glColor4f(bg.x, bg.y, bg.z, bg.w);
    draw_quad(p0, p1, p2, p3);
    glColor4f(fg.x, fg.y, fg.z, fg.w);
    draw_mixer_history_samples(p0, p1, p2, p3, 0, highest);

    dy := p3.y - p0.y;

    dy *= 1.2;

    p0.y -= dy;
    p1.y -= dy;
    p2.y -= dy;
    p3.y -= dy;
    
    glColor4f(bg.x, bg.y, bg.z, bg.w);
    draw_quad(p0, p1, p2, p3);
    glColor4f(fg.x, fg.y, fg.z, fg.w);
    draw_mixer_history_samples(p0, p1, p2, p3, 1, highest);
    glEnd();

/*
    offset := make_vector2(-0.01, 0);
    p0 = add(p0, offset);
    p1 = add(p1, offset);
    p2 = add(p2, offset);
    p3 = add(p3, offset);

    glColor4f(0.1, 0.1, 0.1, 1);
    draw_mixer_history_samples(p0, p1, p2, p3);
*/

    get_highest_history_value :: () -> float {
        nchannels := sound_player.handler.num_channels;

        scale : float = 0;

        for h : sound_player.history {
            for 0..nchannels-1 {
                // Find the bounds.
                scale = max(scale, -h.low[it]);
                scale = max(scale,  h.high[it]);
            }
        }

        return scale;
    }

    draw_mixer_history_samples :: (p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, c: int, scale: float) {
        history := sound_player.history;

        ymid := (p0.y + p3.y) * 0.5;
        y_half := (p3.y - p0.y) * 0.5;
        
        ilength := 1 / cast(float) HISTORY_LENGTH;

        x  := p0.x;
        dx := (p1.x - p0.x) * ilength;

        // history_cursor itself is still being filled, so we expect
        // it to be usually wrong, so we start one later and go one
        // less (hence the -2). Note though that this buffer is being
        // modified asynchronously so it may change even as we are
        // doing this math.
        history_cursor := sound_player.history_cursor;
        for 0..HISTORY_LENGTH-2 {
            i := (it + history_cursor + 1) % HISTORY_LENGTH;
            
            x0 := x;
            x1 := x + dx;

            low  := history[i].low[c];
            high := history[i].high[c];

            y0 := ymid + (low / scale)  * y_half;
            y1 := ymid + (high / scale) * y_half;

            q0, q1, q2, q3: Vector2;
            q0.x = x0;
            q0.y = y0;
            q1.x = x1;
            q1.y = y0;
            q2.x = x1;
            q2.y = y1;
            q3.x = x0;
            q3.y = y1;

            draw_quad(q0, q1, q2, q3);
            
            x = x1;
        }
    }
}

draw_window :: () {
    k := 0.18;
    window_clear(k, k, k, 1);

    width := compile_back_buffer_width;
    height := compile_back_buffer_height;

    font_update_back_buffer_width(width, height);
    aspect := (cast(float64) height) / cast(float64) width;  // @Precedence

    glLoadIdentity();
    glOrtho(0, 1, 0, aspect, -1, 1);

    glEnable(_GL_TEXTURE_2D);

    glEnable(_GL_BLEND);
    glBlendFunc(_GL_SRC_ALPHA, _GL_ONE_MINUS_SRC_ALPHA);

    title := "";
    if got_done_message {
        title = sprint("Done. % procedures.", stat_declarations.count);
    } else {
        title = sprint("Compiling... % procedures.", stat_declarations.count);
    }

    defer free(title.data);

    font := compile_font;
    text_width := get_string_width_in_pixels(font, title, FONT_EFFECT_SMALLCAPS);

    yy := cast(s64) (compile_back_buffer_height - font.character_height * 5.8);
    color := make_vector4(1, 1, 1, 1);
    draw_text(font, (compile_back_buffer_width - text_width)/2, yy, color, title, FONT_EFFECT_SMALLCAPS);


    if got_done_message && bananas_executable_name {
        effect : u32 = 0;
        font := compile_small_font;
        yy -= font.character_height;
        text := sprint("Executable '%' is % bytes.", bananas_executable_name, bananas_executable_size);
        defer free(text.data);

        text_width := get_string_width_in_pixels(font, text, effect);
        k := 0.75;
        color := make_vector4(k, k, k, 1);
        draw_text(font, (compile_back_buffer_width - text_width)/2, yy, color, text, effect);
    }

    
    h_over_w := (compile_back_buffer_height / cast(float) compile_back_buffer_width);

    {
        xmargin := 0.07;
        ymargin := 0.075;
        
        strip_height := 0.08 * h_over_w;
        
        x0 := xmargin;
        x1 := 1  - xmargin;
        y1 := h_over_w - ymargin;
        y0 := y1 - strip_height;
        
        p0 := make_vector2(x0, y0);
        p1 := make_vector2(x1, y0);
        p2 := make_vector2(x1, y1);
        p3 := make_vector2(x0, y1);

        draw_mixer_history(p0, p1, p2, p3);
    }

    {
        xmargin := 0.07;
        ymargin := 0.05;
        
        strip_height := ymargin * 2 * h_over_w;
        
        x0 := xmargin;
        x1 := 1  - xmargin;
        y0 := 0.1;
        y1 := 0.25;
        
        p0 := make_vector2(x0, y0);
        p1 := make_vector2(x1, y0);
        p2 := make_vector2(x1, y1);
        p3 := make_vector2(x0, y1);

        label := "";
        label_color : Vector4;
        if sort_method == BY_NAME {
            label = "by Name";
            label_color = make_vector4(1, .7, .7, 1);
        } else if sort_method == BY_FILE_BY_SIZE {
            label = "by File by Size";
            label_color = make_vector4(1, .7, 1, 1);
        } else if sort_method == BY_SIZE {
            label = "by Size";
            label_color = make_vector4(.6, 1, 1, 1);
        }

        draw_stat_declarations(p0, p1, p2, p3, label_color);

        {
            glEnable(_GL_BLEND);
            glBlendFunc(_GL_SRC_ALPHA, _GL_ONE_MINUS_SRC_ALPHA);
            glEnable(_GL_TEXTURE_2D);

            effect : u32 = 0;
            font := compile_smaller_font;

            tx := (p3.x * compile_back_buffer_width);
            ty := (p3.y * compile_back_buffer_width + font.character_height * .25);

            draw_text(font, xx tx, xx ty, label_color, label, effect);
        }
    }

    
    swap_buffers();
    sleep_milliseconds(1);
    update_window_events();
}

update_my_gui :: () {
    draw_window();
        
    event: Event;
    received := get_next_event(*event);
    if !received return;

    if event.type == Event_Type.KEYBOARD then {
        if !event.key_pressed return;
        
        key := event.key_code;
        if key == Key_Code.ESCAPE {
            bananas_done = true;
            return;
        } else if key == Key_Code.MOUSE_BUTTON_LEFT {
            if current_filename {
                command := sprint("emacsclient +% %/% --server-file c:\\.emacs.d\\server\\server -n", current_line_number, current_filepath, current_filename);
                defer free(command.data);

                // @Leak:
                // ShellExecuteA(cast(HWND) compile_window_handle, to_c_string("open"), to_c_string(EDITOR), to_c_string(command), null, 10);
                info: STARTUPINFO;
                info.cb = size_of(info);
                info.dwFlags = STARTF_USESTDHANDLES;
                info.hStdInput  = GetStdHandle(STD_INPUT_HANDLE);
                info.hStdOutput = GetStdHandle(STD_OUTPUT_HANDLE);
                info.hStdError  = GetStdHandle(STD_ERROR_HANDLE);

                pinfo: PROCESS_INFORMATION;
                result := CreateProcessA(to_c_string(EDITOR), to_c_string(command), null, null, 0, CREATE_NO_WINDOW, null, null, *info, *pinfo);
                // print("Run: %\n", command);
                // error := GetLastError();
                // print("Result % error %\n", result, error);
                CloseHandle(pinfo.hProcess);
                CloseHandle(pinfo.hThread);
            }
        } else if key == Key_Code.MOUSE_BUTTON_RIGHT {
            sort_method += 1;
            if sort_method > NUM_SORT_METHODS  sort_method = 0;
            stat_declarations_are_dirty = true;
        }
    }
}

/*
last_gui_update : float64;
maybe_update_my_gui :: () {
    if !GO_BANANAS return;

    now := get_time();

    LIMIT :: 0.025;
    if now - last_gui_update < LIMIT return;
    last_gui_update = now;
    update_my_gui();
}
*/

bananas_done := false;

wait_for_gui_exit :: () {
    while !bananas_done {
        //        update_my_gui();
        sleep_milliseconds(4);
    }

    stop_bananas_thread();
}

EDITOR :: "C:\\Program Files (x86)\\emacs-24.5\\bin\\emacsclient.exe";
//DONE
