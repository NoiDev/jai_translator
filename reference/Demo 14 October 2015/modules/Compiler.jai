// The following things would be in a 'Compiler' namespace
// but we don't have a way to declare that in user programs yet
// so for now I am just prefixing things with compiler_.

// The AST is exposed via an export operation; what is here is a bit
// different from the internal implementation details of the compiler.
// Thus there is a light abstraction barrier, which means the compiler
// is free to change its choices about how information is stored,
// without breaking user programs.

Compiler_Message :: struct {
    Kind :: enum u8 {
        KIND_UNINITIALIZED : 0,
        FILE,
        COMPILATION_PHASE,
        CODE_TYPECHECKED,
        COMPLETE
    };

    kind := Kind.KIND_UNINITIALIZED;
    workspace: Workspace;
};

Compiler_Message_File :: struct {
    using m : Compiler_Message;

    name:    string;   // The name of the file. (May be null if compiling from a string).
    path:    string;   // The path to the file. (May be null if compiling from a string).
    opening: bool;     // If false, we are closing the file.
};

Compilation_Phase :: enum u32 {
    ALL_SOURCE_CODE_PARSED : 0,
    ALL_TARGET_CODE_BUILT  : 1,

    PRE_WRITE_EXECUTABLE   : 2,
    POST_WRITE_EXECUTABLE  : 3,
};

Compiler_Message_Compilation_Phase :: struct {
    using m : Compiler_Message;

    phase : Compilation_Phase.strict;

    executable_name: string;  // Will be set if phase == PRE_ or POST_WRITE_EXECUTABLE.
};

Compiler_Message_Code_Typechecked :: struct {
    using m : Compiler_Message;
    
    declaration: *Code_Declaration;
};

Code_Node :: struct {
    Kind :: enum u8 {
        UNINITIALIZED : 0,
        BLOCK     : 1,
        LITERAL   : 2,
        IDENT     : 3,
        STATEMENT : 4,

        OPERATOR_EXPRESSION : 5,
        // 6 is currently unused.
        PROCEDURE_CALL  : 7,
        ARRAY_SUBSCRIPT : 8,
        WHILE     : 9,
        IF        : 10,
        LOOP_CONTROL : 11,
        // 12 is currently unused.
        REMOVE    : 13,
        RETURN    : 14,
        EACH      : 15,

        TYPE_DEFINITION : 16,
        TYPE_INSTANTIATION : 17,
        ENUM : 18,

        PROCEDURE : 19,
        STRUCT : 20,
        COMMA_SEPARATED_ARGUMENTS : 21,
        EXTRACT : 22,
        SEQUENCE : 23,

        NEW_OR_DELETE : 24, 

        DECLARATION : 25,

        CAST_EXPRESSION : 26,
        USING : 27,
        DIRECTIVE_INLINE : 28,

        DIRECTIVE_IMPORT : 29,
        DIRECTIVE_LOAD : 30,

        DIRECTIVE_RUN : 31,
        DIRECTIVE_CHECK_CALL : 32,
        DIRECTIVE_ASSERT : 33,
        DIRECTIVE_IF_DEFINED : 34,
        DIRECTIVE_BAKE : 35,
        DIRECTIVE_MODIFY : 36,
        DIRECTIVE_FOREIGN_LIBRARY : 37,

        SIZE_OR_TYPE_OF : 38,
        CONTEXT_OR_PUSH : 39,

        NOTE : 40,
    };

    kind := Kind.UNINITIALIZED;

    type: *Type_Info;

    filename:    string;
    filepath:    string;

    line_number:      s64;
    character_number: s64;

    serial:           s64;
};

Code_Declaration :: struct {

    using base : Code_Node;

    name: string;

    expressions:   [] *Code_Node;

    root_expression:  *Code_Node;

    flags:   u32;

    IS_CONSTANT         :: 0x1;
    IS_PROCEDURE_HEADER :: 0x2;
    IS_STRUCT_MEMBER    :: 0x4;

    import_target: *Code_Declaration;
}

Code_Block :: struct {
    using base : Code_Node;

    parent : *Code_Block;
    belongs_to_struct: *Code_Struct;

    statements: [] *Code_Statement;
    // members:    [] *Code_Declaration;  // Variables declared in this scope.
    
    owning_statement: *Code_Statement;  // This will be in my parent block.
};

Code_Ident :: struct {
    using base : Code_Node;

    name: string;
    resolved_declaration: *Code_Declaration;
    block: *Code_Block;

    flags: u32;

    IS_STRUCT_DEREFERENCE :: 0x1;
};

Code_Statement :: struct {
    using base : Code_Node;

    expression : *Code_Node;  // This may be a Block.
};

Code_Struct :: struct {
    using base : Code_Node;

    header_declaration: *Code_Declaration;
    block: *Code_Block;
    notes: [] *Code_Note;
};

Code_Note :: struct {
    using base : Code_Node;

    text: string;
};

Code_Literal :: struct {
    using base : Code_Node;

    value: Any;
};

