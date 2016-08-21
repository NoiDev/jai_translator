#foreign_library "dsound"

/*

Here are the ugly macros from C for when we want them:

DECLARE_INTERFACE_(IDirectSound, IUnknown)
{
    // IUnknown methods
    STDMETHOD(QueryInterface)       (THIS_ __in REFIID, __deref_out LPVOID*) PURE;
    STDMETHOD_(ULONG,AddRef)        (THIS) PURE;
    STDMETHOD_(ULONG,Release)       (THIS) PURE;

    // IDirectSound methods
    STDMETHOD(CreateSoundBuffer)    (THIS_ __in LPCDSBUFFERDESC pcDSBufferDesc, __deref_out LPDIRECTSOUNDBUFFER *ppDSBuffer, __null LPUNKNOWN pUnkOuter) PURE;
    STDMETHOD(GetCaps)              (THIS_ __out LPDSCAPS pDSCaps) PURE;
    STDMETHOD(DuplicateSoundBuffer) (THIS_ __in LPDIRECTSOUNDBUFFER pDSBufferOriginal, __deref_out LPDIRECTSOUNDBUFFER *ppDSBufferDuplicate) PURE;
    STDMETHOD(SetCooperativeLevel)  (THIS_ HWND hwnd, DWORD dwLevel) PURE;
    STDMETHOD(Compact)              (THIS) PURE;
    STDMETHOD(GetSpeakerConfig)     (THIS_ __out LPDWORD pdwSpeakerConfig) PURE;
    STDMETHOD(SetSpeakerConfig)     (THIS_ DWORD dwSpeakerConfig) PURE;
    STDMETHOD(Initialize)           (THIS_ __in_opt LPCGUID pcGuidDevice) PURE;
};


DECLARE_INTERFACE_(IDirectSoundBuffer8, IDirectSoundBuffer)
{
    // IUnknown methods
    STDMETHOD(QueryInterface)       (THIS_ _In_ REFIID, _Outptr_ LPVOID*) PURE;
    STDMETHOD_(ULONG,AddRef)        (THIS) PURE;
    STDMETHOD_(ULONG,Release)       (THIS) PURE;

    // IDirectSoundBuffer methods
    STDMETHOD(GetCaps)              (THIS_ _Out_ LPDSBCAPS pDSBufferCaps) PURE;
    STDMETHOD(GetCurrentPosition)   (THIS_ _Out_opt_ LPDWORD pdwCurrentPlayCursor, _Out_opt_ LPDWORD pdwCurrentWriteCursor) PURE;
    STDMETHOD(GetFormat)            (THIS_ _Out_writes_bytes_opt_(dwSizeAllocated) LPWAVEFORMATEX pwfxFormat, DWORD dwSizeAllocated, _Out_opt_ LPDWORD pdwSizeWritten) PURE;
    STDMETHOD(GetVolume)            (THIS_ _Out_ LPLONG plVolume) PURE;
    STDMETHOD(GetPan)               (THIS_ _Out_ LPLONG plPan) PURE;
    STDMETHOD(GetFrequency)         (THIS_ _Out_ LPDWORD pdwFrequency) PURE;
    STDMETHOD(GetStatus)            (THIS_ _Out_ LPDWORD pdwStatus) PURE;
    STDMETHOD(Initialize)           (THIS_ _In_ LPDIRECTSOUND pDirectSound, _In_ LPCDSBUFFERDESC pcDSBufferDesc) PURE;
    STDMETHOD(Lock)                 (THIS_ DWORD dwOffset, DWORD dwBytes,
                                           _Outptr_result_bytebuffer_(*pdwAudioBytes1) LPVOID *ppvAudioPtr1, _Out_ LPDWORD pdwAudioBytes1,
                                           _Outptr_opt_result_bytebuffer_(*pdwAudioBytes2) LPVOID *ppvAudioPtr2, _Out_opt_ LPDWORD pdwAudioBytes2, DWORD dwFlags) PURE;
    STDMETHOD(Play)                 (THIS_ DWORD dwReserved1, DWORD dwPriority, DWORD dwFlags) PURE;
    STDMETHOD(SetCurrentPosition)   (THIS_ DWORD dwNewPosition) PURE;
    STDMETHOD(SetFormat)            (THIS_ _In_ LPCWAVEFORMATEX pcfxFormat) PURE;
    STDMETHOD(SetVolume)            (THIS_ LONG lVolume) PURE;
    STDMETHOD(SetPan)               (THIS_ LONG lPan) PURE;
    STDMETHOD(SetFrequency)         (THIS_ DWORD dwFrequency) PURE;
    STDMETHOD(Stop)                 (THIS) PURE;
    STDMETHOD(Unlock)               (THIS_ _In_reads_bytes_(dwAudioBytes1) LPVOID pvAudioPtr1, DWORD dwAudioBytes1,
                                           _In_reads_bytes_opt_(dwAudioBytes2) LPVOID pvAudioPtr2, DWORD dwAudioBytes2) PURE;
    STDMETHOD(Restore)              (THIS) PURE;

    // IDirectSoundBuffer8 methods
    STDMETHOD(SetFX)                (THIS_ DWORD dwEffectsCount, _In_reads_opt_(dwEffectsCount) LPDSEFFECTDESC pDSFXDesc, _Out_writes_opt_(dwEffectsCount) LPDWORD pdwResultCodes) PURE;
    STDMETHOD(AcquireResources)     (THIS_ DWORD dwFlags, DWORD dwEffectsCount, _Out_writes_(dwEffectsCount) LPDWORD pdwResultCodes) PURE;
    STDMETHOD(GetObjectInPath)      (THIS_ _In_ REFGUID rguidObject, DWORD dwIndex, _In_ REFGUID rguidInterface, _Outptr_ LPVOID *ppObject) PURE;
};

*/



