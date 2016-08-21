/*

  WARNING! Creating threads is not currently threadsafe!
  Only do it from the main thread for now. This is easily
  fixed, but we don't have mutexes yet...

*/

Thread_Index :: s64;
Thread_Proc  :: #type (*Thread) -> s64;

Thread_Os_Specific :: struct {
    windows_thread:    HANDLE;
    windows_thread_id: s32;
}

Thread :: struct {  // @Volatile! If you tweak with this, you need to change things like THREAD_STRUCT_STARTING_CONTEXT_OFFSET in the compiler's general.h and also in boilerplates.h
    index : Thread_Index;
    proc  : Thread_Proc;
    data  : *void;
    workspace : Workspace;  // This will be 0 if running a final program, nonzero inside the compiler.
    
    starting_context: Context;
    use_this_starting_context := false;

    using specific : Thread_Os_Specific;
}

global_thread_table : [..] *Thread;

thread_assert_all_are_stopped :: () {
    live_count := 0;

    for global_thread_table {
        if it != null  live_count += 1;
    }

//    print("live_count is %\n", live_count);
    assert(live_count == 0);
}

get_current_workspace :: () -> Workspace #foreign;

thread_create :: (proc: Thread_Proc) -> *Thread {
    windows_thread_id : s32;

    windows_thread_proc := cast(*void) __jai_windows_thread_entry_proc;

    thread := new Thread;
    thread.workspace = get_current_workspace();
    windows_thread := CreateThread(null, 0, windows_thread_proc, thread, CREATE_SUSPENDED, *windows_thread_id);

    if !windows_thread {
        // print("Thread create failed!!\n");
        free(thread);
        return null;
    }

    thread.proc = proc;

    thread.windows_thread_id = windows_thread_id;
    thread.windows_thread    = windows_thread;


    // Put the thread into an empty slot in the table.

    index := find_empty_slot(global_thread_table);
    if index == -1 {
        array_add(*global_thread_table, thread);
        index = global_thread_table.count - 1;
    } else {
        global_thread_table[index] = thread;
    }

    thread.index = index+1;

    return thread;
}

thread_start :: (thread: *Thread) {
    // print("Starting thread %\n", thread.windows_thread);
    ResumeThread(thread.windows_thread);
}

thread_is_done :: (thread: *Thread) -> bool {
    result := WaitForSingleObject(thread.windows_thread, 0);

    return result != WAIT_TIMEOUT;
}

thread_destroy :: (thread: *Thread) {
    CloseHandle(thread.windows_thread);

    assert(thread.index > 0);
    table_index := thread.index - 1;

    // print("thread index %, table entry = %, i am %\n", thread.index, global_thread_table[table_index], thread);

    assert(global_thread_table[table_index] == thread);
    global_thread_table[table_index] = null;
    free(thread);
}


Mutex :: struct {
    csection: CRITICAL_SECTION;
    
    // For Posix (Not done yet):
    // csection: pthread_mutex_t;
    // attr: pthread_mutexattr_t;
    initialized := false;
}

destroy :: (using m: *Mutex) {
    if !m.initialized return;

    DeleteCriticalSection(*csection);

    // pthread_mutex_destroy(*csection);
    // pthread_mutexattr_destroy(*attr);
}


init :: (using m: *Mutex) {
    InitializeCriticalSection(*csection);
    
    // pthread_mutexattr_init(*attr);
    // pthread_mutexattr_settype(*attr, PTHREAD_MUTEX_RECURSIVE);
    // pthread_mutex_init(*csection, *attr);

    initialized = true;
}


lock :: (using m: *Mutex) {
    EnterCriticalSection(*csection);

    // pthread_mutex_lock(*csection);
}


unlock :: (using m: *Mutex) {
    LeaveCriticalSection(*csection);

    // pthread_mutex_unlock(*csection);
}




Condition :: struct {
    event: HANDLE;
}

init :: (using cond : *Condition) {
    event = CreateEventA(null, 0, 0, null);
    assert(event != 0);
}

destroy :: (using cond : *Condition) {
    if event CloseHandle(event);
}

signal :: (using cond : *Condition) {
    // @Robustness:
    // @@ PulseEvent is unreliable in Win7, see remarks in:
    // http://msdn.microsoft.com/en-us/library/windows/desktop/ms684914(v=vs.85).aspx
    // Use SetEvent instead?

    ok := PulseEvent(event);
    assert(ok != 0);
}

wait_for :: (using cond : *Condition) {
    result := WaitForSingleObject(event, WIN_TIMEOUT_INFINITE);
    assert(result != WAIT_FAILED);
}




//
// Windows API stuff:
//

CREATE_SUSPENDED :: 0x4;
WAIT_TIMEOUT     :: 0x102;
WAIT_FAILED      :: 0xFFFFFFFF;

WIN_TIMEOUT_INFINITE  :: 0xFFFFFFFF;  // Note: Is just 'INFINITE' in winapi, temporarily making it longer-named to avoid name conflicts. -jblow, 27 September 2015

THREAD_PRIORITY_NORMAL       :: 0;
THREAD_PRIORITY_ABOVE_NORMAL :: 1;
THREAD_PRIORITY_HIGHEST      :: 2;


CreateThread :: (threadAttributes: *void, stackSize: s64, startAddress: *void, parameter: *void,
                 creation_flags: s32, threadIdReturn: *s32) -> HANDLE #foreign;

ResumeThread :: (thread: HANDLE) -> s32 #foreign;
SetThreadPriority :: (thread: HANDLE, priority: s32) -> s32 #foreign;

WaitForSingleObject :: (handle: HANDLE, milliseconds: s32) -> s32 #foreign;

__jai_windows_thread_entry_proc :: (parameter: *void) -> s32 #foreign;


DeleteCriticalSection     :: (section: *CRITICAL_SECTION) #foreign;
InitializeCriticalSection :: (section: *CRITICAL_SECTION) #foreign;
EnterCriticalSection      :: (section: *CRITICAL_SECTION) #foreign;
LeaveCriticalSection      :: (section: *CRITICAL_SECTION) #foreign;

PulseEvent :: (handle: HANDLE) -> s32 #foreign;
CreateEventA :: (lpEventAttributes: *void,
                 bManualReset:  s32,
                 bInitialState: s32,
                 lpName: *u8) -> HANDLE #foreign;



// Yuck:

/*
LIST_ENTRY :: struct {
    Flink :: *LIST_ENTRY;
    Blink :: *LIST_ENTRY;
}
*/

RTL_CRITICAL_SECTION_DEBUG :: struct {
/*
    WORD   Type;
    WORD   CreatorBackTraceIndex;
    struct _RTL_CRITICAL_SECTION *CriticalSection;
    LIST_ENTRY ProcessLocksList;
    DWORD EntryCount;
    DWORD ContentionCount;
    DWORD Flags;
    WORD   CreatorBackTraceIndexHigh;
    WORD   SpareWORD  ;
*/
}

RTL_CRITICAL_SECTION :: struct {
    DebugInfo: *RTL_CRITICAL_SECTION_DEBUG;

    //
    //  The following three fields control entering and exiting the critical
    //  section for the resource
    //

    LockCount: s32;
    RecursionCount: s32;
    OwningThread : HANDLE;        // from the thread's ClientId->UniqueThread
    LockSemaphore : HANDLE;
    SpinCount: *u32;        // force size on 64-bit systems when packed
}

CRITICAL_SECTION :: RTL_CRITICAL_SECTION;



