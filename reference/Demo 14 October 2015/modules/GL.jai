#foreign_library "GL"


create_window :: (width: s64, height: s64, name: *u8, window_handle_return: **void) -> bool #foreign;
update_window_events :: () -> void #foreign;
// do_sleep :: (milliseconds: s32) -> void #foreign;
window_clear :: (red: float, green: float, blue: float, alpha: float) -> void #foreign;
swap_buffers :: () -> void #foreign;
GetForegroundWindow :: () -> HWND #foreign;

glColor4f       :: (r: float, g: float, b: float, a: float) -> void #foreign;
glColor3f       :: (r: float, g: float, b: float) -> void #foreign;
glBlendFunc     :: (sfactor : s32, dfactor : s32) #foreign;
glEnable        :: (cap : s32) #foreign;
glDisable       :: (cap : s32) #foreign;
glGenTextures   :: (count: s32, result: * u32) #foreign;
glTexParameteri :: (target: s32, pname: s32, param: s32) #foreign;
glTexParameterf :: (target: s32, pname: s32, param: float) #foreign;
glBindTexture   :: (target: s32, texture: u32) #foreign;
glTexImage2D    :: (target: s32, level: s32, international_format: s32, width: s32, height: s32, border: s32, format: s32, type: s32, pixels: * void) #foreign;

_GL_ZERO: s32 :                 0x0000;
_GL_ONE: s32 :                  0x0001;
_GL_TRIANGLES : s32 :           0x0004;
_GL_BLEND : s32 :               0x0BE2;
_GL_SRC_ALPHA : s32 :           0x0302;
_GL_ONE_MINUS_SRC_ALPHA : s32 : 0x0303;
_GL_TEXTURE_2D : s32 :          0x0DE1;
_GL_RGBA8 : s32 :               0x8058;  
_GL_UNSIGNED_BYTE : s32 :       0x1401;
_GL_BGRA_EXT : s32 :            0x80E1;
_GL_TEXTURE_MAX_LEVEL : s32 :   0x813D;
_GL_RGBA : s32 :                0x1908;

_GL_TEXTURE_MAX_ANISOTROPY_EXT : s32 : 0x84FE;


_GL_TEXTURE_MAG_FILTER : s32 :             0x2800;
_GL_TEXTURE_MIN_FILTER : s32 :             0x2801;
_GL_TEXTURE_WRAP_S     : s32 :             0x2802;
_GL_TEXTURE_WRAP_T     : s32 :             0x2803;



_GL_NEAREST   : s32 :                     0x2600;
_GL_LINEAR    : s32 :                     0x2601;


glBegin :: (mode: s32) #foreign;
glEnd :: () #foreign;
glVertex3f :: (x: float, y: float, z: float) #foreign;
glTexCoord2f :: (u: float, v: float) #foreign;

glLoadIdentity :: () -> void #foreign;

glOrtho :: (left: float64, right: float64,
            bottom: float64, top: float64, 
            near: float64, far: float64) -> void #foreign;

/*

  I would like the event stuff to be in Basic, but for now
  I don't want to figure out how to cross-refer between DLLs
  in Windows, so, this all goes here where it can live together.

      -jblow, 23 October 2014

*/

get_next_event :: (result: * Event) -> int #foreign;  // Should be a bool.

Event_Type :: enum u32 {  // If we set this to u8, our packing will stop matching C's.
    UNINITIALIZED : 0,
    KEYBOARD : 1,
    WINDOW : 2,
    QUIT : 3
}

Key_Code :: enum u32 {
    UNKNOWN : 0,
    ARROW_LEFT : 1,
    ARROW_RIGHT : 2,
    ARROW_UP : 3,
    ARROW_DOWN : 4,
    SHIFT : 5,
    ESCAPE : 6,
    MOUSE_BUTTON_LEFT : 7,
    MOUSE_BUTTON_RIGHT : 8,
}

Event :: struct {
    type : Event_Type.strict = Event_Type.UNINITIALIZED;

    // If keyboard event:
    key_pressed : u32 = 0;  // If not pressed, it's a key release.
    key_code : Key_Code.strict = Key_Code.UNKNOWN;
}

// swap_r_with_b has been put into C for now just so we can run it
// quickly in bytecode without having a slow startup.
swap_r_with_b :: (data : *u8, width: s32, height: s32) #foreign;


Texture_Format :: struct {
    ARGB8888 :: 0;
}

Texture_Map :: struct {
    width, height: s32;
    flags: u32;

    DIRTY :: 0x1;

    id: u32;  // GL texture handle.
    data: *Bitmap;  // Used if this is a texture we dirty.
}

Bitmap :: struct {
    width, height: s32;

    data: !* u8;

    format := Texture_Format.ARGB8888;
    num_mipmap_levels := 1;
    length_in_bytes : s64;
}

create_texture :: (data: *Bitmap) -> *Texture_Map {
    map := new Texture_Map;
    map.width = data.width;
    map.height = data.height;
    map.data = data;

    update_texture(map);

    return map;
}

update_texture :: (map: *Texture_Map) {
    if (!map.id) {
        glGenTextures(1, *map.id);
    }

    if !map.data return;

    glBindTexture(_GL_TEXTURE_2D, map.id);

    glTexImage2D(_GL_TEXTURE_2D, 0, _GL_RGBA8, 
                 map.data.width, map.data.height,
                 0, _GL_RGBA, _GL_UNSIGNED_BYTE, cast(* void) map.data.data);

    glTexParameteri(_GL_TEXTURE_2D, _GL_TEXTURE_MAX_LEVEL, 0);
}