OUTPUT_SAMPLING_RATE :: 44100;

PRIMARY_BUFFER_SIZE_IN_BYTES :: 0;
FILL_BUFFER_SIZE_IN_SAMPLES  :: 24000;  // @Cleanup: When we can do constexpr math, this should be: OUTPUT_SAMPLING_RATE / 2 or something like that.

DS_OK :: 0;

DSBPLAY_LOOPING      :: 0x01;

DSBSTATUS_PLAYING           :: 0x001
DSBSTATUS_BUFFERLOST        :: 0x002
DSBSTATUS_LOOPING           :: 0x004
DSBSTATUS_LOCHARDWARE       :: 0x008
DSBSTATUS_LOCSOFTWARE       :: 0x010
DSBSTATUS_TERMINATED        :: 0x020

//
// DirectSound Stuff:
//

WAVE_FORMAT_EXTENSIBLE         :: 0xFFFE;

// OMGWTFBBQ
string_to_guid :: (s: string) -> GUID {
    assert(s.count == 36);

    nybble :: (x: u8) -> u8 {
        if (x >= #char "0") && (x <= #char "9") {
            return x - #char "0";
        }

        if (x >= #char "a") && (x <= #char "f") {
            return x - #char "a" + 10;
        }

        assert(false);
        return 0;
    }
        
    byte :: (s: string, n: s64) -> u8 {
        a := inline nybble(s[n]);
        b := inline nybble(s[n+1]);
        assert(a <= 15);
        assert(b <= 15);
        value := (a << 4) + b;
        return value;
    }
    
    g: GUID;
    b0 : u32 = byte(s, 0);
    b1 : u32 = byte(s, 2);
    b2 : u32 = byte(s, 4);
    b3 : u32 = byte(s, 6);
    assert(s[8] == #char "-");

    g.Data1 = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3;

    b4 : u16 = byte(s, 9);
    b5 : u16 = byte(s, 11);
    assert(s[13] == #char "-");

    g.Data2 = (b4 << 8) | b5;
    
    b6 : u16 = byte(s, 14);
    b7 : u16 = byte(s, 16);
    assert(s[18] == #char "-");

    g.Data3 = (b6 << 8) | b7;

    
    g.Data4[0] = byte(s, 19);
    g.Data4[1] = byte(s, 21);
    assert(s[23] == #char "-");

    g.Data4[2] = byte(s, 24);
    g.Data4[3] = byte(s, 26);
    g.Data4[4] = byte(s, 28);
    g.Data4[5] = byte(s, 30);
    g.Data4[6] = byte(s, 32);
    g.Data4[7] = byte(s, 34);

    return g;
}

// @Incomplete:: Eventually we can uncomment this, but
// right now the #run directive return value handling does not
// handle big return values and GUIDis big! Because the return value
// is put back into the AST, we would need an AST Literal for
// a binary blob, I think. Weird and I don't want to do it yet.
// -jblow, 19 September 2015
// KSDATAFORMAT_SUBTYPE_PCM :: #run { string_to_guid("00000001-0000-0010-8000-00aa00389b71"); };
make_KSDATAFORMAT_SUBTYPE_PCM :: () -> GUID { return string_to_guid("00000001-0000-0010-8000-00aa00389b71"); };

SPEAKER_FRONT_LEFT             :: 0x1;
SPEAKER_FRONT_RIGHT            :: 0x2;
SPEAKER_FRONT_CENTER           :: 0x4;
SPEAKER_LOW_FREQUENCY          :: 0x8;
SPEAKER_BACK_LEFT              :: 0x10;
SPEAKER_BACK_RIGHT             :: 0x20;
SPEAKER_FRONT_LEFT_OF_CENTER   :: 0x40;
SPEAKER_FRONT_RIGHT_OF_CENTER  :: 0x80;
SPEAKER_BACK_CENTER            :: 0x100;
SPEAKER_SIDE_LEFT              :: 0x200;
SPEAKER_SIDE_RIGHT             :: 0x400;
SPEAKER_TOP_CENTER             :: 0x800;
SPEAKER_TOP_FRONT_LEFT         :: 0x1000;
SPEAKER_TOP_FRONT_CENTER       :: 0x2000;
SPEAKER_TOP_FRONT_RIGHT        :: 0x4000;
SPEAKER_TOP_BACK_LEFT          :: 0x8000;
SPEAKER_TOP_BACK_CENTER        :: 0x10000;
SPEAKER_TOP_BACK_RIGHT         :: 0x20000;


//
// Because we don't yet support constant expressions at toplevel,
// some of these 
//

KSAUDIO_SPEAKER_MONO           :: SPEAKER_FRONT_CENTER;
KSAUDIO_SPEAKER_STEREO         :: #run { SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT; };
KSAUDIO_SPEAKER_QUAD           :: #run { SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT | 
                                         SPEAKER_BACK_LEFT  | SPEAKER_BACK_RIGHT; };
KSAUDIO_SPEAKER_SURROUND       :: #run { SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT | 
                                         SPEAKER_FRONT_CENTER | SPEAKER_BACK_CENTER; };
KSAUDIO_SPEAKER_5POINT1        :: #run { SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT | 
                                         SPEAKER_FRONT_CENTER | SPEAKER_LOW_FREQUENCY | 
                                         SPEAKER_BACK_LEFT  | SPEAKER_BACK_RIGHT; };
KSAUDIO_SPEAKER_7POINT1        :: #run { SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT | 
                                         SPEAKER_FRONT_CENTER | SPEAKER_LOW_FREQUENCY | 
                                         SPEAKER_BACK_LEFT | SPEAKER_BACK_RIGHT | 
                                         SPEAKER_FRONT_LEFT_OF_CENTER | SPEAKER_FRONT_RIGHT_OF_CENTER; };
