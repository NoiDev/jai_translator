#import "Basic";
#import "Print";
#import "File";
#import "Compiler";
#import "Sort";
#import "Crc";

indentation_level : s64 = 0;


//
// Section: build_steps
//

// "Build Steps" tend to be an annoying, heavily-OS-dependent situation that relies
// on external tools with poor interfaces or language semantics. As always, we can
// simplify the situation and remove the need for any external tools.

print_file_info :: (name: string) {
    print("file \"%\" ", name);

    s, success := read_entire_file(name);
    if !success {
        print("(does not exist.)\n");
        return;
    }

    crc := crc64(s);
    print("is % bytes, CRC is %.\n", s.count, formatInt(crc, base = 16));

    // Here we just printed the size of the file.
    // What might you do instead?
    // Copy the file to the proper target folder, or to an archive;
    // Run an executable modifier on the file; checksum it.
}

build_steps :: (message : *Compiler_Message) {
    using Compiler_Message.Kind.members;

    if message.kind == FILE {
        file := cast (*Compiler_Message_File) message;
        if file.opening print("::: Opening %\n", file.name);
        else            print("::: Closing %\n", file.name);

        return;
    }

    if message.kind == COMPILATION_PHASE {
        using Compilation_Phase.members;

        phase_message := cast (*Compiler_Message_Compilation_Phase) message;
        phase := phase_message.phase;
        
        if phase == ALL_SOURCE_CODE_PARSED {
            print(">>> All source code parsed.\n");
        } else if phase == ALL_TARGET_CODE_BUILT {
            print(">>> All target code built.\n");
        } else if phase == PRE_WRITE_EXECUTABLE {
            print(">>> Pre-write-executable: ");
            print_file_info(phase_message.executable_name);
        } else if phase == POST_WRITE_EXECUTABLE {
            print(">>> Post-write-executable: ");
            print_file_info(phase_message.executable_name);
        }
    }

    // print("Let's make the output file different.\n");
}


//
// Section: collect_procedure_stats.
//

stat_declarations: [..] *Code_Declaration;

Polymorph_Record :: struct {
    source: *Code_Declaration;
    instances:   s64;
    expressions: s64;
};

polymorph_records: [..] *Polymorph_Record;

find_or_add_polymorph_record :: (source: *Code_Declaration) -> *Polymorph_Record {
    for polymorph_records if it.source == source return it;

    record := new Polymorph_Record;
    record.source = source;
    
    array_add(*polymorph_records, record);
    return record;
}

collect_procedure_stats :: (message : *Compiler_Message) {
    using Compiler_Message.Kind.members;
    
    if message.kind == CODE_TYPECHECKED {
        code := cast(*Compiler_Message_Code_Typechecked) message;
        decl := code.declaration;

        polymorph_source_header : *Code_Declaration;

        if decl.root_expression {
            if decl.root_expression.kind == Code_Node.Kind.PROCEDURE {
                proc := cast(*Code_Procedure) decl.root_expression;
                if proc.procedure_flags & PROCEDURE_IS_FOREIGN return;

                polymorph_source_header = proc.polymorph_source_header;
            }
        }
        
        if (decl.expressions.count > 1) && !polymorph_source_header {
            array_add(*stat_declarations, decl);
        }

        if polymorph_source_header {
            record := find_or_add_polymorph_record(polymorph_source_header);
            record.instances += 1;
            record.expressions += decl.expressions.count;
        }
    }
}

