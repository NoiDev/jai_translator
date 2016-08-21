#import "Basic";
#import "Print";
#import "GL";
#import "Pool";
#import "Math";
#import "File";
#import "Compiler";
#import "Font";

#load "whitelist.jai";
#load "bananas.jai";

DIR :: "/jai/traveller";


GO_BANANAS :: false;


// is_subclass_of can be a utility function that is re-used for many
// compile-time checks.
is_subclass_of :: (info: *Type_Info, base_name: string) -> bool {
    using Type_Info_Tag.members;

    if info.type != STRUCT return false;
    
    info_struct := cast(*Type_Info_Struct) info;

    while true {
        if info_struct.name == base_name return true;
        if info_struct.members.count == 0 break;

        // Should we support guys who have their 'using' in other than slot 0? Probably.
        member := info_struct.members[0];
        if !(member.flags & Type_Info_Struct_Member.USING) break;

        type := member.type;

        if type.type == STRUCT {
            info_struct = cast(*Type_Info_Struct) type;
            continue;
        } else if type.type == POINTER {
            pointer := cast(*Type_Info_Pointer) type;
            return is_subclass_of(pointer.pointer_to, base_name);
        } else break;

        // @Incomplete: We should also check for functions that return an Entity *.
    }
    return false;
}

// contains_pointer_to can be a utility function that is re-used for many
// compile-time checks.
contains_pointer_to :: (info: *Type_Info, base_name: string) -> bool {
    using Type_Info_Tag.members;

    // If info.type == STRUCT we can ignore it here; we will catch it later,
    // because that struct has its own entry in the type table!

    if info.type == POINTER {
        pointer := cast(*Type_Info_Pointer) info;
        to := pointer.pointer_to;
        if to.type == STRUCT return is_subclass_of(to, base_name);
        return contains_pointer_to(to, base_name);
    }

    if info.type == ARRAY {
        array := cast(*Type_Info_Array) info;
        return contains_pointer_to(array.element_type, base_name);
    }

    return false;
}


audit_for_entity_pointers :: (w: Workspace) {
    /*

      We had the ability to look at types in the program before, but we never had a way
      at build time to know the program was fully compiled so that we could inspect the 
      final types thoroughly, nor did we have a way to separate the target program from
      the build code.

     */

    using Type_Info_Tag.members;
    
    table := compiler_get_type_table(w);
    for info : table {
        if info.type != STRUCT continue;
        info_struct  := cast(*Type_Info_Struct) info;

        for info_struct.members {
            if (it_index == 0) && (it.flags & Type_Info_Struct_Member.USING) continue; // Ignore whoever we are derived from.

            // See note about code reviews below!
            if contains_pointer_to(it.type, "Entity") {
                if !is_whitelisted_for_entity_pointers(info_struct, *it) {
                    error := sprint("Error in struct '%': You can't store entity pointers on a struct. See http://gamebudz.com/wiki/code_guidelines/entity_pointers.html for a full explanation.\n", info_struct.name);
                    defer free(error.data);
                    
                    compiler_report_error(it.filename, it.line_number, it.character_number, error);
                }
            }
        }
    }
}

/*

About Code Reviews

A significant portion of what happens during code reviews is education of less-senior
programmers about what they should and shouldn't be doing in a particular codebase.

To the extent we can automate this with static checks, we save the senior person's time,
and increase the efficiency of the junior person (since we don't need to wait for a 
code review to identify and fix problems like the above.)

Since one of the jobs of the senior person is to be watchful for dangerous and destabilizing
things throughout the codebase, these checks can save his time (which is valuable, since
he's senior). With whitelisting confined to one file and the code for the checks confined
to another file, he has a place to focus his attention -- any violations of these checks
are going to show up as changes to the whitelists or the checking code, so they are 
easy to spot.

*/

workspaces_started   := 0;
workspaces_completed := 0;

workspace_info_array: [..] *Workspace_Info;

Workspace_Info :: struct {
    name: string;
    workspace: Workspace;
}

start_a_workspace :: (name: string, proc: (w: Workspace) -> void) {
    w := compiler_create_workspace();
    if !w {
        print("Workspace creation failed for '%'\n", name);
        return;
    }
    
    compiler_begin_intercept(w);

    proc(w);
    
    set_build_file_path(w, #filepath);
    add_build_file(w, "invaders.jai");

    workspaces_started += 1;

    info := new Workspace_Info;
    info.name = name;
    info.workspace = w;
    array_add(*workspace_info_array, info);
}

process_build_events :: () {
    while true {
        using Compiler_Message.Kind.members;

        message := compiler_wait_for_message();
        if !message break; // continue;

        if message.kind == COMPLETE {
            // We don't need to process messages for this;
            // after we get the COMPLETE message, we know all data structures
            // have been built (we even let you generate the executable), but
            // then we'll tell you if we don't like the code.
            if message.workspace > 1 audit_for_entity_pointers(message.workspace);
            workspaces_completed += 1;
        }

        if message.workspace > 1  bananas_send_procedure_stats(message);

        if !GO_BANANAS {
            if workspaces_completed >= workspaces_started break;
        }
    }
}

build :: () {
    build_options.executable_name = "";  // No executable for the primary workspace.
    update_build_options();

    bananas_start();

    while workspaces_completed < workspaces_started {
        process_build_events();
        bananas_update();
    }

    bananas_wait_for_exit();
}


setup_debug :: (w: Workspace) {
    options := build_options;

    options.optimization_level = Optimization_Level.DEBUG;
    options.emit_line_directives = false;
    options.executable_name = "traveller_debug";

    update_build_options(w, *options);
}

setup_release :: (w: Workspace) {
    options := build_options;

    options.optimization_level = Optimization_Level.RELEASE;
    options.array_bounds_check = Array_Bounds_Check_Mode.OFF;
    options.emit_line_directives = false;
    options.executable_name = "traveller";

    update_build_options(w, *options);
}

build_all :: () {
    start_a_workspace("Debug",   setup_debug);
    start_a_workspace("Release", setup_release);

    build();
}

build_debug :: () {
    start_a_workspace("Debug",   setup_debug);
    build();
}

build_release :: () {
    start_a_workspace("Release", setup_release);
    build();
}


#run build_release();
//#run build_all();