KSAUDIO_SPEAKER_5POINT1_SURROUND :: #run { SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT | 
                                         SPEAKER_FRONT_CENTER | SPEAKER_LOW_FREQUENCY | 
                                         SPEAKER_SIDE_LEFT  | SPEAKER_SIDE_RIGHT; };
KSAUDIO_SPEAKER_7POINT1_SURROUND :: #run { SPEAKER_FRONT_LEFT | SPEAKER_FRONT_RIGHT | 
                                         SPEAKER_FRONT_CENTER | SPEAKER_LOW_FREQUENCY | 
                                         SPEAKER_BACK_LEFT | SPEAKER_BACK_RIGHT | 
                                           SPEAKER_SIDE_LEFT | SPEAKER_SIDE_RIGHT; };

// The following are obsolete 5.1 and 7.1 settings (they lack side speakers).  Note this means
// that the default 5.1 and 7.1 settings (KSAUDIO_SPEAKER_5POINT1 and KSAUDIO_SPEAKER_7POINT1 are
// similarly obsolete but are unchanged for compatibility reasons).
//KSAUDIO_SPEAKER_5POINT1_BACK :: KSAUDIO_SPEAKER_5POINT1;
//KSAUDIO_SPEAKER_7POINT1_WIDE :: KSAUDIO_SPEAKER_7POINT1;