print_procedure_stats :: () {

    if !stat_declarations.count return;  // If we didn't collect any stats, return silently.

    compare_declarations :: (a: *Code_Declaration, b: *Code_Declaration) -> s64 {
        delta := b.expressions.count - a.expressions.count;
        if delta return delta;

        return compare_strings(a.name, b.name);
    }
    
    bubble_sort(stat_declarations, compare_declarations);
    
    print("\n");
    print("Procedure size (by expression count):\n");
    print("------------------------------------ \n");

    FIELD_WIDTH :: 32;
    draw_dots := false;

    for stat_declarations {
        print("%", it.name);
        num_spaces := FIELD_WIDTH - it.name.count;
        if num_spaces < 1 num_spaces = 1;

        for 1..num_spaces {
            if draw_dots print(".");
            else print(" ");
        }

        print("%\n", it.expressions.count);
        draw_dots = !draw_dots;
    }

    print("\n");


    FIRST_FIELD_WIDTH  :: 32;
    SECOND_FIELD_WIDTH :: 10;

    if polymorph_records.count {
        print("Polymorph              expressions     instances\n");
        print("------------------------------------------------\n");

        compare :: (a: *Polymorph_Record, b: *Polymorph_Record) -> s64 {
            return b.expressions - a.expressions;
        }
        
        bubble_sort(polymorph_records, compare);
    }
    
    for polymorph_records {
        print("%", it.source.name);

        spacer := " ";
        if draw_dots spacer = ".";

        num_spaces := FIRST_FIELD_WIDTH - it.source.name.count;
        if num_spaces < 1 num_spaces = 1;

        for 1..num_spaces print(spacer);

        length := print("%", it.expressions);

        num_spaces = SECOND_FIELD_WIDTH - length;
        if num_spaces < 1 num_spaces = 1;

        for 1..num_spaces print(spacer);

        print("%\n", it.instances);
        draw_dots = !draw_dots;
    }

    if polymorph_records.count print("\n");
}

print_quoted_string :: (s: string) {
    print("\"");

    for 0..s.count-1 {
        c := s[it];
        if c == #char "\n" {
            print("\\n");
        } else if c == #char "\\" {
            print("\\");
        } else {
            print_single_byte_character(c);
        }
    }
    
    print("\"");
}

