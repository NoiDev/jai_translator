#foreign_library "Basic"
//#import "Print"

SOA_Pointer :: struct {
    data: * u8;
    index: u32;
    count: u32;
};

array_unordered_remove :: inline (array: *[..] $T, item: T) -> s64 {
    removed: s64 = 0;

    size := size_of(T);
    
    for i : 0..array.count-1 {
        current := cast (*u8) array.data + i * size;
        if (memcmp(current, *item, size) == 0) {
            source := cast (*u8) array.data + (array.count - 1) * size;
            memcpy(current, source, size);

            array.count -= 1;
            removed += 1;
            i -= 1;
        }
    }
    
    return removed;
}

array_ordered_remove_by_index :: inline (array_pointer: *[..] $T, index: s64) {
    assert(index >= 0, #file, #line);
    assert(index < array_pointer.count, #file, #line);
    
    array := <<array_pointer;

    for i : index..array.count-2
        array[i] = array[i+1];


    array_pointer.count -= 1;
}

array_find :: (array: [] $T, item: T) -> s64 {
    for array if it == item return it_index; 
    return -1;  // Not found.
}

array_add :: (array: *[..] $T, item: T) { 
    if array.count >= array.allocated {
        reserve := 2 * array.allocated;
        if reserve < 8  reserve = 8;

        array_reserve(array, reserve);
    }

    array.data[array.count] = item;
    array.count += 1;
}


array_add_if_unique :: (array: *[..] $T, item: T) -> bool, s64 {   // Return true if added; also return index.
    index := array_find(<<array, item);
    if index != -1 return false, index;

    array_add(array, item);
    return true, array.count-1;
}
                

array_reserve :: (array: *[..] $T, reserve: s64) {
    if reserve <= array.allocated return;

    size := size_of(T);
    num_bytes := reserve * size;

    if !array.allocator {
        array.allocator      = context.allocator;
        array.allocator_data = context.allocator_data;
    }

    if !array.allocator  array.allocator = __default_allocator;

    allocator := array.allocator;

    new_memory := allocator(Allocator_Mode.RESIZE, num_bytes, array.count * size, array.data, array.allocator_data, 0);
    assert(new_memory != null, #file, #line);

    if !new_memory return;  // @Incomplete: array_add should know this failed.

    array.data = new_memory;
    array.allocated = reserve;
}

array_reset :: (array: *[..] $T) {
    // @Incomplete: If we allocated a lot of RAM, release it?
    array.count = 0;
}

find_empty_slot :: (array: [] * $T) -> s64 {
    for array 
        if it == null return it_index;

    return -1;
}


add_build_file :: (filename: string) #foreign;
add_build_string :: (data: string) #foreign;
set_build_file_path :: (filename: string) #foreign;
update_build_options :: () #foreign;

// For some reason in Windows sinf and cosf don't have linkage, probably because
// they always get turned into intrinsics? So I made my own..
cos  :: (theta: float) -> float #foreign "__cosf"; 
sin  :: (theta: float) -> float #foreign "__sinf";
sqrt :: (theta: float) -> float #foreign "__sqrtf";

cos  :: (theta: float64) -> float64 #foreign "cos"; 
sin  :: (theta: float64) -> float64 #foreign "sin";
sqrt :: (theta: float64) -> float64 #foreign "sqrt";

//fmod :: (x: float, divisor: float) -> float #foreign "fmod";
fmod :: (x: float64, divisor: float64) -> float64 #foreign;
pow  :: (x: float64, power: float64) -> float64 #foreign;
pow  :: (x: float, power: float) -> float #foreign "powf";
fabs :: (x: float64) -> float64 #foreign;
atan2 :: (y: float, x: float) -> float #foreign;
floor :: (x: float64) -> float64 #foreign;

TAU : float : 6.283147;
TAU64 : float64 : 6.28318530717958647;

//printf :: (s: *u8, args: ..) -> s32 #foreign;
sprintf :: (dest: *u8, s: *u8, args: ..) -> s32 #foreign;
strchr :: (s: *u8, c: u32) -> *u8 #foreign;
sscanf :: (s: *u8, format: *u8, args: ..) -> s32 #foreign;

memcmp :: (a: *void, b: *void, count: s64) -> s32 #foreign;

panic :: () -> void #foreign;

assert :: (arg: bool, file: string = "", line: s64 = -1) {  // This is a sorry-assed assert.
    if arg return;

    write_string :: (s: string) {
        standard_output := GetStdHandle(STD_OUTPUT_HANDLE);

        written: s32;
        status := WriteFile(standard_output, s.data, xx s.count, *written, null);
    }

    if file && (line >= 0) {
        s := sprint("!!!!!     Assertion failed at %:%      !!!!!", file, line);
        for 0..s.count-1 write_string("!");
        write_string("\n");
        print("%\n", s);
        for 0..s.count-1 write_string("!");
        write_string("\n");
    } else {
        write_string("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
        write_string("!!!!!    Assertion failed    !!!!!\n");
        write_string("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n");
    }
    
    panic();
}


alloc :: (size: s64) -> *void {
    return context.allocator(Allocator_Mode.ALLOCATE, size, 0, null, context.allocator_data, 0);
}

free :: (memory: *void) {
    context.allocator(Allocator_Mode.FREE, 0, 0, memory, context.allocator_data, 0);
}

log :: (message: string, ident: string, mode: Log_Mode.strict = Log_Mode.EVERYDAY) {
    context.logger(message, ident, mode, context.logger_data);
}

get_time :: () -> float64 #foreign;


get_field :: (info: *Type_Info_Struct, name: string) -> *Type_Info_Struct_Member {
    for * info.members {
        if name == it.name return it;
    }

    return null;
}

to_string :: (s: *u8) -> string {
    strlen :: (x: *u8) -> s64 {
        count := 0;
        while << x  { x += 1; count += 1; }

        return count;
    }
    
    // @Temporary

    length := strlen(s);

    result: string;
    result.count = length;
    result.data = cast(*u8) s;
    return result;
}


XXX_temporary_get_start_of_data_segment :: () -> *u8 #foreign;
running_at_compile_time :: () -> bool #foreign;

to_c_string :: (s: string) -> *u8 {

    result : *u8 = alloc(s.count + 1);
    memcpy(result, s.data, s.count);
    result[s.count] = 0;

    return result;
}

copy_string :: (s: string) -> string {
    t : string;

    if !s.count return t;

    t.count = s.count;
    t.data = alloc(s.count);
    memcpy(t.data, s.data, s.count);

    return t;
}

//
// Windows-specific stuff.
//
// @Incomplete: We need a way to cordon off platform-specific code.
//

STD_INPUT_HANDLE  :: -10;
STD_OUTPUT_HANDLE :: -11;
STD_ERROR_HANDLE  :: -12;

HANDLE :: #type s64;   // This actually needs to be pointer-sized, so s32 in 32-bit, but as you see above, lots of people use integers too, arrrrgh!!

HWND :: HANDLE;

POINT :: struct {
    x, y: s32;
}

// @Cleanup: We needed these to be explicitly s32 for CreateFileA, but that is a bug...
FILE_SHARE_READ   : s32 : 0x1;
FILE_SHARE_WRITE  : s32 : 0x2;
FILE_SHARE_DELETE : s32 : 0x4;

FILE_CREATE_NEW        : s32 : 1;
FILE_CREATE_ALWAYS     : s32 : 2;
FILE_OPEN_EXISTING     : s32 : 3;
FILE_OPEN_ALWAYS       : s32 : 4;
FILE_TRUNCATE_EXISTING : s32 : 5;

INVALID_HANDLE_VALUE :: -1;

GetStdHandle :: (handle: s32) -> HANDLE #foreign;  // Here because Print needs it.
CloseHandle  :: (handle: HANDLE) -> s32 #foreign;
WriteFile    :: (handle: HANDLE, buffer: *void, buffer_length: s32, written_result: *s32, overlapped: *void) -> s32 #foreign;  // This is here because Print needs it.
GetLastError :: () -> s32 #foreign;
ExitProcess :: (exit_code: u32) -> void #foreign;
GetDesktopWindow :: () -> HWND #foreign;
GetCursorPos :: (p: *POINT) -> s32 #foreign;
ScreenToClient :: (hwnd: HWND, p: *POINT) -> s32 #foreign;

// ShellExecuteA :: (hwnd: HWND, lpOperation: *u8, lpFile: *u8, lpParmeters: *u8, lpDirectory: *u8, nShowCmd: int) -> s32 #foreign;
STARTUPINFO :: struct {
    cb: s32;
    lpReserved: *u8;
    lpDesktop: *u8;
    lpTitle: *u8;
    dwX: s32;
    dwY: s32;
    dwXSize: s32;
    dwYSize: s32;
    dwXCountChars: s32;
    dwYCountChars: s32;
    dwFillAttribute: s32;
    dwFlags: s32;
    wShowWindow: s16;
    cbReserved2: s16;
    lpReserved2: *u8;
    hStdInput: HANDLE;
    hStdOutput: HANDLE;
    hStdError: HANDLE;
}

CREATE_NO_WINDOW :: 0x08000000;
STARTF_USESTDHANDLES :: 0x00000100;

SECURITY_ATTRIBUTES :: struct {
    // Left empty for now since we don't use it.
}

PROCESS_INFORMATION :: struct {
    hProcess: HANDLE;
    hThread:  HANDLE;
    dwProcessId: s32;
    dwThreadId:  s32;
}

CreateProcessA :: (lpApplicationName: *u8, lpCommandLine: *u8, lpSecurityAttributes: *SECURITY_ATTRIBUTES, lpThreadAttributes: *SECURITY_ATTRIBUTES,
                  bInheritHandles: s32, dwCreationFlags: s32, lpEnvironment: *void, lpCurrentDirectory: *u8, lpStartupInfo: *STARTUPINFO, lpProcessInformation: *PROCESS_INFORMATION) -> s32 #foreign;

timeBeginPeriod :: (period: u32) -> u32 #foreign;

sleep_milliseconds :: (milliseconds: s32) {
    Sleep :: (milliseconds: s32) -> void #foreign;

    Sleep(milliseconds);
}

setcwd :: (s: string) -> bool {
    _chdir :: (s: *u8) -> s32 #foreign;

    // Allocate a C string. Yuck!
    
    c_string := to_c_string(s);
    defer free(c_string);

    chdir_result := _chdir(c_string);

    return chdir_result != 0;
}

min :: (a: $T, b: T) -> T {
    if a < b return a;
    return b;
}

max :: (a: $T, b: T) -> T {
    if a > b return a;
    return b;
}