DSSPEAKER_HEADPHONE        :: 1;
DSSPEAKER_MONO             :: 2;
DSSPEAKER_QUAD             :: 3;
DSSPEAKER_STEREO           :: 4;
DSSPEAKER_SURROUND         :: 5;
DSSPEAKER_5POINT1          :: 6;
DSSPEAKER_5POINT1_BACK     :: DSSPEAKER_5POINT1;
DSSPEAKER_5POINT1_SURROUND :: 9;
DSSPEAKER_7POINT1          :: 7;
DSSPEAKER_7POINT1_SURROUND :: 8;
DSSPEAKER_7POINT1_WIDE     :: DSSPEAKER_7POINT1;

DSBCAPS_PRIMARYBUFFER      :: 0x1;
DSBCAPS_CTRLVOLUME         :: 0x80;
DSBCAPS_GLOBALFOCUS        :: 0x08000;
DSBCAPS_GETCURRENTPOSITION2:: 0x10000;

DSBUFFERCAPS :: struct {
}

IDirectSound8 :: struct {
    using vtable: *IDirectSound8Vtable;
}

IDirectSoundBuffer8 :: struct {
    using vtable: *IDirectSoundBuffer8Vtable;
}

Com_Vtable_Base :: struct {
    QueryInterface: *void;
    AddRef: *void;
    Release: (*void) -> s32 #foreign;
}

IDirectSoundBuffer8Vtable :: struct {
    using base: Com_Vtable_Base;

    GetCaps: (buffer: *IDirectSoundBuffer8, caps: *DSBUFFERCAPS) #foreign;
    GetCurrentPosition: (buffer: *IDirectSoundBuffer8, pdwCurrentPlayCursor: *s32, pdwCurrentWriteCursor: *s32) -> s32 #foreign;
    GetFormat: *void;
    GetVolume: *void;
    GetPan: *void;
    GetFrequency: *void;
    GetStatus:     (buffer: *IDirectSoundBuffer8, pdwStatus: *s32) -> s32 #foreign;
    Initialize: *void;
    Lock: (buffer: *IDirectSoundBuffer8, dwOffset: s32, dwBytes: s32, pvAudioPtr1: **void, dwAudioBytes1: *s32, pvAudioPtr2: **void, dwAudioBytes2: *s32, dwFlags: s32) -> s32 #foreign;
    Play:     (buffer: *IDirectSoundBuffer8, dwReserved1: s32, dwPriority: s32, dwFlags: s32) -> s32 #foreign;
    SetCurrentPosition: *void;
    SetFormat:  (buffer: *IDirectSoundBuffer8, format: *Waveformatex) -> s32 #foreign;
    SetVolume: *void;
    SetPan: *void;
    SetFrequency: *void;
    Stop: (buffer: *IDirectSoundBuffer8) -> s32 #foreign;
    Unlock: (buffer: *IDirectSoundBuffer8, pvAudioPtr1: *void, dwAudioBytes1: s32, pvAudioPtr2: *void, dwAudioBytes2: s32) -> s32 #foreign;
    
    Restore: (buffer: *IDirectSoundBuffer8) -> s32 #foreign;

    // IDirectSoundBuffer8 methods
    SetFX: *void;
    AcquireResources: *void;
    GetObjectInPath: *void;
}