print_expression :: (expr : *Code_Node, toplevel: bool = false, name: string = "") {  // 'name' only set if toplevel.
    if !expr {
        print("(null)");
        return;
    }

    using Code_Node.Kind.members;

    if expr.kind == BLOCK {
        print("#block");
    } else if expr.kind == LITERAL {
        if toplevel print("(define % ", name);
        
        lit := cast(*Code_Literal) expr;
        if lit.value.type.type == Type_Info_Tag.STRING {
            print_quoted_string(<<cast(*string) lit.value.value_pointer);
        } else {
            print("%", lit.value);
        }

        if toplevel print(")");
    } else if expr.kind == IDENT {
        ident := cast(*Code_Ident) expr;
        print("%", ident.name);
    } else if expr.kind == STATEMENT {
        print("statement");
    } else if expr.kind == OPERATOR_EXPRESSION {
        op := cast(*Code_Operator_Expression) expr;

        print("(");

        token := op.operator_token_type;
        stoken := cast(Compiler_Operators.strict) token;
        handled := false;

        if !op.left {   // Special names for unary operators.
            if token == #char "*" {
                print("address-of");
                handled = true;
            }

            if stoken == Compiler_Operators.POINTER_DEREFERENCE {
                print("dereference");
                handled = true;
            }
        }

        if stoken == Compiler_Operators.LOGICAL_AND {
            print("and");
            handled = true;
        } else if stoken == Compiler_Operators.LOGICAL_OR {
            print("or");
            handled = true;
        }
        
        if !handled {
            if token < 128 {
                print_single_byte_character(token);
            } else {
                name := operator_to_string(token);

                if name.count {
                    print("%", name);
                } else {
                    // An operator we have not handled.
                    print("_operator_%", token);
                }
            }
        }
        
        print(" ");

        if op.left {
            print_expression(op.left);
            print(" ");
        }

        if op.right {
            print_expression(op.right);
        }

        print(")");
    } else if expr.kind == PROCEDURE_CALL {
        call := cast(*Code_Procedure_Call) expr;

        print("(");
        print_expression(call.procedure_expression);

        for call.arguments {
            print(" ");
            print_expression(it);
        }

        print(")");
    } else if expr.kind == ARRAY_SUBSCRIPT {
        print("(subscript XXXXXX)");
    } else if expr.kind == WHILE {
        _while := cast(*Code_While) expr;
        print("(while ");
        print_expression(_while.condition);
        print("\n");
        print_block(_while.block);
        print(")");
    } else if expr.kind == IF {
        _if := cast(*Code_If) expr;

        print("(if ");
        print_expression(_if.condition);

        if _if.then_block {
            print("\n");
            print_block(_if.then_block);
        }
        
        if _if.else_block {
            print("\n");
            print_block(_if.else_block);
        }
        
        print(")");
    } else if expr.kind == LOOP_CONTROL {
        print("(loop_control XXXXXX)");
    } else if expr.kind == REMOVE {
        print("(remove XXXXXX)");
    } else if expr.kind == RETURN {
        ret := cast(*Code_Return) expr;

        print("(return");
        for ret.values {
            print(" ");
            print_expression(it);
        }
        
        print(")");
    } else if expr.kind == EACH {
        _for := cast(*Code_For) expr;

        name := "";
        if _for.ident_decl name = _for.ident_decl.name;
        else name = _for.index_decl.name;

        assert(name.count > 0);
        
        if _for.iteration_expression_right print("(for % ", name);
        else print("(for_array % ", name);

        
        print_expression(_for.iteration_expression);
        
        if _for.iteration_expression_right {
            print(" ");
            print_expression(_for.iteration_expression_right);
        }

        print("\n");
        print_block(_for.block);
        print(")");
    } else if expr.kind == TYPE_DEFINITION {
        print("#type_definition");
    } else if expr.kind == TYPE_INSTANTIATION {
        print("#type_instantiation"); // @Cleanup: Unnecessary?
    } else if expr.kind == ENUM {
        print("#enum");
    } else if expr.kind == PROCEDURE {
        proc := cast(*Code_Procedure) expr;
        print_procedure(proc, toplevel, name);
        //if toplevel print_procedure(proc, name);
        //else print("#procedure_%", proc);  // @Incomplete: If a local procedure, print it...
    } else if expr.kind == STRUCT {
        print("#struct");
    } else if expr.kind == COMMA_SEPARATED_ARGUMENTS {
        print("#comma-separated");
    } else if expr.kind == EXTRACT {
        print("#extract");
    } else if expr.kind == SEQUENCE {
        print("#sequence");
    } else if expr.kind == NEW_OR_DELETE {
        print("(new_or_delete XXXXXX)");
    } else if expr.kind == DECLARATION {
        decl := cast(*Code_Declaration) expr;
        print("(let % ", decl.name);

        handled := false;
        if decl.root_expression {
            if decl.root_expression.kind == PROCEDURE {
                print("_local_proc_%", decl.name);
                handled = true;
            }
        }
        
        if !handled print_expression(decl.root_expression);
        
        print(")");
    } else if expr.kind == CAST_EXPRESSION {
        print("(cast_expression XXXXXX)");
    } else if expr.kind == USING {
        print("#using");
    } else if expr.kind == DIRECTIVE_INLINE {
        print("#directive_inline");
    } else if expr.kind == DIRECTIVE_IMPORT {
        print("#directive_import");
    } else if expr.kind == DIRECTIVE_LOAD {
        print("#directive_load");
    } else if expr.kind == DIRECTIVE_RUN {
        print("#directive_run");
    } else if expr.kind == DIRECTIVE_CHECK_CALL {
        print("#directive_check_call");
    } else if expr.kind == DIRECTIVE_ASSERT {
        print("#directive_assert");
    } else if expr.kind == DIRECTIVE_IF_DEFINED {
        print("#directive_if_defined");
    } else if expr.kind == DIRECTIVE_BAKE {
        print("#directive_bake");
    } else if expr.kind == DIRECTIVE_MODIFY {
        print("#directive_modify");
    } else if expr.kind == SIZE_OR_TYPE_OF {
        print("#size_or_type_of");
    } else if expr.kind == CONTEXT_OR_PUSH {
        print("#context_or_push");
    } else if expr.kind == NOTE {
        print("#note");
    } else {
        print("(#other_value_XXXXXX %).", expr.kind);
    }
}