PROCEDURE_IS_FOREIGN :: 0x1;

Code_Procedure :: struct {
    using base : Code_Node;

    block:         *Code_Block;
    types_block:   *Code_Block;

    arguments: [] *Code_Declaration;
    returns:   [] *Code_Declaration;

    name: string;

    my_header:               *Code_Declaration;
    polymorph_source_header: *Code_Declaration;

    procedure_flags: u32;
};

Code_Procedure_Call :: struct {
    using base : Code_Node;

    procedure_expression: *Code_Node;
    arguments: [] *Code_Node;

    num_return_values_received: s64;
};

Code_Return :: struct {
    using base : Code_Node;

    values: [] *Code_Node;
};

Code_While :: struct {
    using base : Code_Node;

    condition: *Code_Node;
    block:     *Code_Block;
};

Code_For :: struct {
    using base : Code_Node;

    iteration_expression : *Code_Node;
    iteration_expression_right : *Code_Node;

    block : *Code_Block;

    ident_decl: *Code_Declaration;  // This is the ident of the iterator data variable.
    index_decl: *Code_Declaration;  // This is the ident of the iterator index variable.

    takes_pointer: bool;
};

Code_If :: struct {
    using base : Code_Node;

    condition:  *Code_Node;
    then_block: *Code_Block;
    else_block: *Code_Block;
};

Code_Operator_Expression :: struct {
    using base : Code_Node;

    operator_token_type: Compiler_Operators.loose;
    left:  *Code_Node;
    right: *Code_Node;
};

Compiler_Operators :: enum s64 {
    PLUS_EQUALS   : 259,
    MINUS_EQUALS : 260,
    TIMES_EQUALS  : 261,
    DIV_EQUALS    : 262,
    MOD_EQUALS    : 263,
    IS_EQUAL      : 264,
    IS_NOT_EQUAL  : 265,
    LOGICAL_AND   : 266,
    LOGICAL_OR    : 267,
    LESS_EQUALS   : 268,
    GREATER_EQUALS : 269,

    POINTER_DEREFERENCE : 273,

    CONDITIONAL_DEREFERENCE : 275,
    BITWISE_AND_EQUALS      : 276,
    BITWISE_OR_EQUALS       : 277,
    BITWISE_XOR_EQUALS      : 278,
    LOGICAL_XOR             : 279,
};

operator_to_string :: (oper: Compiler_Operators.loose) -> string {
    // Note: This ony handles the long operators.
    // Any operator with a value under 127 is a single character
    // represented by its own ASCII value. We don't handle those
    // here because we don't want to allocate and don't have a
    // short-string implemention.   -jblow, 6 September 2015.
    
    using Compiler_Operators.members;

    // @Cleanup: This cast maybe should be unnecessary?
    op := cast(Compiler_Operators.strict) oper;
    
    if op == PLUS_EQUALS   return "+=";
    if op == MINUS_EQUALS  return "-=";
    if op == TIMES_EQUALS  return "*=";
    if op == DIV_EQUALS    return "/=";
    if op == MOD_EQUALS    return "%=";
    if op == IS_EQUAL      return "==";
    if op == IS_NOT_EQUAL  return "!=";
    if op == LOGICAL_AND   return "&&";
    if op == LOGICAL_OR    return "||";
    if op == LESS_EQUALS   return "<=";
    if op == GREATER_EQUALS return ">=";
    
    return "";
}



//
// Hmm, I maybe would rather have compiler_create_workspace return (success, workspace), but
// currently foreign procedures can't return multiple values. This is because the C calling
// convention doesn't support more than one return, but for procedures that are implemented
// in our own stuff of course we can return multiple values. We could hack around the error
// message having a #foreign_system directive or something, but ... hmm.
//
//        -jblow, 10 September 2015
//
compiler_create_workspace  :: () -> Workspace #foreign;
compiler_destroy_workspace :: (w: Workspace) #foreign;

compiler_begin_intercept :: (w: Workspace) #foreign;
compiler_end_intercept   :: (w: Workspace) #foreign;

compiler_wait_for_message:: () -> *Compiler_Message #foreign;

compiler_pass_code       :: (m: *Compiler_Message) #foreign;
compiler_reject_code     :: (m: *Compiler_Message) #foreign;

compiler_report_error    :: (filename: string, line_number: s64, character_number: s64, error_text: string) #foreign;

compiler_get_type_table  :: (w: Workspace) -> [] *Type_Info #foreign;

// @Incomplete: compiler_call_library_intercepts
// @Incomplete: Implement #stopper

add_build_file :: (w: Workspace, filename: string) #foreign "add_build_file_on_workspace";
add_build_string :: (w: Workspace, data: string) #foreign "add_build_string_on_workspace";
set_build_file_path :: (w: Workspace, filename: string) #foreign "set_build_file_path_on_workspace";
update_build_options :: (w: Workspace, options: *Build_Options) #foreign "update_build_options_on_workspace";