IDirectSound8Vtable :: struct {
    using base: Com_Vtable_Base;

    // IDirectSound methods
    CreateSoundBuffer: (dsound: *IDirectSound8, desc: *DSBUFFERDESC, buffer: **IDirectSoundBuffer8, outer: **void = null) -> s32 #foreign;
    
    GetCaps: *void;
    DuplicateSoundBuffer: *void;
    SetCooperativeLevel: (dsound: *IDirectSound8, hwnd: HWND, level: s32) -> s32 #foreign;
    Compact: *void;
    GetSpeakerConfig: (dsound: *IDirectSound8, config: *s32) -> s32 #foreign;
    SetSpeakerConfig: *void;
    Initialize: *void;
}

WAVEFORMATEXTENSIBLE :: struct {
    Format: Waveformatex;
    wValidBitsPerSample: s16;
    dwChannelMask: s32;
    SubFormat: GUID;
}

Sound_Handler :: struct {
    playing: bool;

    fill_buffer_size_in_bytes: s32;
    minimum_prebuffered_bytes: s64;

    num_channels:  s64;  // Currently will only be 2, 6, or 8.
    channel_names: [..] string;

    my_write_cursor: s64;

    dsound:         *IDirectSound8;
    primary_buffer: *IDirectSoundBuffer8;
    fill_buffer:    *IDirectSoundBuffer8;
}

Fill_Region_Result :: struct {
    buffer0: string;
    buffer1: string;
}

DSBUFFERDESC :: struct {
    dwSize        : s32;
    dwFlags       : s32;
    dwBufferBytes : s32;
    dwReserved    : s32;
    lpwfxFormat   : *Waveformatex;

    guid3DAlgorithm: GUID;
}

GUID :: struct {  // @Incomplete: Check that the packing of this is what we expect.
    Data1: u32;
    Data2: u16;
    Data3: u16;
    Data4: [8] u8;
}


SUCCEEDED :: (hr: s32) -> bool {
    return hr == 0;
}

FAILED :: (hr: s32) -> bool {
    return !SUCCEEDED(hr);
}

safe_release :: (b: **$T) {
    p := <<b;
    if p  p.Release(p);
    <<b = null;
}
    
init_wave_format :: (using w: *Waveformatex, nchannels: s16) {
    wFormatTag      = WAVE_FORMAT_PCM; 
    nChannels       = nchannels;
    nSamplesPerSec  = OUTPUT_SAMPLING_RATE; 
    wBitsPerSample  = 16;
    nBlockAlign     = (wBitsPerSample / 8) * nChannels;
    nAvgBytesPerSec = nSamplesPerSec * nBlockAlign;
}

DSSPEAKER_CONFIG :: (speaker_config: s32) -> u8 {
    return cast(u8) (speaker_config & 0xff);
}

DSSPEAKER_GEOMETRY :: (speaker_config: s32) -> u8 {
    return cast(u8) ((speaker_config >> 16) & 0xff);
}