print_block :: (block: *Code_Block) {
    if !block return;
    
    indentation_level += 1;

    for block.statements {
        for 1..indentation_level print("    ");
        print_expression(it.expression);

        if it_index < block.statements.count - 1 print("\n");
    }

    indentation_level -= 1;
}

print_procedure :: (proc : *Code_Procedure, toplevel: bool, name: string) {
    block := proc.block;

    if toplevel {
        print("(define (%", name);
    } else {
        print("(lambda (");
    }

    for proc.arguments {
        if toplevel print(" ");
        print("%", it.name);
    }
    
    print(")\n");

    print_block(block);

    print(")");
//    if toplevel print(")");
}



//
// Section: translate_to_scheme
//

// Because we are given the checked AST, we don't need a parser or typechecker!
// The compiler just tells us what it knows, rather than us having to reconstruct
// that from some overly-complicated external tool (in an error-prone way).

// Instead of Scheme, you could imagine translating a procedure into several
// different shader languages for different platforms.

// (You could have a software renderer that serves as a reference implementation,
// then export that same code as GPU shader code in different languages,
// without having to build some onerous tool.)

translate_to_scheme :: (message : *Compiler_Message) {
    using Compiler_Message.Kind.members;
    
    if message.kind == CODE_TYPECHECKED {
        code := cast(*Compiler_Message_Code_Typechecked) message;
        decl := code.declaration;

        if decl.filename != "demo.jai" return;  // Only print stuff from our own file, for demo purposes.
        
        name := decl.name;
        if !name name = "(unnamed)";

        annotation := "";
        if decl.flags & decl.IS_PROCEDURE_HEADER  annotation = "[procedure header]";
        print("\n;  % (%:%) %\n", name, decl.filename, decl.line_number, annotation);

        if decl.flags & decl.IS_PROCEDURE_HEADER  return;
        
        if decl.root_expression {
            expr := decl.root_expression;
            print_expression(expr, true, name);
        } else {
            print("No expression.");
        }

        print("\n");
        
        return;
    }

    // print("Unhandled message: %.\n", message.kind);
}


threadsafety_check :: (message : *Compiler_Message) {
    using Compiler_Message.Kind.members;
    
    if message.kind != CODE_TYPECHECKED return;
    ct := cast(*Compiler_Message_Code_Typechecked) message;
    decl := ct.declaration;

    if decl.filename == "Mixer_Async.jai" {
        scan_for_external_references(decl);
    }


    scan_for_external_references :: (decl: *Code_Declaration) {
        // if decl.expressions.count print("decl %, has % expressions.\n", decl.name, decl.expressions.count);

        for decl.expressions {
            if it.kind == Code_Node.Kind.IDENT {
                ident := cast(*Code_Ident) it;
                resolved := ident.resolved_declaration;
                if !resolved continue;  // @Hack?

                if ident.flags & ident.IS_STRUCT_DEREFERENCE continue;
                while resolved.import_target resolved = resolved.import_target;
                
                // If it's a struct member, it's okay.
                if resolved.flags & resolved.IS_STRUCT_MEMBER  continue;
                
                // If it's a constant literal, it's okay.
                if (resolved.flags & resolved.IS_CONSTANT) && resolved.root_expression {
                    if resolved.root_expression.kind == Code_Node.Kind.LITERAL continue;
                }
                
                if resolved.filename != decl.filename {
                    if !is_filename_whitelisted_for_threadsafety(decl.filename, resolved.filename) {
                        print("resolved flags %, ident flags %\n", resolved.flags, ident.flags);
                        // error := sprint("Identifier '%' may violate threadsafety (it refers to %:% s=%)\n", ident.name, resolved.filename, resolved.line_number, resolved.serial);
                        error := sprint("Identifier '%' may violate threadsafety (it refers to %:%)\n", ident.name, resolved.filename, resolved.line_number);
                        compiler_report_error(ident.filename, ident.line_number, ident.character_number, error);
                    }
                }
            }
        }
    }

    //
    // For clarity, again, we can put the following function into a separate file with
    // similar routines.
    //
    is_filename_whitelisted_for_threadsafety :: (source_file: string, dest_file: string) -> bool {
        if dest_file == "Preload.jai" return true;
        if dest_file == "Basic.jai" return true;
        if dest_file == "Thread.jai" return true;

        if source_file == "Mixer_Async.jai" {
            if dest_file == "Cached_Decoder.jai" return true;
            if dest_file == "Mixer_Win32.jai" return true;
        }

        return false;
    }
}