init :: (using handler: *Sound_Handler, hwnd: HWND, global_focus: bool) -> bool {
    DirectSoundCreate8 :: (device: *void, ppds8: **IDirectSound8, outer: *void) -> s32 #foreign;

    hr := DirectSoundCreate8(null, *dsound, null);
    if !SUCCEEDED(hr) print("DSCreate8 Failed!\n");
    if !SUCCEEDED(hr) return false;

    DSSCL_NORMAL        :: 0x1;
    DSSCL_PRIORITY      :: 0x2;
    // DSSCL_EXCLUSIVE     :: 0x3;   Deprecated and useless.
    // DSSCL_WRITEPRIMARY  :: 0x4;   Deprecated and useless.

    hr = dsound.SetCooperativeLevel(dsound, hwnd, DSSCL_PRIORITY);
    
    if !SUCCEEDED(hr) print("SCL Failed! dsound % hwnd %\n", dsound, hwnd);
    if !SUCCEEDED(hr) return false;
    
    speaker_config: s32;
    hr = dsound.GetSpeakerConfig(dsound, *speaker_config);
    
    if SUCCEEDED(hr) {
        config := DSSPEAKER_CONFIG(speaker_config);
        geometry := DSSPEAKER_GEOMETRY(speaker_config);

        if (config == DSSPEAKER_5POINT1_BACK) || (config == DSSPEAKER_5POINT1_SURROUND) {
            array_add(*channel_names, "Front Left");
            array_add(*channel_names, "Front Right");
            array_add(*channel_names, "Center");
            array_add(*channel_names, "Subwoofer");
            array_add(*channel_names, "Rear Left");
            array_add(*channel_names, "Rear Right");
        } else if (config == DSSPEAKER_7POINT1_WIDE) || (config == DSSPEAKER_7POINT1_SURROUND) {
            array_add(*channel_names, "Front Left");
            array_add(*channel_names, "Front Right");
            array_add(*channel_names, "Center");
            array_add(*channel_names, "Subwoofer");
            array_add(*channel_names, "Rear Left");
            array_add(*channel_names, "Rear Right");
            array_add(*channel_names, "Extend Left");
            array_add(*channel_names, "Extend Right");
        } else {
            array_add(*channel_names, "Left");
            array_add(*channel_names, "Right");
        }
    } else {
        array_add(*channel_names, "Left?");
        array_add(*channel_names, "Right?");
    }

    num_channels = channel_names.count;


    //
    // Get the primary buffer 
    //
    dsbd: DSBUFFERDESC;
    dsbd.dwSize        = size_of(DSBUFFERDESC);
    dsbd.dwFlags       = DSBCAPS_PRIMARYBUFFER;
    dsbd.dwBufferBytes = PRIMARY_BUFFER_SIZE_IN_BYTES;
    
    hr = dsound.CreateSoundBuffer(dsound, *dsbd, *primary_buffer, null);
    if FAILED(hr) return false;

    channel_mask: s64;
    if num_channels == 2 {
        channel_mask = KSAUDIO_SPEAKER_STEREO;
    } else {
        channel_mask = KSAUDIO_SPEAKER_5POINT1_SURROUND;
    }

    pcm := make_KSDATAFORMAT_SUBTYPE_PCM();
    
    wfx: WAVEFORMATEXTENSIBLE;
    init_wave_format(*wfx.Format, cast(s16) num_channels);
    wfx.Format.wFormatTag = WAVE_FORMAT_EXTENSIBLE;
    wfx.Format.wBitsPerSample = 16;
    wfx.Format.nSamplesPerSec = OUTPUT_SAMPLING_RATE;
    wfx.Format.cbSize = 22;
    wfx.wValidBitsPerSample = 16;
    wfx.dwChannelMask = cast(s32) channel_mask;
    wfx.SubFormat = pcm;

    hr = primary_buffer.SetFormat(primary_buffer, *wfx.Format);
    if !SUCCEEDED(hr) print("SetFormat!\n");
    if FAILED(hr) return false;


/*
    wfx2: WAVEFORMATEXTENSIBLE;
    wfx2.Format.wFormatTag = WAVE_FORMAT_EXTENSIBLE;
    wfx2.Format.cbSize = 22;

    needed: s32 = 0;
    hr = primary_buffer.GetFormat(primary_buffer, null, 0, *needed);
    result_bytes := malloc(needed);
    defer free(result_bytes);
    hr = primary_buffer->GetFormat((LPWAVEFORMATEX)result_bytes, needed, NULL);
    assert(SUCCEEDED(hr));

    //
    // @Incomplete: What if our result format has a different number of channels from what we wanted?
    //
*/

    fill_bytes := FILL_BUFFER_SIZE_IN_SAMPLES * num_channels;
    
    //
    // Create the fill buffer.
    //
    fill_desc: DSBUFFERDESC;
    fill_desc.dwSize        = size_of(DSBUFFERDESC);

    fill_desc.dwFlags       = DSBCAPS_CTRLVOLUME | DSBCAPS_GETCURRENTPOSITION2;
    if global_focus  fill_desc.dwFlags |= DSBCAPS_GLOBALFOCUS;
    
    fill_desc.dwBufferBytes = cast(s32) fill_bytes;
    fill_desc.lpwfxFormat   = *wfx.Format;

    hr = dsound.vtable.CreateSoundBuffer(dsound, *fill_desc, *fill_buffer, null);
    assert(SUCCEEDED(hr));
    if !SUCCEEDED(hr) print("CSB Failed!\n");
    if FAILED(hr) return false;


    fill_buffer_size_in_bytes = cast(s32) fill_bytes;  // @Robustness: Check the actual length of the buffer, not what we asked it to be.
    return true;
}

play :: (using handler: *Sound_Handler) {
    if !fill_buffer return; // No audio driver!

    hr := fill_buffer.Play(fill_buffer, 0, 0, DSBPLAY_LOOPING);
    // print("play hr %\n", hr);
    
    assert(SUCCEEDED(hr));
    if SUCCEEDED(hr) playing = true;
}

get_fill_regions :: (using handler: *Sound_Handler, bytes_to_lock: s64) -> Fill_Region_Result, bool {
    result: Fill_Region_Result;
	if !fill_buffer return result, false;  // No driver, no regions!

    pointer1, pointer2: *void;
    bytes1, bytes2: s32;
    
    hr := fill_buffer.Lock(fill_buffer, cast(s32) my_write_cursor, cast(s32) bytes_to_lock, 
                           *pointer1, *bytes1, *pointer2, *bytes2, 
                           0);
    // print("lock %, %, %\n", fill_buffer, my_write_cursor, bytes_to_lock);
    
    if !SUCCEEDED(hr) return result, false;

    result.buffer0.data  = pointer1;
    result.buffer0.count = bytes1;

    result.buffer1.data  = pointer2;
    result.buffer1.count = bytes2;

    // print(">>> Fill regions %, %\n", bytes1, bytes2);
    return result, true;
}

release_fill_regions :: (using handler: *Sound_Handler, result: Fill_Region_Result) {
    if !fill_buffer return;  // No driver!
	
    s0 := result.buffer0;
    s1 := result.buffer1;

    fill_buffer.Unlock(fill_buffer, s0.data, cast(s32) s0.count, s1.data, cast(s32) s1.count);

    my_write_cursor += s0.count + s1.count;

    if my_write_cursor >= fill_buffer_size_in_bytes  my_write_cursor -= fill_buffer_size_in_bytes;

    assert(my_write_cursor >= 0);
    assert(my_write_cursor < fill_buffer_size_in_bytes);
    assert((my_write_cursor % 4) == 0);
    // print("<<< Fill regions release\n");
}


shutdown :: (using handler: *Sound_Handler) {
    if fill_buffer {
        fill_buffer.Stop(fill_buffer);
    }

    safe_release(*primary_buffer);
    safe_release(*fill_buffer);
    safe_release(*dsound);
}

restore_buffers :: (using handler: *Sound_Handler) -> bool {
    restore_buffer :: (buffer: *IDirectSoundBuffer8) -> bool {
        dwStatus: s32;
        hr := buffer.GetStatus(buffer, *dwStatus);
        if FAILED(hr) return false;

        if !(dwStatus & DSBSTATUS_BUFFERLOST) return true;

        hr = buffer.Restore(buffer);
        if FAILED(hr) return false;

        return true;
    }

    success1 := restore_buffer(primary_buffer);
    success2 := restore_buffer(fill_buffer);

    return success1 && success2;
}

get_bytes_between :: (front: $T, rear: T, buffer_len: T) -> T {
    if front >= rear return front - rear;
    return (buffer_len - rear) + front;
}

count_buffered_bytes :: (using handler: *Sound_Handler) -> s64 {
	if !fill_buffer return 0;

//    restore_buffers();

    d_play_cursor: s32;
    d_annoying_write_cursor: s32;

    hr := fill_buffer.GetCurrentPosition(fill_buffer, *d_play_cursor, *d_annoying_write_cursor);
    if !SUCCEEDED(hr) return 0;
    
    between := get_bytes_between(my_write_cursor, d_play_cursor, fill_buffer_size_in_bytes);
    necessary_prebuffered := get_bytes_between(d_annoying_write_cursor, d_play_cursor, fill_buffer_size_in_bytes);

//    if (minimum_prebuffered_bytes < necessary_prebuffered) minimum_prebuffered_bytes = necessary_prebuffered;
    minimum_prebuffered_bytes = necessary_prebuffered;

    return between;
}

needs_async_update_from_main_thread :: (handler: *Sound_Handler) -> bool {
    return true;
}