//
// Section: misra_checks
//

misra_checks :: (message : *Compiler_Message) {
    using Code_Node.Kind.members;
    using Compiler_Message.Kind.members;
    using Compiler_Operators.members;
    
    if message.kind != CODE_TYPECHECKED return;

    code := cast(*Compiler_Message_Code_Typechecked) message;
    decl := code.declaration;


/*
    if decl.is_procedure_header {
        print(";    header for  % (%:%)\n", decl.name, decl.filename, decl.line_number);
    }
*/

    // For convenience, the compiler gives us a flattened array of
    // all expressions in dependency order, so that we don't have to
    // do some kind of recursive tree walk ("visitor pattern")

    // print("decl % has % expressions.\n", decl.name, decl.expressions.count);

    for decl.expressions {

        // MISRA C rule 13.3: Floating-point expressions shall not be tested for equality or inequality.
        
        if it.kind == OPERATOR_EXPRESSION {
            op := cast(*Code_Operator_Expression) it;
            token := cast(Compiler_Operators.strict) op.operator_token_type;  // @Cleanup: Unnecessary cast?

            if (token == IS_EQUAL) || (token == IS_NOT_EQUAL) {
                // We only need to check one operand because if one is a float type, the other is guaranteed to be as well.
                assert(op.left.type == op.right.type);
                type := op.left.type;

                if type.type == Type_Info_Tag.FLOAT {
                    report_misra_error(it, "13.3: Floating-point expressions shall not be tested for equality or inequality.");
                }
            }
        }
        
        // MISRA C rule 16.2: Functions shall not call themselves, either directly or indirectly.

        if it.kind == PROCEDURE_CALL {
            call := cast(*Code_Procedure_Call) it;
            add_to_misra_call_graph(decl, call);
        }
        
        // MISRA C rule 17.5: The declaration of objects should contain no more than 2 levels of pointer indirection.

        if it.kind == DECLARATION {
            decl := cast(*Code_Declaration) it;
            if decl.root_expression {
                type := decl.root_expression.type;
                pointer_level := 0;

                while type.type == Type_Info_Tag.POINTER {
                    pointer_level += 1;

                    p := cast(*Type_Info_Pointer) type;
                    type = p.pointer_to;
                }

                if pointer_level > 2 {
                    report_misra_error(it, "17.5: The declaration of objects should contain no more than 2 levels of pointer indirection.");
                }
            }

            // To do: Also check types of global declarations.
            // This is trivial, but to do it I'd factor this code
            // into a separate function; but since this is an illustration
            // I wanted this code all in one block. -jblow, 6 September 2015.)
        }
    }
}

MISRA_RULE_16_2_STRING :: "16.2: Functions shall not call themselves, either directly or indirectly.";

Misra_Call_Record :: struct {
    caller: *Code_Declaration;
    procedures_called: [..] *Code_Declaration;
}

call_graph: [..] *Misra_Call_Record;


find_call_record :: (graph: [..] *Misra_Call_Record, decl: *Code_Declaration) -> *Misra_Call_Record {
    for call_graph  if it.caller == decl return it;
    return null;
}

add_to_misra_call_graph :: (decl: *Code_Declaration, call: *Code_Procedure_Call) {
    // We can only test calls for which the called procedure is known at compile time.
    // If you were really paranoid about this you might insert dynamic checks as well,
    // but today we are only demoing static checks.

    if call.procedure_expression.kind != Code_Node.Kind.IDENT  return;  // Bail.

    // Get the header for this declaration, since the header and body are different.
    assert(decl.root_expression != null);
    assert(decl.root_expression.kind == Code_Node.Kind.PROCEDURE);

    proc := cast(*Code_Procedure) decl.root_expression;
    header := proc.my_header;

    // Now compare the header versus the other thing.
    
    ident  := cast(*Code_Ident) call.procedure_expression;
    target := ident.resolved_declaration;
    
    // print("ADDING % -> %, decl is %, header is %, target is %\n", decl.name, ident.name, decl, header, target);
    
    if header == target {  // If we are calling ourself, it is right away no good!
        report_misra_error(*call.base, MISRA_RULE_16_2_STRING);
        return;
    }

    record := find_call_record(call_graph, header);

    if !record {
        // Add a new record to the call graph.
        record = new Misra_Call_Record;
        record.caller = header;
        array_add(*call_graph, record);
    }

    assert(record != null);

    array_add_if_unique(*record.procedures_called, target);
}

misra_call_graph_post_check :: () {
    changed := true;
    while changed {
        changed = false;  // Will get reset if we modify the call graph. Stop when no more modifications happen.

        for call_graph {
            count := it.procedures_called.count;
            plural := "procedure";
            if count > 1 plural = "procedures";
            print("MISRA call_graph post-check for % (it calls % %).\n", it.caller.name, count, plural);

            caller_record := it;
            
            for caller_record.procedures_called {
                // Anyone that I call, import their called procedures into me.
                // Speed warning: I am doing this in a really slow way. Hey, it's a demo.
                // If we never add anyone, we are done!

                other := find_call_record(call_graph, it);
                if !other continue;

                for other.procedures_called {
                    if it == caller_record.caller {
                        report_misra_error(*it.base, MISRA_RULE_16_2_STRING);
                        return;
                    }

                    added := array_add_if_unique(*caller_record.procedures_called, it);
                    if added changed = true;
                }
            }
        }
    }
}
                

report_misra_error :: (node: *Code_Node, description: string) {
    error := sprint("MISRA check failure, rule %", description);
    defer free(error.data);
    
    compiler_report_error(node.filename, node.line_number, node.character_number, error);
}

//
// Section: build proc
//

//DOING_MISRA :: true;
DOING_MISRA :: false;

build :: () {
    w := compiler_create_workspace();
    if !w return;
    
    build_options.executable_name    = "";      // No exe for our workspace.
    update_build_options();
    
    build_options.executable_name    = "demo";  // Other workspace is exe called "demo".
    update_build_options(w, *build_options);

    set_build_file_path(w, #filepath);
    add_build_file(w, "demo.jai");

    compiler_begin_intercept(w);

    while true {
        using Compiler_Message.Kind.members;
        
        message := compiler_wait_for_message();
        if !message continue;
        // print("setup got %\n", << message);
        if message.workspace != w continue;
        if message.kind == COMPLETE break;

        build_steps(message);
        // collect_procedure_stats(message);
        // translate_to_scheme(message);
        if DOING_MISRA misra_checks(message);
        threadsafety_check(message);
    }

    compiler_end_intercept(w);

    if DOING_MISRA misra_call_graph_post_check();
    print_procedure_stats();
    
    print("Done!\n");
}

#run build();

// Before running: Find all the MISRA demo code and enable it.
