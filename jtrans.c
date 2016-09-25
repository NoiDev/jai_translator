
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include <assert.h>

#define GENERATE_TOKEN_FILE     1
#define GENERATE_STRUCTURE_FILE 1

#define DEFAULT_TOKEN_BUFFER_SIZE 1024

typedef enum {
    /* KEYWORDS */
    TOKEN_TYPE_KEYWORD_AUTO,    /* 00 */
    TOKEN_TYPE_KEYWORD_BREAK,
    TOKEN_TYPE_KEYWORD_CASE,
    TOKEN_TYPE_KEYWORD_CHAR,
    TOKEN_TYPE_KEYWORD_CONST,
    TOKEN_TYPE_KEYWORD_CONTINUE,
    TOKEN_TYPE_KEYWORD_DEFAULT,
    TOKEN_TYPE_KEYWORD_DO,
    TOKEN_TYPE_KEYWORD_DOUBLE,
    TOKEN_TYPE_KEYWORD_ELSE,
    TOKEN_TYPE_KEYWORD_ENUM,    /* 10 */
    TOKEN_TYPE_KEYWORD_EXTERN,
    TOKEN_TYPE_KEYWORD_FLOAT,
    TOKEN_TYPE_KEYWORD_FOR,
    TOKEN_TYPE_KEYWORD_GOTO,
    TOKEN_TYPE_KEYWORD_IF,
    TOKEN_TYPE_KEYWORD_INT,
    TOKEN_TYPE_KEYWORD_LONG,
    TOKEN_TYPE_KEYWORD_REGISTER,
    TOKEN_TYPE_KEYWORD_RETURN,
    TOKEN_TYPE_KEYWORD_SHORT,   /* 20 */
    TOKEN_TYPE_KEYWORD_SIGNED,
    TOKEN_TYPE_KEYWORD_SIZEOF,
    TOKEN_TYPE_KEYWORD_STATIC,
    TOKEN_TYPE_KEYWORD_STRUCT,
    TOKEN_TYPE_KEYWORD_SWITCH,
    TOKEN_TYPE_KEYWORD_TYPEDEF,
    TOKEN_TYPE_KEYWORD_UNION,
    TOKEN_TYPE_KEYWORD_UNSIGNED,
    TOKEN_TYPE_KEYWORD_VOID,
    TOKEN_TYPE_KEYWORD_VOLATILE,    /* 30 */
    TOKEN_TYPE_KEYWORD_WHILE,

    /* SYMBOLS */
    TOKEN_TYPE_SINGLE_QUOTE,
    TOKEN_TYPE_DOUBLE_QUOTE,
    TOKEN_TYPE_OPEN_PAREN,
    TOKEN_TYPE_CLOSE_PAREN,
    TOKEN_TYPE_ARROW,
    TOKEN_TYPE_OPEN_CURLY_BRACE,
    TOKEN_TYPE_CLOSE_CURLY_BRACE,
    TOKEN_TYPE_OPEN_SQUARE_BRACE,
    TOKEN_TYPE_CLOSE_SQUARE_BRACE,   /* 40 */
    TOKEN_TYPE_COMPARISON_EQUALS,
    TOKEN_TYPE_NOT_EQUALS,
    TOKEN_TYPE_GREATER_EQUAL,
    TOKEN_TYPE_LESSER_EQUAL,
    TOKEN_TYPE_ASSIGNMENT_PLUS,
    TOKEN_TYPE_ASSIGNMENT_MINUS,
    TOKEN_TYPE_ASSIGNMENT_MULTPLY,
    TOKEN_TYPE_ASSIGNMENT_DIVIDE,
    TOKEN_TYPE_ASSIGNMENT_MODULUS,
    TOKEN_TYPE_ASSIGNMENT_LEFT_SHIFT,   /* 50 */
    TOKEN_TYPE_ASSIGNMENT_RIGHT_SHIFT,
    TOKEN_TYPE_ASSIGNMENT_AND,
    TOKEN_TYPE_ASSIGNMENT_OR,
    TOKEN_TYPE_ASSIGNMENT_XOR,
    TOKEN_TYPE_ASSIGNMENT_EQUALS,
    TOKEN_TYPE_AND,
    TOKEN_TYPE_OR,
    TOKEN_TYPE_NOT,
    TOKEN_TYPE_BITWISE_AND,
    TOKEN_TYPE_BITWISE_OR,  /* 60 */
    TOKEN_TYPE_BITWISE_XOR,
    TOKEN_TYPE_BITWISE_NOT,
    TOKEN_TYPE_COMMA,
    TOKEN_TYPE_COLON,
    TOKEN_TYPE_SEMICOLON,
    TOKEN_TYPE_DOT,
    TOKEN_TYPE_STAR,
    TOKEN_TYPE_LEFT_SHIFT,
    TOKEN_TYPE_RIGHT_SHIFT,
    TOKEN_TYPE_INCREMENT,   /* 70 */
    TOKEN_TYPE_DECREMENT,
    TOKEN_TYPE_PLUS,
    TOKEN_TYPE_MINUS,
    TOKEN_TYPE_MULTIPLY,
    TOKEN_TYPE_DIVIDE,
    TOKEN_TYPE_MODULUS,
    TOKEN_TYPE_OPEN_ANGLE_BRACE,
    TOKEN_TYPE_CLOSE_ANGLE_BRACE,
    TOKEN_TYPE_SLASH,
    TOKEN_TYPE_BACKSLASH,   /* 80 */
    TOKEN_TYPE_TERNARY,

    /* PREPROCESSOR */
    TOKEN_TYPE_PRE_INCLUDE,
    TOKEN_TYPE_PRE_DEFINE,
    TOKEN_TYPE_PRE_UNDEF,
    TOKEN_TYPE_PRE_IF,
    TOKEN_TYPE_PRE_IFDEF,
    TOKEN_TYPE_PRE_IFNDEF,
    TOKEN_TYPE_PRE_ELSE,
    TOKEN_TYPE_PRE_ENDIF,
    TOKEN_TYPE_PRE_ERROR,  /* 90 */
    TOKEN_TYPE_PRE_PRAGMA,
    TOKEN_TYPE_PRE_FILE_MACRO,
    TOKEN_TYPE_PRE_LINE_MACRO,
    TOKEN_TYPE_PRE_DATE_MACRO,
    TOKEN_TYPE_PRE_TIME_MACRO,
    TOKEN_TYPE_PRE_TIMESTAMP_MACRO,
    TOKEN_TYPE_PRE_HASH,
    TOKEN_TYPE_PRE_DOUBLE_HASH,

    /* CONTAINER TOKENS */
    TOKEN_TYPE_LINE_COMMENT,
    TOKEN_TYPE_BLOCK_COMMENT,  /* 100 */
    TOKEN_TYPE_STRING_LITERAL,
    TOKEN_TYPE_CHARACTER_LITERAL,
    TOKEN_TYPE_NUMBER,
    TOKEN_TYPE_IDENTIFIER,
    TOKEN_TYPE_BLANK_LINE,
    TOKEN_TYPE_END_OF_FILE,

    TOKEN_TYPE_COUNT
} token_type;

bool is_keyword_token_type(token_type type) {
    if (type >= TOKEN_TYPE_KEYWORD_AUTO && type <= TOKEN_TYPE_KEYWORD_WHILE) {
        return true;
    }
    return false;
}

void init_token_lookup_table(char *token_lookup[]) {

    /* KEYWORDS */
    token_lookup[TOKEN_TYPE_KEYWORD_AUTO] = "auto";
    token_lookup[TOKEN_TYPE_KEYWORD_BREAK] = "break";
    token_lookup[TOKEN_TYPE_KEYWORD_CASE] = "case";
    token_lookup[TOKEN_TYPE_KEYWORD_CHAR] = "char";
    token_lookup[TOKEN_TYPE_KEYWORD_CONST] = "const";
    token_lookup[TOKEN_TYPE_KEYWORD_CONTINUE] = "continue";
    token_lookup[TOKEN_TYPE_KEYWORD_DEFAULT] = "default";
    token_lookup[TOKEN_TYPE_KEYWORD_DO] = "do";
    token_lookup[TOKEN_TYPE_KEYWORD_DOUBLE] = "double";
    token_lookup[TOKEN_TYPE_KEYWORD_ELSE] = "else";
    token_lookup[TOKEN_TYPE_KEYWORD_ENUM] = "enum";
    token_lookup[TOKEN_TYPE_KEYWORD_EXTERN] = "extern";
    token_lookup[TOKEN_TYPE_KEYWORD_FLOAT] = "float";
    token_lookup[TOKEN_TYPE_KEYWORD_FOR] = "for";
    token_lookup[TOKEN_TYPE_KEYWORD_GOTO] = "goto";
    token_lookup[TOKEN_TYPE_KEYWORD_IF] = "if";
    token_lookup[TOKEN_TYPE_KEYWORD_INT] = "int";
    token_lookup[TOKEN_TYPE_KEYWORD_LONG] = "long";
    token_lookup[TOKEN_TYPE_KEYWORD_REGISTER] = "register";
    token_lookup[TOKEN_TYPE_KEYWORD_RETURN] = "return";
    token_lookup[TOKEN_TYPE_KEYWORD_SHORT] = "short";
    token_lookup[TOKEN_TYPE_KEYWORD_SIGNED] = "signed";
    token_lookup[TOKEN_TYPE_KEYWORD_SIZEOF] = "sizeof";
    token_lookup[TOKEN_TYPE_KEYWORD_STATIC] = "static";
    token_lookup[TOKEN_TYPE_KEYWORD_STRUCT] = "struct";
    token_lookup[TOKEN_TYPE_KEYWORD_SWITCH] = "switch";
    token_lookup[TOKEN_TYPE_KEYWORD_TYPEDEF] = "typedef";
    token_lookup[TOKEN_TYPE_KEYWORD_UNION] = "union";
    token_lookup[TOKEN_TYPE_KEYWORD_UNSIGNED] = "unsigned";
    token_lookup[TOKEN_TYPE_KEYWORD_VOID] = "void";
    token_lookup[TOKEN_TYPE_KEYWORD_VOLATILE] = "volatile";
    token_lookup[TOKEN_TYPE_KEYWORD_WHILE] = "while";

    /* SYMBOLS */
    token_lookup[TOKEN_TYPE_SINGLE_QUOTE] = "'";
    token_lookup[TOKEN_TYPE_DOUBLE_QUOTE] = "\"";
    token_lookup[TOKEN_TYPE_OPEN_PAREN] = "(";
    token_lookup[TOKEN_TYPE_CLOSE_PAREN] = ")";
    token_lookup[TOKEN_TYPE_OPEN_CURLY_BRACE] = "{";
    token_lookup[TOKEN_TYPE_CLOSE_CURLY_BRACE] = "}";
    token_lookup[TOKEN_TYPE_OPEN_SQUARE_BRACE] = "[";
    token_lookup[TOKEN_TYPE_CLOSE_SQUARE_BRACE] = "]";
    token_lookup[TOKEN_TYPE_COMPARISON_EQUALS] = "==";
    token_lookup[TOKEN_TYPE_ASSIGNMENT_EQUALS] = "=";
    token_lookup[TOKEN_TYPE_NOT_EQUALS] = "!=";
    token_lookup[TOKEN_TYPE_GREATER_EQUAL] = ">=";
    token_lookup[TOKEN_TYPE_LESSER_EQUAL] = "<=";
    token_lookup[TOKEN_TYPE_ASSIGNMENT_PLUS] = "+=";
    token_lookup[TOKEN_TYPE_ASSIGNMENT_MINUS] = "-=";
    token_lookup[TOKEN_TYPE_ASSIGNMENT_MULTPLY] = "*=";
    token_lookup[TOKEN_TYPE_ASSIGNMENT_DIVIDE] = "/=";
    token_lookup[TOKEN_TYPE_ASSIGNMENT_MODULUS] = "%=";
    token_lookup[TOKEN_TYPE_ASSIGNMENT_LEFT_SHIFT] = "<<=";
    token_lookup[TOKEN_TYPE_ASSIGNMENT_RIGHT_SHIFT] = ">>=";
    token_lookup[TOKEN_TYPE_ASSIGNMENT_AND] = "&=";
    token_lookup[TOKEN_TYPE_ASSIGNMENT_OR] = "|=";
    token_lookup[TOKEN_TYPE_ASSIGNMENT_XOR] = "^=";
    token_lookup[TOKEN_TYPE_AND] = "&&";
    token_lookup[TOKEN_TYPE_OR] = "||";
    token_lookup[TOKEN_TYPE_NOT] = "!";
    token_lookup[TOKEN_TYPE_BITWISE_AND] = "&";
    token_lookup[TOKEN_TYPE_BITWISE_OR] = "|";
    token_lookup[TOKEN_TYPE_BITWISE_XOR] = "^";
    token_lookup[TOKEN_TYPE_BITWISE_NOT] = "~";
    token_lookup[TOKEN_TYPE_COMMA] = ",";
    token_lookup[TOKEN_TYPE_COLON] = ":";
    token_lookup[TOKEN_TYPE_SEMICOLON] = ";";
    token_lookup[TOKEN_TYPE_DOT] = ".";
    token_lookup[TOKEN_TYPE_STAR] = "*";
    token_lookup[TOKEN_TYPE_ARROW] = "->";
    token_lookup[TOKEN_TYPE_LEFT_SHIFT] = "<<";
    token_lookup[TOKEN_TYPE_RIGHT_SHIFT] = ">>";
    token_lookup[TOKEN_TYPE_INCREMENT] = "++";
    token_lookup[TOKEN_TYPE_DECREMENT] = "--";
    token_lookup[TOKEN_TYPE_PLUS] = "+";
    token_lookup[TOKEN_TYPE_MINUS] = "-";
    token_lookup[TOKEN_TYPE_MULTIPLY] = "*";
    token_lookup[TOKEN_TYPE_DIVIDE] = "/";
    token_lookup[TOKEN_TYPE_MODULUS] = "%";
    token_lookup[TOKEN_TYPE_OPEN_ANGLE_BRACE] = "<";
    token_lookup[TOKEN_TYPE_CLOSE_ANGLE_BRACE] = ">";
    token_lookup[TOKEN_TYPE_SLASH] = "/";
    token_lookup[TOKEN_TYPE_BACKSLASH] = "\\";
    token_lookup[TOKEN_TYPE_TERNARY] = "?";

    /* PREPROCESSOR */
    token_lookup[TOKEN_TYPE_PRE_INCLUDE] = "#include";
    token_lookup[TOKEN_TYPE_PRE_DEFINE] = "#define";
    token_lookup[TOKEN_TYPE_PRE_UNDEF] = "#undef";
    token_lookup[TOKEN_TYPE_PRE_IF] = "#if";
    token_lookup[TOKEN_TYPE_PRE_IFDEF] = "#ifdef";
    token_lookup[TOKEN_TYPE_PRE_IFNDEF] = "#ifndef";
    token_lookup[TOKEN_TYPE_PRE_ELSE] = "#else";
    token_lookup[TOKEN_TYPE_PRE_ENDIF] = "#endif";
    token_lookup[TOKEN_TYPE_PRE_ERROR] = "#error";
    token_lookup[TOKEN_TYPE_PRE_PRAGMA] = "#pragma";
    token_lookup[TOKEN_TYPE_PRE_FILE_MACRO] = "__FILE__";
    token_lookup[TOKEN_TYPE_PRE_LINE_MACRO] = "__LINE__";
    token_lookup[TOKEN_TYPE_PRE_DATE_MACRO] = "__DATE__";
    token_lookup[TOKEN_TYPE_PRE_TIME_MACRO] = "__TIME__";
    token_lookup[TOKEN_TYPE_PRE_TIMESTAMP_MACRO] = "__TIMESTAMP__";
    token_lookup[TOKEN_TYPE_PRE_HASH] = "#";
    token_lookup[TOKEN_TYPE_PRE_DOUBLE_HASH] = "##";

}


typedef enum {
    warning_type_goto,
    warning_type_switch,
    warning_type_ternary,
    warning_type_preprocessor,
    warning_type_static_function,
    warning_type_static_variable,

    warning_type_count
} warning_type;

void issue_warning(warning_type type) {
    static int warning_counts[warning_type_count];

    warning_counts[type]++;

    if (warning_counts[type] > 1)
        return;

    switch (type) {
        case warning_type_goto:
            printf("Warning: Uses goto construct, which is currently not supported by JAI.\n");
            printf("   Note: \"goto\" statements and related labels have been left intact.\n");
            break;
        case warning_type_switch:
            printf("Warning: Uses switch construct, which is currently not supported by JAI.\n");
            printf("   Note: \"switch\", \"case\", and \"default\" statements  have been left intact.\n");
            break;
        case warning_type_ternary:
            printf("Warning: Uses ternary operator, which is currently not supported by JAI.\n");
            printf("   Note: Ternary statements have been left intact.\n");
            break;
        case warning_type_preprocessor:
            printf("Warning: Uses preprocessor directives that are not currently not supported by JAI.\n");
            printf("   Note: #include and some of #define are automatically translated, all others are left intact.\n");
        case warning_type_static_function:
            printf("Warning: Uses static functions which are not currently not supported by JAI.\n");
            printf("   Note: Static functions will be defined as normal, with a /* static */ tag before the definition.\n");
            break;
        case warning_type_static_variable:
            printf("Warning: Uses static variables which are not currently not supported by JAI.\n");
            printf("   Note: Static variables will be defined as normal, with a /* static */ tag before the definition.\n");
            break;
        default:
            break;
    }
}


/* Tokenization */

#define ASCII_NULL       0
#define ASCII_TAB        9
#define ASCII_LINE_FEED 10
#define ASCII_RETURN    13
#define ASCII_SPACE     32

typedef struct {
    int id;
    token_type type;
    char *text;
    int line_number;
    int char_number;
    char *line_start;
} token;

typedef struct {
    int last_token_id;
    int token_buffer_size;
    bool empty_line;
    int line_number;
    char *line_start_at;  /* Position in input file buffer. */
#if GENERATE_TOKEN_FILE
    FILE *token_file;
#endif
} token_context;

void eat_character(char **at) {
    (*at)++;
}

void add_token(token_type type, token *token_at, char *text, int text_length, char *input_file_at, token_context *context) {
    context->last_token_id++;
    if (context->last_token_id > context->token_buffer_size) {
        return;
    }
    char *token_text =  malloc((text_length+1)*sizeof(char));
    strncpy(token_text, text, text_length);
    token_text[text_length] = 0;
    token_at->id = context->last_token_id;
    token_at->type = type;
    token_at->text = token_text;
    token_at->line_number = context->line_number;
    token_at->char_number = input_file_at-context->line_start_at+1;
    token_at->line_start = context->line_start_at;
    /*token_at++;*/

#if GENERATE_TOKEN_FILE
    fprintf(context->token_file, "#%i, Line: %3i, Char: %3i, Type: %3i, Text: \"%s\"\n", token_at->id, token_at->line_number, token_at->char_number, token_at->type, token_at->text);
#endif
}

void cleanup_token_buffer(token *buffer, token *last_token) {
    token *token_at = buffer;
    while (token_at<last_token) {
        free(token_at->text);
        token_at++;
    }
}

bool is_numeric_char(char character) {
    if (character >= '0' && character <= '9') {
        return true;
    } else if (character == '.') {
        return true;
    }
    return false;
}

bool is_identifier_char(char character) {
    if (character >= 'A' && character <= 'Z') {
        return true;
    } else if (character >= 'a' && character <= 'z') {
        return true;
    } else if (character >= '0' && character <= '9') {
        return true;
    } else if (character == '_') {
        return true;
    }
    return false;
}



/* Lexing and Output */

#define EMIT_TEXT_INDENT(...) if (context->parse_mode) { fprintf(context->output_file, "%*s", 4*context->indent_depth, ""); fprintf(context->output_file, __VA_ARGS__); };
#define EMIT_TEXT(...) if (context->parse_mode) { fprintf(context->output_file, __VA_ARGS__); };

#if GENERATE_STRUCTURE_FILE
#define EMIT_STRUCTURE_FILE_LINE(...) fprintf(context->structure_file, "%*s", 4*context->parse_depth, ""); fprintf(context->structure_file, __VA_ARGS__)
#else
#define EMIT_STRUCTURE_FILE_LINE(...)
#endif

#define PARSE_MODE_OUTPUT    1
#define PARSE_MODE_NO_OUTPUT 0

#define BEGIN_PARSE_BLOCK(ID) EMIT_STRUCTURE_FILE_LINE("Begin Parse Block: %s\n", ID); context->parse_depth++;
#define END_PARSE_BLOCK(ID)   context->parse_depth--; EMIT_STRUCTURE_FILE_LINE("End Parse Block: %s\n", ID);

/* For structures that require non-trivial parsing to identify before outputing. */
#define BEGIN_HYPOTHETICAL_PARSE_BLOCK(TAG) if (context->parse_mode_gate_depth == 0) { \
    EMIT_STRUCTURE_FILE_LINE(">>> BEGIN HYPOTHETICAL: %s\n", TAG);  \
    context->parse_depth++;                                         \
    context->parse_mode_gate_depth = context->parse_depth;          \
    context->parse_mode = PARSE_MODE_NO_OUTPUT;                     \
}
#define END_HYPOTHETICAL_PARSE_BLOCK(TAG) if (context->parse_mode_gate_depth == context->parse_depth) {   \
    context->parse_mode_gate_depth = 0;                             \
    context->parse_depth--;                                         \
    EMIT_STRUCTURE_FILE_LINE("<<< END HYPOTHETICAL: %s\n", TAG);    \
    context->parse_mode = PARSE_MODE_OUTPUT;                        \
}

/* Sets flags to allow type parsing to be more greedy for casts and sizeof statements. */
#define BEGIN_TYPE_AS_ARGUMENT_BLOCK() context->parse_type_as_argument = true;
#define END_TYPE_AS_ARGUMENT_BLOCK()   context->parse_type_as_argument = false;

typedef struct {
    FILE *output_file;
#if GENERATE_STRUCTURE_FILE
    FILE *structure_file;
#endif
    bool parse_mode;
    int parse_mode_gate_depth;
    int parse_depth;
    int indent_depth;
    int line_number;
    token *first_unrecognized_token;
    int last_unrecognized_line_emitted;
    char *last_input_file_char_emitted;
    int unrecognized_count;
    int unsupported_count;

    /* @HACK */
    bool parse_type_as_argument; /* used to imform type parsing in casts and sizeof statements */
    bool extra_indent;           /* used for switch statement indents */
} parse_context;

/* Forward Declarations */
bool parse_scope();
bool parse_variable_declaration();
bool parse_evaluable_expression();
bool parse_enum_def();
bool parse_struct_def();
bool parse_typedef();

typedef enum {
    variable_type_void, /* void */
    variable_type_integer,
    variable_type_floating_point,
    variable_type_struct,
    variable_type_enum,
    variable_type_typedef
} variable_type;

typedef enum {
    sign_type_unspecified,
    sign_type_signed,
    sign_type_unsigned
} sign_type;

typedef struct {
    variable_type var_type;
    sign_type sign;
    int indirection_count;
    int size; /* in bits */
    char *text;
} type_description;

bool is_preprocessor_token(token it) {
    if (it.type >= TOKEN_TYPE_PRE_INCLUDE &&
            it.type <= TOKEN_TYPE_PRE_DOUBLE_HASH) {
        return true;
    }
    return false;
}

bool is_assignment_operator_token(token it) {
    if (it.type == TOKEN_TYPE_ASSIGNMENT_EQUALS          ||
            it.type == TOKEN_TYPE_ASSIGNMENT_PLUS        ||
            it.type == TOKEN_TYPE_ASSIGNMENT_MINUS       ||
            it.type == TOKEN_TYPE_ASSIGNMENT_MULTPLY     ||
            it.type == TOKEN_TYPE_ASSIGNMENT_DIVIDE      ||
            it.type == TOKEN_TYPE_ASSIGNMENT_MODULUS     ||
            it.type == TOKEN_TYPE_ASSIGNMENT_LEFT_SHIFT  ||
            it.type == TOKEN_TYPE_ASSIGNMENT_RIGHT_SHIFT ||
            it.type == TOKEN_TYPE_ASSIGNMENT_AND         ||
            it.type == TOKEN_TYPE_ASSIGNMENT_OR          ||
            it.type == TOKEN_TYPE_ASSIGNMENT_XOR) {
        return true;
    }
    return false;
}

bool is_unary_prefix_operator_token(token it) {
    if (it.type == TOKEN_TYPE_STAR            ||  /* (Dereference) */
            it.type == TOKEN_TYPE_BITWISE_AND ||  /* (Address)     */
            it.type == TOKEN_TYPE_BITWISE_NOT ||
            it.type == TOKEN_TYPE_NOT         ||
            it.type == TOKEN_TYPE_LEFT_SHIFT  ||
            it.type == TOKEN_TYPE_RIGHT_SHIFT ||
            it.type == TOKEN_TYPE_INCREMENT   ||
            it.type == TOKEN_TYPE_DECREMENT) {
        return true;
    }
    return false;
}

bool is_unary_postfix_operator_token(token it) {
    if (it.type == TOKEN_TYPE_INCREMENT       ||
            it.type == TOKEN_TYPE_DECREMENT   ||
            it.type == TOKEN_TYPE_LEFT_SHIFT  ||
            it.type == TOKEN_TYPE_RIGHT_SHIFT) {
        return true;
    }
    return false;
}

bool is_binary_operator_token(token it) {
    if (it.type == TOKEN_TYPE_COMPARISON_EQUALS     ||
            it.type == TOKEN_TYPE_NOT_EQUALS        ||
            it.type == TOKEN_TYPE_OPEN_ANGLE_BRACE  ||
            it.type == TOKEN_TYPE_CLOSE_ANGLE_BRACE ||
            it.type == TOKEN_TYPE_GREATER_EQUAL     ||
            it.type == TOKEN_TYPE_LESSER_EQUAL      ||
            it.type == TOKEN_TYPE_OR                ||
            it.type == TOKEN_TYPE_AND               ||
            it.type == TOKEN_TYPE_PLUS              ||
            it.type == TOKEN_TYPE_MINUS             ||
            it.type == TOKEN_TYPE_STAR              ||  /* (Multiply) */
            it.type == TOKEN_TYPE_SLASH             ||
            it.type == TOKEN_TYPE_MODULUS ) {
        return true;
    }
    return false;
}

void eat_token(token **token_at, parse_context *context, char *structure_identifier) {
    token *it = *token_at;

#if GENERATE_STRUCTURE_FILE
    if (context->parse_mode == PARSE_MODE_OUTPUT) {
        EMIT_STRUCTURE_FILE_LINE("%s - Token: #%i, Type: %i, Text: \"%s\", Line: %i, Char: %i \n", structure_identifier, it->id, it->type, it->text, it->line_number, it->char_number);
    } else {
        EMIT_STRUCTURE_FILE_LINE("(SILENT) %s - Token: #%i, Type: %i, Text: \"%s\", Line: %i, Char: %i \n", structure_identifier, it->id, it->type, it->text, it->line_number, it->char_number);
    }
#endif

    if (context->first_unrecognized_token) {
        EMIT_TEXT("\n");
        EMIT_TEXT_INDENT("/*END: Unrecognized Token Structure */\n");
        EMIT_TEXT("\n");
        context->first_unrecognized_token = NULL;
    }

    it++;
    *token_at = it;
}

void eat_token_unrecognized(token **token_at, parse_context *context, char *expected_structure) {
    if (context->parse_mode == PARSE_MODE_NO_OUTPUT)
        return;

    token *it = *token_at;
    EMIT_STRUCTURE_FILE_LINE("*** UNRECOGNIZED *** %i (\"%s\") Exp: %s Line: %i, Char: %i \n", it->type, it->text, expected_structure, it->line_number, it->char_number);

    if (!context->first_unrecognized_token) {
        context->unrecognized_count++;
        context->first_unrecognized_token = it;
        EMIT_TEXT("\n");
        EMIT_TEXT_INDENT("/* Unrecognized Token Structure, Expected: %s\n", expected_structure);
        EMIT_TEXT_INDENT("   Starting with Token #%i, Type: %3i, Text: \"%s\"\n", it->id, it->type, it->text);
        EMIT_TEXT_INDENT("   Orignal Code Starting at Line: %i, Char: %i */\n", it->line_number, it->char_number);
        EMIT_TEXT("\n");
    }
    int unrecognized_line_number = it->line_number;
    if (context->last_unrecognized_line_emitted<unrecognized_line_number && context->last_input_file_char_emitted[1]!=0) {
        /* Print Original Source Code */
        int current_line = context->last_unrecognized_line_emitted;
        char *line_start;
        char *line_end = context->last_input_file_char_emitted;
        while (current_line < unrecognized_line_number && line_end[1]!=0) {
            line_start = line_end + 1;
            line_end = strchr(line_start, '\n');
            current_line++;
        }
        EMIT_TEXT("%.*s\n", (int)(line_end-line_start), line_start);
        context->last_unrecognized_line_emitted = unrecognized_line_number;
        context->last_input_file_char_emitted = line_end;
    }
    it++;
    *token_at = it;
}


bool parse_blank_line(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (it[0].type != TOKEN_TYPE_BLANK_LINE) {
        return false;
    }
    BEGIN_PARSE_BLOCK("Blank Line");

    eat_token(&it, context, "Blank Line");

    END_PARSE_BLOCK("Blank Line");
    *token_at = it;
    return true;
}

bool parse_line_comment(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (it[0].type != TOKEN_TYPE_LINE_COMMENT) {
        return false;
    }
    BEGIN_PARSE_BLOCK("Line Comment");

    token *comment_token = it;

    eat_token(&it, context, "Line Comment");

    if (comment_token[-1].line_number == comment_token[0].line_number) {
        EMIT_TEXT("  //%s", comment_token->text);
    } else {
        EMIT_TEXT("\n");
        EMIT_TEXT_INDENT("//%s", comment_token->text);
    }

    END_PARSE_BLOCK("Line Comment");
    *token_at = it;
    return true;
}

bool parse_block_comment(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (it[0].type != TOKEN_TYPE_BLOCK_COMMENT) {
        return false;
    }
    BEGIN_PARSE_BLOCK("Block Comment");

    token *comment_token = it;

    eat_token(&it, context, "Block Comment");

    if (comment_token[-1].line_number == comment_token[0].line_number) {
        if (comment_token[0].line_number == comment_token[1].line_number) {
            EMIT_TEXT("/*%s*/", comment_token->text);
        } else {
            EMIT_TEXT("  /*%s*/", comment_token->text);
        }
    } else {
        EMIT_TEXT("\n");
        EMIT_TEXT_INDENT("/*%s*/", comment_token->text);
    }

    END_PARSE_BLOCK("Block Comment");
    *token_at = it;
    return true;
}

bool parse_include(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (it[0].type != TOKEN_TYPE_PRE_INCLUDE) {
        return false;
    }
    BEGIN_PARSE_BLOCK("#include");

    token *include_token = it;

    /* Library Includes */
    if (include_token[1].type == TOKEN_TYPE_OPEN_ANGLE_BRACE
            && include_token[2].type == TOKEN_TYPE_IDENTIFIER) {

        eat_token(&it, context, "Include Library");
        eat_token(&it, context, "Include Library \"<\"");
        eat_token(&it, context, "Included Library Name");

        char *library_name = include_token[2].text;
        EMIT_TEXT("#import \"%s\";", library_name);

        while (it[0].type != TOKEN_TYPE_CLOSE_ANGLE_BRACE) {
            eat_token(&it, context, "Skipping remaining <> contents");
        }
        eat_token(&it, context, "Include Library \">\"");

    /* File Includes */
    } else if (include_token[1].type == TOKEN_TYPE_STRING_LITERAL) {

        eat_token(&it, context, "Include File");
        eat_token(&it, context, "Included File Name");

        char *file_name = include_token[1].text;
        char *file_ext = strchr(file_name, '.');
        char *converted_file_name;

        if (file_ext) {
            int base_name_length = file_ext-file_name;
            converted_file_name = malloc((base_name_length+5)*sizeof(char));;
            strncpy(converted_file_name, file_name, base_name_length);
            converted_file_name[base_name_length] = 0;
            strcat(converted_file_name, ".jai");
        } else {
            converted_file_name = malloc((strlen(file_name)+1)*sizeof(char));;
            strcpy(converted_file_name, file_name);
        }
        EMIT_TEXT("#load \"%s\";", converted_file_name);
        free(converted_file_name);
    }

    END_PARSE_BLOCK("#include");
    *token_at = it;
    return true;
}

bool parse_define(token **token_at, parse_context *context) {
    token *it = *token_at;

    bool is_translatable_define = false;

    if (it[0].type == TOKEN_TYPE_PRE_DEFINE &&
            it[1].type == TOKEN_TYPE_IDENTIFIER &&
            (it[2].type == TOKEN_TYPE_IDENTIFIER ||
             it[2].type == TOKEN_TYPE_NUMBER     ||
             it[2].type == TOKEN_TYPE_CHARACTER_LITERAL ||
             it[2].type == TOKEN_TYPE_STRING_LITERAL)) {
        is_translatable_define = true;
    }

    if (!is_translatable_define) {
        return false;
    }
    BEGIN_PARSE_BLOCK("#define");

    token *define_token = it;

    eat_token(&it, context, "Define");
    eat_token(&it, context, "Define: Name");
    eat_token(&it, context, "Define: Value");

    EMIT_TEXT("%s :: %s;", define_token[1].text, define_token[2].text);

    END_PARSE_BLOCK("#define");
    *token_at = it;
    return true;
}

bool parse_general_preprocessor(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (!is_preprocessor_token(it[0])) {
        return false;
    }
    BEGIN_PARSE_BLOCK("Preprocessor Directive");

    context->unsupported_count++;
    issue_warning(warning_type_ternary);

    int line_number_of_directive = it[0].line_number;

    char *line_start = it[0].line_start;
    char *line_end = strchr(line_start, '\n');
    if (!line_end)
        line_end = strchr(line_start, '\r');
    assert(line_end);

    EMIT_TEXT("%.*s", (int)(line_end-line_start), line_start);
    eat_token(&it, context, "Preprocessor Directive");

    while (it[0].line_number == line_number_of_directive) {
        eat_token(&it, context, "Preprocessor Directive: Continuation");
    }

    END_PARSE_BLOCK("Preprocessor Directive");
    *token_at = it;
    return true;
}

bool parse_type_expression(token **token_at, parse_context *context) {
    token *it = *token_at;
    BEGIN_PARSE_BLOCK("Potential Type Expression");

    type_description desc;

    desc.var_type = variable_type_void;
    desc.sign = sign_type_unspecified;
    desc.indirection_count = 0;
    desc.size = 0;
    desc.text = NULL;

    token *type_expr_start = it;

    bool parsing = true;
    while (parsing) {
        if (it[0].type == TOKEN_TYPE_KEYWORD_VOID) {
            eat_token(&it, context, "Type Expression: void");
            desc.var_type = variable_type_void;

        /* Floating-Point Types */
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_FLOAT) {
            eat_token(&it, context, "Type Expression: float");
            desc.var_type = variable_type_floating_point;
            desc.size = 32;
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_DOUBLE) {
            eat_token(&it, context, "Type Expression: double");
            desc.var_type = variable_type_floating_point;
            desc.size = 64;
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_LONG &&
                it[1].type == TOKEN_TYPE_KEYWORD_DOUBLE) {
            eat_token(&it, context, "Type Expression: long double");
            desc.var_type = variable_type_floating_point;
            desc.size = 80;

        /* Integer Types */
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_CHAR) {
            eat_token(&it, context, "Type Expression: char");
            desc.var_type = variable_type_integer;
            desc.size = 8;
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_SHORT) {
            eat_token(&it, context, "Type Expression: short");
            desc.var_type = variable_type_integer;
            desc.size = 16;
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_INT) {
            eat_token(&it, context, "Type Expression: int");
            desc.var_type = variable_type_integer;
            desc.size = 16;
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_LONG) {
            eat_token(&it, context, "Type Expression: long");
            desc.var_type = variable_type_integer;
            desc.size = 32;

        /* Sign Types */
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_SIGNED) {
            eat_token(&it, context, "Type Expression: signed");
            desc.sign = sign_type_signed;
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_UNSIGNED) {
            eat_token(&it, context, "Type Expression: unsigned");
            desc.sign = sign_type_unsigned;

        /* Enum */
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_ENUM) {
            eat_token(&it, context, "Type Expression: enum");
            desc.var_type = variable_type_enum;
            if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
                desc.text = it[0].text;
                eat_token(&it, context, "Type Expression: enum name");
            }

        /* Struct */
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_STRUCT) {
            eat_token(&it, context, "Type Expression: struct");
            if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
                desc.text = it[0].text;
                eat_token(&it, context, "Type Expression: struct name");
            }

        /* Typedef */
        } else if (it[0].type == TOKEN_TYPE_IDENTIFIER &&
                (it[1].type == TOKEN_TYPE_IDENTIFIER ||
                 it[1].type == TOKEN_TYPE_STAR ||
                    (context->parse_type_as_argument &&
                     it[1].type == TOKEN_TYPE_CLOSE_PAREN))) {
            /* Extra check to differentiate custom types from variable names. */
            desc.text = it[0].text;
            desc.var_type = variable_type_typedef;
            eat_token(&it, context, "Type Expression: custom type");

        /* Pointers */
        } else if (it[0].type == TOKEN_TYPE_STAR && it != type_expr_start) {
            eat_token(&it, context, "Type Expression: pointer");
            desc.indirection_count++;

            /* Pointer indicators are the final part fo a type expression, if present. */
            /* Stop parsing in this case. */
            if (it[0].type != TOKEN_TYPE_STAR) {
                parsing = false;
            }

        /* No more type tokens */
        } else {
            parsing = false;
        }
    }

    END_PARSE_BLOCK("Potential Type Expression");
    /* No tokens eaten, not a type expression */
    if (it == type_expr_start) {
        return false;
    }

    BEGIN_PARSE_BLOCK("Type Expression");


    /* resolve c-style types to jai-style types */

    if (desc.indirection_count > 0) {
        for (int i=0; i<desc.indirection_count; i++) {
            EMIT_TEXT("*");
        }
    }

    if (desc.var_type == variable_type_void && desc.sign != sign_type_unspecified)
        desc.var_type = variable_type_integer;

    if (desc.var_type == variable_type_void) {
        EMIT_TEXT("void");
    } else if (desc.var_type == variable_type_integer) {
        if (desc.size < 8) {
            desc.size = 64;
        }
        if (desc.sign == sign_type_unspecified) {
            if (desc.size==8) {                     /* char => u8 */
                desc.sign = sign_type_unsigned;
            } else if (desc.size > 8) {             /* all other integers default to signed */
                desc.sign = sign_type_signed;
            }
        }
        if (desc.sign == sign_type_signed) {
            EMIT_TEXT("s%i", desc.size);
        } else if (desc.sign == sign_type_unsigned) {
            EMIT_TEXT("u%i", desc.size);
        }
    } else if (desc.var_type == variable_type_floating_point) {
        if (desc.size <= 32) {
            EMIT_TEXT("float");
        } else {
            EMIT_TEXT("float%i", desc.size);
        }
    } else if (desc.var_type == variable_type_enum) {
        EMIT_TEXT("enum %s", desc.text);
    } else if (desc.var_type == variable_type_struct) {
        EMIT_TEXT("struct %s", desc.text);
    } else if (desc.var_type == variable_type_typedef) {
        EMIT_TEXT("%s", desc.text);
    } else {
        printf("Unrecognized Variable Type: %i\n", desc.var_type);
        assert(false);
    }

    END_PARSE_BLOCK("Type Expression");
    *token_at = it;
    return true;
}

bool parse_array_subscript(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (it[0].type != TOKEN_TYPE_OPEN_SQUARE_BRACE) {
        return false;
    }
    BEGIN_PARSE_BLOCK("Array Subscript");

    while (it[0].type==TOKEN_TYPE_OPEN_SQUARE_BRACE) {
        eat_token(&it, context, "Array Subscript: Start");
        EMIT_TEXT("[");
        if (!parse_evaluable_expression(&it, context)) {
            eat_token_unrecognized(&it, context, "Array Subscript Expression");
        }
        if (it[0].type == TOKEN_TYPE_CLOSE_SQUARE_BRACE) {
            eat_token(&it, context, "Array Subscript: End");
            EMIT_TEXT("]");
        } else {
            eat_token_unrecognized(&it, context, "Array Subscript: End");
        }
    }

    END_PARSE_BLOCK("Array Subscript");
    *token_at = it;
    return true;
}

bool parse_subscripts_and_dereferences(token **token_at, parse_context *context) {
    token *it = *token_at;
    BEGIN_PARSE_BLOCK("Potential Subscripts and dereferences");

    bool found = false;
    bool parsing = true;

    while (parsing) {
        parsing = false;

        /* Subscripts */
        if (parse_array_subscript(&it, context)) {
            found = true;
            parsing = true;
        }

        /* Struct Dereference */
        if (it[0].type == TOKEN_TYPE_DOT && it[1].type == TOKEN_TYPE_IDENTIFIER) {
            char *name_text = it[1].text;

            eat_token(&it, context, "Struct member dereference");
            eat_token(&it, context, "Struct member name");

            found = true;
            parsing = true;

            EMIT_TEXT(".%s", name_text);

        /* Pointer Dereference */
        } else if (it[0].type == TOKEN_TYPE_ARROW && it[1].type == TOKEN_TYPE_IDENTIFIER) {
            char *name_text = it[1].text;

            eat_token(&it, context, "Struct pointer dereference");
            eat_token(&it, context, "Struct member name");

            found = true;
            parsing = true;

            EMIT_TEXT(".%s", name_text);
        }
    }

    END_PARSE_BLOCK("Potential Subscripts and dereferences");
    *token_at = it;
    return found;
}

bool parse_evaluable_expression(token **token_at, parse_context *context) {
    token *it = *token_at;

    BEGIN_PARSE_BLOCK("Evaluable Expression");

    bool found = false;

    /* Block Comment */
    if (parse_block_comment(&it, context)) {
        found = true;
    }

    /* Parenthetical */
    if (it[0].type==TOKEN_TYPE_OPEN_PAREN) {
        found = true;
        eat_token(&it, context, "Parentheical: Start");

        token *contents_start = it;

        bool cast;

        BEGIN_HYPOTHETICAL_PARSE_BLOCK("Test for cast expression");
        BEGIN_TYPE_AS_ARGUMENT_BLOCK();
        cast = parse_type_expression(&it, context);
        END_TYPE_AS_ARGUMENT_BLOCK();

        if (cast && it[0].type == TOKEN_TYPE_CLOSE_PAREN) {
            eat_token(&it, context, "Parenthetical: End of potential cast");
            cast = parse_evaluable_expression(&it, context); /* Check for object of cast */
        }
        END_HYPOTHETICAL_PARSE_BLOCK("Test for cast expression");

        it = contents_start;

        if (cast) {
            BEGIN_PARSE_BLOCK("Cast");

            EMIT_TEXT("cast(");
            BEGIN_TYPE_AS_ARGUMENT_BLOCK();
            parse_type_expression(&it, context);
            END_TYPE_AS_ARGUMENT_BLOCK();

            if (it[0].type==TOKEN_TYPE_CLOSE_PAREN) {
                eat_token(&it, context, "Parentheical: End");
            }
            EMIT_TEXT(") ");

            parse_evaluable_expression(&it, context);

            END_PARSE_BLOCK("Cast");

        } else {
            EMIT_TEXT("(");
            bool parsing = true;
            while (parsing && it[0].type != TOKEN_TYPE_CLOSE_PAREN) {

                if (!parse_evaluable_expression(&it, context)) {
                    parsing = false;
                    eat_token_unrecognized(&it, context, "Evaluable Expression in Parenthetical");
                }
            }

            if (it[0].type==TOKEN_TYPE_CLOSE_PAREN) {
                eat_token(&it, context, "Parentheical: End");
            }
            EMIT_TEXT(")");
        }
    }

    /* Prefix Operators */
    if (is_unary_prefix_operator_token(it[0])) {
        token *operator_token = it;
        bool is_value_prefix_expression = false;

        BEGIN_HYPOTHETICAL_PARSE_BLOCK("Test for target of prefix operator");
        eat_token(&it, context, "Potential Prefix Operator");
        is_value_prefix_expression = parse_evaluable_expression(&it, context);
        END_HYPOTHETICAL_PARSE_BLOCK("Test for target of prefix operator");

        it = operator_token;

        if (is_value_prefix_expression) {
            found = true;

            eat_token(&it, context, "Evaluable: Unary Prefix Operator");

            EMIT_TEXT("%s", operator_token->text);
            parse_evaluable_expression(&it, context);

        }
    }


    /* sizeof */
    if (it[0].type == TOKEN_TYPE_KEYWORD_SIZEOF) {
        found = true;

        eat_token(&it, context, "Evaluable: sizeof");
        EMIT_TEXT("sizeof(");

        if (it[0].type == TOKEN_TYPE_OPEN_PAREN) {
            eat_token(&it, context, "Evaluable: sizeof: Open Parenthetical");
        }

        BEGIN_TYPE_AS_ARGUMENT_BLOCK();
        if (!parse_type_expression(&it, context)) {
            eat_token_unrecognized(&it, context, "Evaluable: sizeof: Type Expression");
        }
        END_TYPE_AS_ARGUMENT_BLOCK();

        if (it[0].type == TOKEN_TYPE_CLOSE_PAREN) {
            eat_token(&it, context, "Evaluable: sizeof: Close Parenthetical");
        }

        EMIT_TEXT(")");
    }



    /* Function Call */
    if (it[0].type == TOKEN_TYPE_IDENTIFIER && it[1].type == TOKEN_TYPE_OPEN_PAREN) {
        found = true;

        token *function_name_token = it;

        eat_token(&it, context, "Evaluable: Function Call: Name");
        eat_token(&it, context, "Evaluable: Function Call: Start of Arguments");
        EMIT_TEXT("%s(", function_name_token->text);

        BEGIN_PARSE_BLOCK("Function Call");
        while (it[0].type != TOKEN_TYPE_CLOSE_PAREN) {
            if (!parse_evaluable_expression(&it, context)) {
                eat_token_unrecognized(&it, context, "Function Argument in Evaluable Function Call");
            }

            if (it[0].type == TOKEN_TYPE_COMMA) {
                eat_token(&it, context, "Evaluable: Function: Argument Separator");
                EMIT_TEXT(", ");
            }
        }
        END_PARSE_BLOCK("Function Call");

        eat_token(&it, context, "Evaluable: Function Call: End of Arguments");
        EMIT_TEXT(")");
    }


    /* Values */

    /* Plain Number */
    if (it[0].type == TOKEN_TYPE_NUMBER) {
        found = true;
        token *value_token = it;

        eat_token(&it, context, "Evaluable: Number");
        EMIT_TEXT("%s", value_token->text);

    /* Negative Number */
    } else if (it[0].type == TOKEN_TYPE_MINUS && it[1].type == TOKEN_TYPE_NUMBER) {
        found = true;
        token *value_token = &it[1];

        eat_token(&it, context, "Evaluable: Negative Number: Sign");
        eat_token(&it, context, "Evaluable: Negative Number: Numeric Component");
        EMIT_TEXT("-%s", value_token->text);

    /* Variable */
    } else if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
        found = true;
        token *value_token = it;

        eat_token(&it, context, "Evaluable: Identifier");
        EMIT_TEXT("%s", value_token->text);

        parse_subscripts_and_dereferences(&it, context);

    /* String Literal */
    } else if (it[0].type == TOKEN_TYPE_STRING_LITERAL) {
        found = true;
        token *value_token = it;

        eat_token(&it, context, "Evaluable: String Literal");
        EMIT_TEXT("\"%s\"", value_token->text);

    /* String Literal */
    } else if (it[0].type == TOKEN_TYPE_CHARACTER_LITERAL) {
        found = true;
        token *value_token = it;

        eat_token(&it, context, "Evaluable: Character Literal");
        EMIT_TEXT("#char \"%s\"", value_token->text);

    /* File Macro */
    } else if (it[0].type == TOKEN_TYPE_PRE_FILE_MACRO) {
        found = true;

        eat_token(&it, context, "Evaluable: Preprocessor File Macro");
        EMIT_TEXT("#file");

    /* Line Macro */
    } else if (it[0].type == TOKEN_TYPE_PRE_LINE_MACRO) {
        found = true;

        eat_token(&it, context, "Evaluable: Preprocessor Line Macro");
        EMIT_TEXT("#line");
    }

    if (!found) {
        END_PARSE_BLOCK("Evaluable Expression");
        return false;
    }


    /* Test for following evaluables */

    /* Postfix Operators */
    if (is_unary_postfix_operator_token(it[0])) {
        token *operator_token = it;

        eat_token(&it, context, "Evaluable: Unary Postfix Operator");
        EMIT_TEXT("%s", operator_token->text);
    }

    /* Binary Operators */
    if (is_binary_operator_token(it[0])) {
        token *operator_token = it;

        eat_token(&it, context, "Evaluable: Binary Operator");
        EMIT_TEXT(" %s ", operator_token->text);

        parse_evaluable_expression(&it, context);
    }

    /* Ternary Operator */
    if (it[0].type == TOKEN_TYPE_TERNARY) {

        context->unsupported_count++;
        issue_warning(warning_type_ternary);

        eat_token(&it, context, "Evaluable: Ternary Operator: Start");
        EMIT_TEXT(" ? ");

        if (!parse_evaluable_expression(&it, context)) {
            eat_token_unrecognized(&it, context, "Evaluable Expression in Ternary (Position 2)");
        }

        if (it[0].type == TOKEN_TYPE_COLON) {
            eat_token(&it, context, "Evaluable: Ternary Operator: Separator");
            EMIT_TEXT(" : ");

            if (!parse_evaluable_expression(&it, context)) {
                eat_token_unrecognized(&it, context, "Evaluable Expression in Ternary (Position 3)");
            }
        }
    }

    END_PARSE_BLOCK("Evaluable Expression");
    *token_at = it;
    return true;
}

bool parse_statement(token **token_at, parse_context *context) {
    token *it = *token_at;
    BEGIN_PARSE_BLOCK("Statement");

    token *statement_start = it;

    /* Variable Declaration */
    if (parse_variable_declaration(&it, context)) {
        /* Note parse_vairable_declaration eats entire statement to ';'. */

        END_PARSE_BLOCK("Statement");
        *token_at = it;
        return true;
    }

    /* Assignment */
    bool parse_assignment = false;

    BEGIN_HYPOTHETICAL_PARSE_BLOCK("Test for assignment");
    while (it[0].type != TOKEN_TYPE_SEMICOLON) {
        if (is_assignment_operator_token(it[0])) {
            eat_token(&it, context, "Statement: Found assignment token");
            parse_assignment = true;
            break;
        }
        eat_token(&it, context, "Statement: Scan for assignment token");
    }
    END_HYPOTHETICAL_PARSE_BLOCK("Test for assignment");

    it = statement_start;

    if (parse_assignment) {
        if (it[0].type == TOKEN_TYPE_STAR) {
            eat_token(&it, context, "Statement: Assignment to dereferenced pointer");
            EMIT_TEXT("*");
        }
        if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
            char *name_text = it[0].text;
            eat_token(&it, context, "Statement: Assignment Target");
            EMIT_TEXT("%s", name_text);
        }

        parse_subscripts_and_dereferences(&it, context);

        token *operator_token = &it[0];

        eat_token(&it, context, "Statement: Assignment Operator");
        EMIT_TEXT(" %s ", operator_token->text);

        parse_evaluable_expression(&it, context);

    /* Return */
    } else if (it[0].type == TOKEN_TYPE_KEYWORD_RETURN) {
        eat_token(&it, context, "Statement: Return");
        EMIT_TEXT("return");

        if (it[0].type != TOKEN_TYPE_SEMICOLON) {
            EMIT_TEXT(" ");
        }

        parse_evaluable_expression(&it, context);

    /* Break */
    } else if (it[0].type == TOKEN_TYPE_KEYWORD_BREAK) {
        eat_token(&it, context, "Statement: Break");

        EMIT_TEXT("break");

    /* Continue */
    } else if (it[0].type == TOKEN_TYPE_KEYWORD_CONTINUE) {
        eat_token(&it, context, "Statement: Continue");

        EMIT_TEXT("continue");

    /* Generic Evaluable */
    } else {
        parse_evaluable_expression(&it, context);
    }

    /* End of Statement */
    if (it[0].type == TOKEN_TYPE_SEMICOLON) {
        eat_token(&it, context, "Statement: End");
        EMIT_TEXT(";");

        *token_at = it;
        END_PARSE_BLOCK("Statement");
        return true;
    }

    END_PARSE_BLOCK("Statement");
    return false;
}

bool parse_if(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (it[0].type != TOKEN_TYPE_KEYWORD_IF) {
        return false;
    }
    BEGIN_PARSE_BLOCK("If Statement");

    eat_token(&it, context, "If Statement");
    EMIT_TEXT("if (");

    if (it[0].type == TOKEN_TYPE_OPEN_PAREN) {
        eat_token(&it, context, "If Statement: Start of Conditional");
    }

    bool parsing = true;
    while (parsing && it[0].type != TOKEN_TYPE_CLOSE_PAREN) {
        if (!parse_evaluable_expression(&it, context)) {
            parsing = false;
            eat_token_unrecognized(&it, context, "If Statement: Conditional");
        }
    }

    if (it[0].type == TOKEN_TYPE_CLOSE_PAREN) {
        eat_token(&it, context, "If Statement: End of Conditional");
    }
    EMIT_TEXT(")");

    if (it[0].type == TOKEN_TYPE_OPEN_CURLY_BRACE) {
        EMIT_TEXT(" ");

    parse_scope(&it, context);

    } else {

        context->indent_depth++;
        if (!parse_statement(&it, context))
            eat_token_unrecognized(&it, context, "If Statement: Inline");
        context->indent_depth--;
    }

    if (it[0].type == TOKEN_TYPE_KEYWORD_ELSE) {
        if (it[-1].type == TOKEN_TYPE_CLOSE_CURLY_BRACE)
            EMIT_TEXT(" ");
        eat_token(&it, context, "Else Statement");
        EMIT_TEXT("else ");

        if (it[0].type == TOKEN_TYPE_KEYWORD_IF) {
            parse_if(&it, context);

        } else if (!parse_scope(&it, context)) {

            context->indent_depth++;
            if (!parse_statement(&it, context))
                eat_token_unrecognized(&it, context, "Else Statement: Inline");
            context->indent_depth--;
        }
    }

    END_PARSE_BLOCK("If Statement");
    *token_at = it;
    return true;
}

bool parse_for(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (it[0].type != TOKEN_TYPE_KEYWORD_FOR) {
        return false;
    }
    BEGIN_PARSE_BLOCK("For Loop");

    eat_token(&it, context, "For Statement");
    EMIT_TEXT("for (");

    if (it[0].type == TOKEN_TYPE_OPEN_PAREN) {
        eat_token(&it, context, "For Statement: Start of Control Statement");
    }

    /* For Loop Control Statements */
    BEGIN_PARSE_BLOCK("For Control Statements");
    if (!parse_statement(&it, context)) {
        eat_token_unrecognized(&it, context, "For Statement: Initializer");
    }
    EMIT_TEXT(" ");

    if (!parse_statement(&it, context)) {
        eat_token_unrecognized(&it, context, "For Statement: Conditional");
    }
    EMIT_TEXT(" ");

    if (!parse_evaluable_expression(&it, context)) {
        eat_token_unrecognized(&it, context, "For Statement: Increment");
    }
    END_PARSE_BLOCK("For Control Statements");

    if (it[0].type == TOKEN_TYPE_CLOSE_PAREN) {
        eat_token(&it, context, "For Statement: End of Control Statement");
    }

    EMIT_TEXT(") ");

    /* For Loop Scope */
    if (!parse_scope(&it, context)) {
        eat_token_unrecognized(&it, context, "For Statement: Scope");
    }

    END_PARSE_BLOCK("For Loop");
    *token_at = it;
    return true;
}

bool parse_while(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (it[0].type != TOKEN_TYPE_KEYWORD_WHILE) {
        return false;
    }
    BEGIN_PARSE_BLOCK("While Loop");

    eat_token(&it, context, "While Statement");
    EMIT_TEXT("while (");

    /* While Loop Control Statement */
    if (it[0].type == TOKEN_TYPE_OPEN_PAREN) {
        eat_token(&it, context, "While Statement: Start of Conditional");
    }

    BEGIN_PARSE_BLOCK("While Conditional");
    if (!parse_evaluable_expression(&it, context)) {
        eat_token_unrecognized(&it, context, "While Statement: Conditional");
    }
    END_PARSE_BLOCK("While Conditional");

    if (it[0].type==TOKEN_TYPE_CLOSE_PAREN) {
        eat_token(&it, context, "While Statement: End of Conditional");
    }

    EMIT_TEXT(") ");

    /* While Loop Scope */
    if (!parse_scope(&it, context)) {
        eat_token_unrecognized(&it, context, "While Statement: Scope");
    }

    END_PARSE_BLOCK("While Loop");
    *token_at = it;
    return true;
}

bool parse_do(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (it[0].type != TOKEN_TYPE_KEYWORD_DO) {
        return false;
    }
    BEGIN_PARSE_BLOCK("Do Loop");

    eat_token(&it, context, "Do-While Statement: Do");
    EMIT_TEXT("do ");

    if (!parse_scope(&it, context)) {
        eat_token_unrecognized(&it, context, "Do-While Statement: Scope");
    }

    if (it[0].type == TOKEN_TYPE_KEYWORD_WHILE) {
        eat_token(&it, context, "Do-While Statement: While");
    }

    if (it[1].type == TOKEN_TYPE_OPEN_PAREN) {
        eat_token(&it, context, "Do-While Statement: Start of Conditional");
    }

    EMIT_TEXT(" while (");

    if (!parse_evaluable_expression(&it, context)) {
        eat_token_unrecognized(&it, context, "Do-While Statement: Conditional");
    }

    if (it[0].type==TOKEN_TYPE_CLOSE_PAREN) {
        eat_token(&it, context, "Do-While Statement: End of Conditional");
    }

    if (it[0].type==TOKEN_TYPE_SEMICOLON) {
        eat_token(&it, context, "Do-While Statement: End of Statement");
    }

    EMIT_TEXT(");");

    END_PARSE_BLOCK("Do Loop");
    *token_at = it;
    return true;
}

bool parse_goto(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (it[0].type != TOKEN_TYPE_KEYWORD_GOTO) {
        return false;
    }
    BEGIN_PARSE_BLOCK("Goto");

    context->unsupported_count++;
    issue_warning(warning_type_goto);

    eat_token(&it, context, "Goto Statement: Goto");

    char *label_name;
    if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
        label_name = it->text;
        eat_token(&it, context, "Goto Statement: Label Name");
    } else {
        label_name = "/* Un-Named */";
    }

    if (it[0].type == TOKEN_TYPE_SEMICOLON)
        eat_token(&it, context, "Goto Statement: End of Statement");

    EMIT_TEXT("goto %s;", label_name);

    END_PARSE_BLOCK("Goto");
    *token_at = it;
    return true;
}

bool parse_goto_label(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (!(it[0].type == TOKEN_TYPE_IDENTIFIER && it[1].type == TOKEN_TYPE_COLON)) {
        return false;
    }
    BEGIN_PARSE_BLOCK("Goto Label");

    context->unsupported_count++;
    issue_warning(warning_type_goto);

    token *label_token = it;

    eat_token(&it, context, "Goto Label: Label Name");
    eat_token(&it, context, "Goto Label: End of Label");

    EMIT_TEXT("%s:", label_token->text);

    END_PARSE_BLOCK("Goto Label");
    *token_at = it;
    return true;
}

bool parse_switch(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (it[0].type != TOKEN_TYPE_KEYWORD_SWITCH) {
        return false;
    }
    BEGIN_PARSE_BLOCK("Switch");

    eat_token(&it, context, "Switch Statement");
    EMIT_TEXT("switch (");

    if (it[0].type == TOKEN_TYPE_OPEN_PAREN)
        eat_token(&it, context, "Switch Statement: Start of Test Value");

    context->unsupported_count++;
    issue_warning(warning_type_switch);

    bool parsing = true;
    while (parsing && it[0].type != TOKEN_TYPE_CLOSE_PAREN) {
        if (!parse_evaluable_expression(&it, context)) {
            eat_token_unrecognized(&it, context, "Switch Statement: Test Expression");
            parsing = false;
        }
    }

    if (it[0].type == TOKEN_TYPE_CLOSE_PAREN)
        eat_token(&it, context, "Switch Statement: End of Test Value");

    EMIT_TEXT(") ");

    context->extra_indent = true;
    if (!parse_scope(&it, context)) {
        context->extra_indent = false;
        eat_token_unrecognized(&it, context, "Switch Statement: Scope");
    }

    END_PARSE_BLOCK("Switch");
    *token_at = it;
    return true;
}

bool parse_case(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (it[0].type != TOKEN_TYPE_KEYWORD_CASE) {
        return false;
    }
    BEGIN_PARSE_BLOCK("Switch Case");

    context->unsupported_count++;
    issue_warning(warning_type_switch);

    eat_token(&it, context, "Case Statement");

    context->indent_depth--;
    EMIT_TEXT_INDENT("case ");

    /* Technically this should only be an integer or an identifier, but this will catch both cases in a single expression */
    if (!parse_evaluable_expression(&it, context)) {
        eat_token_unrecognized(&it, context, "Case Statement: Label or Number");
    }

    if (it[0].type == TOKEN_TYPE_COLON)
        eat_token(&it, context, "Case Statement: End of Case Label");

    EMIT_TEXT(":");
    context->indent_depth++;

    END_PARSE_BLOCK("Switch Case");
    *token_at = it;
    return true;
}

bool parse_default(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (it[0].type != TOKEN_TYPE_KEYWORD_DEFAULT) {
        return false;
    }
    BEGIN_PARSE_BLOCK("Switch Default");

    context->unsupported_count++;
    issue_warning(warning_type_switch);

    eat_token(&it, context, "Default Statement");

    context->indent_depth--;
    EMIT_TEXT_INDENT("default:");
    context->indent_depth++;

    if (it[0].type == TOKEN_TYPE_COLON)
        eat_token(&it, context, "Default Statement: End of Case Label");

    END_PARSE_BLOCK("Switch Default");
    *token_at = it;
    return true;
}

bool parse_variable_declaration(token **token_at, parse_context *context) {
    token *it = *token_at;

    BEGIN_HYPOTHETICAL_PARSE_BLOCK("Test for Variable Declaration");
    bool is_static = false;
    if (it[0].type == TOKEN_TYPE_KEYWORD_STATIC) {
        eat_token(&it, context, "Variable: Static");
        is_static = true;
    }

    token *declaration_start = it;

    bool continue_parsing = true;
    if (!parse_type_expression(&it, context)) {
        continue_parsing = false;
    }
    if (it[0].type != TOKEN_TYPE_IDENTIFIER) {
        continue_parsing = false;
    }
    END_HYPOTHETICAL_PARSE_BLOCK("Test for Variable Declaration");

    if (!continue_parsing) {
        return false;
    }
    BEGIN_PARSE_BLOCK("Variable Declaration");

    char *variable_name = it[0].text;

    eat_token(&it, context, "Variable Declaration");

    if (is_static) {
        context->unsupported_count++;
        issue_warning(warning_type_static_variable);

        EMIT_TEXT("/* static */ ");
    }
    EMIT_TEXT("%s : ", variable_name);

    it = declaration_start;

    parse_type_expression(&it, context);
    eat_token(&it, context, "Variable Declaration: Variable Name");

    parse_array_subscript(&it, context);

    /* Chained Plain Declaration */
    if (it[0].type == TOKEN_TYPE_COMMA) {
        while (it[0].type == TOKEN_TYPE_COMMA) {
            eat_token(&it, context, "Variable Declaration: Chained Declaration");

            if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
                variable_name = it[0].text;

                eat_token(&it, context, "Variable Declaration: Variable Name");

                EMIT_TEXT("\n");
                EMIT_TEXT_INDENT("%s : ", variable_name);

                token *next = it;
                it = declaration_start;
                parse_type_expression(&it, context);
                it = next;

                parse_array_subscript(&it, context);
            }
        }

    /* Declaration and Assignment */
    } else if (is_assignment_operator_token(it[0])) {
        char *operator_text = it[0].text;

        eat_token(&it, context, "Variable Declaration: Assignment Operator");
        EMIT_TEXT(" %s ", operator_text);

        if (!parse_evaluable_expression(&it, context)) {
            eat_token_unrecognized(&it, context, "Assignment expression after declaration");
        }

    }

    if (it[0].type == TOKEN_TYPE_SEMICOLON) {
        eat_token(&it, context, "Variable Declaration: End of Declaration");
    }

    EMIT_TEXT(";");

    END_PARSE_BLOCK("Variable Declaration");
    *token_at = it;
    return true;
}

bool parse_scope(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (it[0].type != TOKEN_TYPE_OPEN_CURLY_BRACE) {
        return false;
    }
    BEGIN_PARSE_BLOCK("Scope");

    eat_token(&it, context, "Scope: Start");
    EMIT_TEXT("{");

    int original_indent = context->indent_depth;

    context->indent_depth++;

    if (context->extra_indent) {
        context->indent_depth++;
        context->extra_indent = false;
    }

    while (it[0].type != TOKEN_TYPE_CLOSE_CURLY_BRACE) {

        if (parse_line_comment(&it, context))
            continue;

        if (parse_block_comment(&it, context))
            continue;

        EMIT_TEXT("\n");

        if (parse_blank_line(&it, context))
            continue;

        if (parse_general_preprocessor(&it, context))
            continue;

        if (parse_enum_def(&it, context))
            continue;

        if (parse_struct_def(&it, context))
            continue;

        if (parse_typedef(&it, context))
            continue;

        if (parse_default(&it, context))
            continue;

        if (parse_case(&it, context))
            continue;

        if (parse_goto_label(&it, context))
            continue;

        EMIT_TEXT_INDENT("");

        if (parse_if(&it, context))
            continue;

        if (parse_for(&it, context))
            continue;

        if (parse_do(&it, context))
            continue;

        if (parse_while(&it, context))
            continue;

        if (parse_switch(&it, context))
            continue;

        if (parse_goto(&it, context))
            continue;

        if (parse_statement(&it, context))
            continue;

        eat_token_unrecognized(&it, context, "Statement In Scope");
    }

    eat_token(&it, context, "Scope: End");

    context->indent_depth = original_indent;

    EMIT_TEXT("\n");
    EMIT_TEXT_INDENT("}");

    END_PARSE_BLOCK("Scope");
    *token_at = it;
    return true;
}

bool parse_function_definition(token **token_at, parse_context *context) {
    token *it = *token_at;

    BEGIN_HYPOTHETICAL_PARSE_BLOCK("Test for Function Declaration");
    bool is_static = false;
    if (it[0].type == TOKEN_TYPE_KEYWORD_STATIC) {
        eat_token(&it, context, "Function Declaration: Static");
        is_static = true;
    }

    bool is_extern = false;
    if (it[0].type == TOKEN_TYPE_KEYWORD_EXTERN) {
        eat_token(&it, context, "Variable: Extern");
        is_extern = true;
    }

    token *function_start = it;

    bool parsing = true;
    if (!parse_type_expression(&it, context)) {
        parsing = false;
    }
    if (it[0].type != TOKEN_TYPE_IDENTIFIER) {
        parsing = false;
    }
    END_HYPOTHETICAL_PARSE_BLOCK("Test for Function Declaration");

    if (!parsing) {
        return false;
    }
    BEGIN_PARSE_BLOCK("Function Declaration");

    token function_name_token = it[0];

    eat_token(&it, context, "Function Declaration: Name");

    if (it[0].type == TOKEN_TYPE_OPEN_PAREN) {
        eat_token(&it, context, "Function Declaration: Start of Arguments");
    }

    if (is_static) {
        context->unsupported_count++;
        issue_warning(warning_type_static_function);

        EMIT_TEXT("/* static */ ");
    }

    EMIT_TEXT("%s :: (", function_name_token.text);

    /* Parse Argument List */
    BEGIN_PARSE_BLOCK("Function Arguments");

    while (it && it[0].type != TOKEN_TYPE_CLOSE_PAREN) {

        if (parse_block_comment(&it, context))
            continue;

        if (it[0].type == TOKEN_TYPE_KEYWORD_CONST) {
            /* Quietly eat all "const" tokens */
            eat_token(&it, context, "Function Declaration: Arguemnts: Const");
        }

        bool found_type_exp = true;
        token *argument_start = it;

        BEGIN_HYPOTHETICAL_PARSE_BLOCK("Test for type expression for argument");
        if (!parse_type_expression(&it, context)) {
            found_type_exp = false;
            eat_token_unrecognized(&it, context, "Function Argument");
        }
        END_HYPOTHETICAL_PARSE_BLOCK("Test for type expression for argument");

        bool has_name = false;
        if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
            has_name = true;
            char *argument_name = it[0].text;
            eat_token(&it, context, "Function: Arguments: Name");
            EMIT_TEXT("%s: ", argument_name);
        } else {
            EMIT_TEXT("/* Un-Named : */ ");
        }

        it = argument_start;

        if (found_type_exp)
            parse_type_expression(&it, context);

        if (has_name)
            eat_token(&it, context, "Function: Arguemnts: Skip over Name");


        if (it[0].type == TOKEN_TYPE_OPEN_SQUARE_BRACE && it[1].type == TOKEN_TYPE_CLOSE_SQUARE_BRACE) {
            eat_token(&it, context, "Function: Arguemnts: Start Array Type Indicator");
            eat_token(&it, context, "Function: Arguemnts: End Array Type Indicator");
            EMIT_TEXT("[..]");
        }

        if (it[0].type == TOKEN_TYPE_COMMA) {
            eat_token(&it, context, "Function: Arguemnts: Separator");
            EMIT_TEXT(", ");
        }

    }
    END_PARSE_BLOCK("Function Arguments");

    eat_token(&it, context, "Function: Arguments: End");

    token *end_of_arguments = it;

    /* Parse Return Type */
    it = function_start;
    if (it[0].type == TOKEN_TYPE_KEYWORD_VOID && it[1].type != TOKEN_TYPE_STAR) {
        EMIT_TEXT(")");
    } else {
        EMIT_TEXT(") -> ");
        parse_type_expression(&it, context);
    }

    if (is_extern)
        EMIT_TEXT(" #foreign");

    it = end_of_arguments;

    if (it[0].type == TOKEN_TYPE_SEMICOLON) {
        eat_token(&it, context, "Function Prototype");
        EMIT_TEXT(";");

    } else {
        EMIT_TEXT(" "); /* Space between return type and function body opening brace. */

        /* Parse Function Body */
        if (!parse_scope(&it, context)) {
            eat_token_unrecognized(&it, context, "Function Body");
        }
    }

    END_PARSE_BLOCK("Function Declaration");
    *token_at = it;
    return true;
}

bool parse_enum_def(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (it[0].type != TOKEN_TYPE_KEYWORD_ENUM || it[1].type != TOKEN_TYPE_OPEN_CURLY_BRACE) {
        return false;
    }
    BEGIN_PARSE_BLOCK("Enum Definition");

    eat_token(&it, context, "Enum Definition");

    if (it[0].type == TOKEN_TYPE_OPEN_CURLY_BRACE ) {
        eat_token(&it, context, "Enum Definition: Start of Scope");
    }

    token *enum_contents_start = it;

    BEGIN_HYPOTHETICAL_PARSE_BLOCK("Skipping over contents temporarily");
    while (it->type != TOKEN_TYPE_CLOSE_CURLY_BRACE) {
        eat_token(&it, context, "Enum Definition: Skip over contents");
    }
    eat_token(&it, context, "Enum Definition: End of Scope");
    END_HYPOTHETICAL_PARSE_BLOCK("Skipping over contents temporarily");

    char *enum_name;
    if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
        enum_name = it->text;
        eat_token(&it, context, "Enum Definition: Name");
    } else {
        enum_name = "/* Un-Named */";
    }

    EMIT_TEXT_INDENT("%s :: enum {", enum_name);
    context->indent_depth++;

    it = enum_contents_start;

    BEGIN_PARSE_BLOCK("Enum Contents");
    while (it[0].type != TOKEN_TYPE_CLOSE_CURLY_BRACE) {

        if (parse_line_comment(&it, context))
            continue;

        if (parse_block_comment(&it, context))
            continue;

        EMIT_TEXT("\n");

        if (parse_blank_line(&it, context))
            continue;

        if (parse_general_preprocessor(&it, context))
            continue;

        if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
            char *name_text = it->text;
            eat_token(&it, context, "Enum Definition: Contents: Identifier");
            EMIT_TEXT_INDENT("%s", name_text);
        } else {
            eat_token_unrecognized(&it, context, "Enum: Contents");
            continue;
        }

        if (it[0].type == TOKEN_TYPE_NUMBER) {
            char *number_text = it->text;
            eat_token(&it, context, "Enum Definition: Contents: Value");
            EMIT_TEXT(" %s", number_text);
        }
        if (it[0].type == TOKEN_TYPE_COMMA) {
            eat_token(&it, context, "Enum Definition: Contents: Separator");
            EMIT_TEXT(",");
        }
    }
    END_PARSE_BLOCK("Enum Contents");

    if (it[0].type == TOKEN_TYPE_CLOSE_CURLY_BRACE) {
        eat_token(&it, context, "Enum Definition: End of Scope");
    }

    if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
        eat_token(&it, context, "Enum Definition: Name");
    }

    if (it[0].type == TOKEN_TYPE_SEMICOLON) {
        eat_token(&it, context, "Enum Definition: End of Definition");
    }

    context->indent_depth--;

    EMIT_TEXT("\n");
    EMIT_TEXT_INDENT("};");

    END_PARSE_BLOCK("Enum Definition");
    *token_at = it;
    return true;
}

bool parse_struct_def(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (it[0].type != TOKEN_TYPE_KEYWORD_STRUCT || it[1].type != TOKEN_TYPE_OPEN_CURLY_BRACE) {
        return false;
    }
    BEGIN_PARSE_BLOCK("Struct Definition");

    eat_token(&it, context, "Struct Definition");

    if (it[0].type == TOKEN_TYPE_OPEN_CURLY_BRACE ) {
        eat_token(&it, context, "Struct Definition: Start of Scope");
    }

    token *struct_contents_start = it;

    BEGIN_HYPOTHETICAL_PARSE_BLOCK("Skipping over contents temporarily");
    while (it[0].type != TOKEN_TYPE_CLOSE_CURLY_BRACE) {
        eat_token(&it, context, "Struct Definition: Skip over contents");
    }
    eat_token(&it, context, "Struct Definition: End of Scope");
    END_HYPOTHETICAL_PARSE_BLOCK("Skipping over contents temporarily");

    BEGIN_PARSE_BLOCK("Struct Contents");
    char *struct_name;
    if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
        struct_name = it->text;
        eat_token(&it, context, "Struct Definition: Name");
    } else {
        struct_name = "/* Un-Named */";
    }

    EMIT_TEXT_INDENT("%s :: struct {", struct_name);
    context->indent_depth++;

    it = struct_contents_start;
    while (it[0].type != TOKEN_TYPE_CLOSE_CURLY_BRACE) {

        if (parse_line_comment(&it, context))
            continue;

        if (parse_block_comment(&it, context))
            continue;

        EMIT_TEXT("\n");

        if (parse_blank_line(&it, context))
            continue;

        if (parse_general_preprocessor(&it, context))
            continue;

        EMIT_TEXT_INDENT("");

        if (parse_variable_declaration(&it, context))
            continue;

        eat_token_unrecognized(&it, context, "Struct : Contents");
    }
    END_PARSE_BLOCK("Struct Contents");

    if (it[0].type == TOKEN_TYPE_CLOSE_CURLY_BRACE) {
        eat_token(&it, context, "Struct Definition: End of Contents");
    }

    if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
        eat_token(&it, context, "Struct Definition: Name");
    }

    if (it[0].type == TOKEN_TYPE_SEMICOLON) {
        eat_token(&it, context, "Struct Definition: End of Declaration");
    }

    context->indent_depth--;

    EMIT_TEXT("\n");
    EMIT_TEXT_INDENT("};");

    END_PARSE_BLOCK("Struct Definition");
    *token_at = it;
    return true;
}



bool parse_typedef(token **token_at, parse_context *context) {
    token *it = *token_at;

    if (it[0].type != TOKEN_TYPE_KEYWORD_TYPEDEF) {
        return false;
    }
    BEGIN_PARSE_BLOCK("Typedef");

    eat_token(&it, context, "Typedef");

    if (parse_enum_def(&it, context)) {
    } else if (parse_struct_def(&it, context)) {
    } else {
        token *base_type_start = it;

        BEGIN_HYPOTHETICAL_PARSE_BLOCK("Skipping over type expression temporarily");
        parse_type_expression(&it, context);
        END_HYPOTHETICAL_PARSE_BLOCK("Skipping over type expression temporarily");

        if (it[0].type == TOKEN_TYPE_IDENTIFIER && it[1].type == TOKEN_TYPE_SEMICOLON) {
            token *type_name_token = &it[0];

            eat_token(&it, context, "Typedef: Generic: Name");
            EMIT_TEXT("%s :: ", type_name_token->text);

            it = base_type_start;
            parse_type_expression(&it, context);
            eat_token(&it, context, "Typedef: Generic: Skip over Name");
            eat_token(&it, context, "Typedef: Generic: End of Declaration");

            EMIT_TEXT(";");
        }
    }

    END_PARSE_BLOCK("Typedef");
    *token_at = it;
    return true;
}


int main (int argc, char *argv[]) {

    /* Resolve Arguments */
    char *input_file_path;
    if (argc < 2) {
        printf("Must pass a file to translate.\n");
        printf("   e.g. jtrans file.c\n");
        exit(EXIT_FAILURE);
    } else if (argc > 2) {
        printf("Only single file processing is currently supported.\n");
        printf("Please process one file at a time.\n");
        printf("   e.g. jtrans file.c\n");
        exit(EXIT_FAILURE);
    } else {
        input_file_path = argv[1];
        printf("File to process: %s\n", input_file_path);
    }


    /* Create Output Files */
    FILE *input_file = fopen(input_file_path, "r");
    if (!input_file) {
        printf("Unable to open input file for reading: %s", input_file_path);
        exit(EXIT_FAILURE);
    }

    int base_path_len = strchr(input_file_path, '.') - input_file_path + 1;

    char *output_file_path = malloc(base_path_len + 4);
    strncpy(output_file_path, input_file_path, base_path_len);
    output_file_path[base_path_len] = 0;
    strcat(output_file_path, "jai");

    printf("Output file: %s\n", output_file_path);

    FILE *output_file = NULL;
    output_file = fopen(output_file_path, "w");
    if (!output_file) {
        printf("Unable to open output file for writing: %s", output_file_path);
        exit(EXIT_FAILURE);
    }

#if GENERATE_TOKEN_FILE
    char *token_file_path = malloc(base_path_len + 7);
    strncpy(token_file_path, input_file_path, base_path_len);
    token_file_path[base_path_len] = 0;
    strcat(token_file_path, "tokens");
    printf("Tokens file: %s\n", token_file_path);

    FILE *token_file = NULL;
    token_file = fopen(token_file_path, "w");
    if (!token_file) {
        printf("Unable to open token file for writing: %s", token_file_path);
        exit(EXIT_FAILURE);
    }
    fprintf(token_file, "/* Token file generated for: %s */\n", input_file_path);
    free(token_file_path);
#endif

#if GENERATE_STRUCTURE_FILE
    char *structure_file_path = malloc(base_path_len + 10);
    strncpy(structure_file_path, input_file_path, base_path_len);
    structure_file_path[base_path_len] = 0;
    strcat(structure_file_path, "structure");
    printf("Structure file: %s\n", structure_file_path);

    FILE *structure_file = NULL;
    structure_file = fopen(structure_file_path, "w");
    if (!structure_file) {
        printf("Unable to open structure file for writing: %s", structure_file_path);
        exit(EXIT_FAILURE);
    }
    fprintf(structure_file, "/* Structure file generated for: %s */\n", input_file_path);
    free(structure_file_path);
#endif

    /* Load input file into memory. */
    char *input_buffer;
    fseek(input_file, 0L, SEEK_END);
    int input_file_size = ftell(input_file);
    fseek(input_file, 0L, SEEK_SET);
    input_buffer = (char *)malloc(input_file_size + 1);
    fread(input_buffer, input_file_size, 1, input_file);
    input_buffer[input_file_size] = 0;
    fclose(input_file);


    /* Lookup Table Setup */
    int token_lookup_count = TOKEN_TYPE_COUNT-8; /* Total - number of container tokens (not in lookup table) */
    char *token_lookup[token_lookup_count];
    init_token_lookup_table(token_lookup);

    /* Tokenize Input File */
    bool reparse;

    int token_buffer_size = DEFAULT_TOKEN_BUFFER_SIZE;
    token *token_buffer;
    token *token_at;

    token_context token_context_space;
    token_context *token_context = &token_context_space;

    do {
        reparse = false;
        token_buffer = malloc(token_buffer_size*sizeof(token));
        token_at = token_buffer;

        char *at = input_buffer;

#if GENERATE_TOKEN_FILE
        token_context->token_file = token_file;;
#endif
        token_context->last_token_id = 0;
        token_context->token_buffer_size = token_buffer_size;
        token_context->empty_line = true;
        token_context->line_number = 1;
        token_context->line_start_at = at;

        while (at[0]) {

            /* Handle newlines and whitespace */
            if (at[0] == ASCII_TAB || at[0] == ASCII_SPACE) {
                eat_character(&at);
                continue;
            } else if (at[0] == ASCII_RETURN) {
                /* Windows and Classic Mac newlines */
                if (at[1] == ASCII_LINE_FEED) {
                    eat_character(&at);
                }
                if (token_context->empty_line) {
                    add_token(TOKEN_TYPE_BLANK_LINE, token_at, "\\n", 2, at, token_context);
                    token_at++;
                }
                eat_character(&at);
                token_context->line_number++;
                token_context->line_start_at = at;
                token_context->empty_line = true;
                continue;
            } else if (at[0] == ASCII_LINE_FEED) {
                /* Unix newlines */
                if (token_context->empty_line) {
                    add_token(TOKEN_TYPE_BLANK_LINE, token_at, "\\n", 2, at, token_context);
                    token_at++;
                }
                eat_character(&at);
                token_context->line_number++;
                token_context->line_start_at = at;
                token_context->empty_line = true;
                continue;
            }
            token_context->empty_line = false;

            /* Detect Line-wise Comments */
            if (at[0] == '/' && at[1] == '/') {
                at += 2;
                char *comment_start = at;
                while (at[0] != ASCII_RETURN && at[0] != ASCII_LINE_FEED  && at[0] != ASCII_NULL ) {
                    eat_character(&at);
                }
                int comment_string_length = at-comment_start;
                add_token(TOKEN_TYPE_LINE_COMMENT, token_at, comment_start, comment_string_length, comment_start, token_context);
                token_at++;
                eat_character(&at);
                token_context->line_number++;
                token_context->line_start_at = at;
                token_context->empty_line = true;
                continue;
            }

            /* Detect Block Comments */
            if (at[0] == '/' && at[1] == '*') {
                at += 2;
                char *comment_start = at;
                while (!(at[0] == '*' && at[1] == '/') && at[0] != ASCII_NULL) {
                    /* Count Lines in Block Comments */
                    if (at[0] == ASCII_RETURN) {
                        /* Windows and Classic Mac newlines */
                        if (at[1] == ASCII_LINE_FEED) {
                            eat_character(&at);
                        }
                        token_context->line_number++;
                    } else if (at[0] == ASCII_LINE_FEED) {
                        /* Unix newlines */
                        token_context->line_number++;
                    }
                    eat_character(&at);
                    token_context->line_start_at = at;
                }
                int comment_string_length = at-comment_start;
                add_token(TOKEN_TYPE_BLOCK_COMMENT, token_at, comment_start, comment_string_length, comment_start, token_context);
                token_at++;
                eat_character(&at);
                eat_character(&at);
                continue;
            }

            /* Detect string literals */
            if (at[0]=='"') {
                eat_character(&at);
                char *string_start = at;
                int contiguous_slash_count = 0;
                while (!(at[0] == '"' && !(contiguous_slash_count%2)) && at[0] != ASCII_NULL) {
                    if (at[0]=='\\') {
                        contiguous_slash_count++;
                    } else {
                        contiguous_slash_count = 0;
                    }
                    /* Count Lines in String Literals */
                    if (at[0] == ASCII_RETURN) {
                        /* Windows and Classic Mac newlines */
                        if (at[1] == ASCII_LINE_FEED) {
                            eat_character(&at);
                        }
                        token_context->line_number++;
                    } else if (at[0] == ASCII_LINE_FEED) {
                        /* Unix newlines */
                        token_context->line_number++;
                    }
                    eat_character(&at);
                }
                int string_length = at-string_start;
                add_token(TOKEN_TYPE_STRING_LITERAL, token_at, string_start, string_length, string_start, token_context);
                token_at++;
                eat_character(&at);
                continue;
            }

            /* Detect character literals */
            if (at[0]=='\'') {
                eat_character(&at);
                char *char_start = at;
                int contiguous_slash_count = 0;
                while (!(at[0] == '\'' && !(contiguous_slash_count%2)) && at[0] != ASCII_NULL) {
                    if (at[0]=='\\') {
                        contiguous_slash_count++;
                    } else {
                        contiguous_slash_count = 0;
                    }
                    eat_character(&at);
                }
                int char_length = at-char_start;
                add_token(TOKEN_TYPE_CHARACTER_LITERAL, token_at, char_start, char_length, char_start, token_context);
                token_at++;
                eat_character(&at);
                continue;
            }

            /* Check for lookup table tokens */
            bool found = false;
            for (int token_type_index=0; token_type_index<token_lookup_count; token_type_index++) {
                char *token_string = token_lookup[token_type_index];
                int token_string_length = strlen(token_string);
                if (strncmp(at, token_string, token_string_length)==0) {
                    if (is_keyword_token_type(token_type_index) &&
                            is_identifier_char(at[token_string_length])) {
                        /* allow keywords as substring of identifier */
                        continue;
                    }
                    add_token(token_type_index, token_at, token_string, token_string_length, at, token_context);
                    token_at++;
                    at += token_string_length;
                    found = true;
                    break;
                }

            }
            if (found) {
                continue;
            }

            /* Check for number */
            char *number_start = at;
            while (is_numeric_char(at[0])) {
                eat_character(&at);
            }
            if (at > number_start) {
                int number_string_length = at - number_start;
                add_token(TOKEN_TYPE_NUMBER, token_at, number_start, number_string_length, number_start, token_context);
                token_at++;
                continue;
            }

            /* Check for identifier */
            char *identifier_start = at;
            while (is_identifier_char(at[0])) {
                eat_character(&at);
            }
            if (at > identifier_start) {
                int identifier_string_length = at - identifier_start;
                add_token(TOKEN_TYPE_IDENTIFIER, token_at, identifier_start, identifier_string_length, identifier_start, token_context);
                token_at++;
                continue;
            }

            /* register unrecognized token */
            printf("Unrecognized character: \'%c\' (%i), Context: \"%.21s\"\n", at[0], (int)at[0], &at[-10]);
            eat_character(&at);
        }
        add_token(TOKEN_TYPE_END_OF_FILE, token_at, "EOF", 3, at, token_context);
        if (token_context->last_token_id > token_context->token_buffer_size) {
            printf("File is larger than the default token buffer (%i).\n", token_context->token_buffer_size);
            printf("Resizing token buffer from %i to %i and reparsing.\n", token_context->token_buffer_size, token_context->last_token_id);
            cleanup_token_buffer(token_buffer, &token_buffer[token_context->token_buffer_size-1]);
            token_buffer_size = token_context->last_token_id;
            reparse = true;
        }
    } while (reparse);

#if GENERATE_TOKEN_FILE
    fclose(token_file);
#endif

    /* Generate Output File */

    token *last_token = token_at;
    token_at = &token_buffer[0];

    parse_context context_space;
    parse_context *context = &context_space;
    context->output_file = output_file;
#if GENERATE_STRUCTURE_FILE
    context->structure_file = structure_file;
#endif
    context->parse_mode = PARSE_MODE_OUTPUT;
    context->parse_depth = 0;
    context->indent_depth = 0;
    context->extra_indent = false;
    context->line_number = 0;
    context->parse_type_as_argument = false;
    context->first_unrecognized_token = NULL;
    context->last_unrecognized_line_emitted = 0;
    context->last_input_file_char_emitted = &input_buffer[-1];
    context->unrecognized_count = 0;
    context->unsupported_count = 0;


    /* Start: Parse Global Scope */

    while (token_at<last_token) {
        context->parse_depth = 0;

        if (parse_line_comment(&token_at, context))
            continue;

        if (parse_block_comment(&token_at, context))
            continue;

        EMIT_TEXT("\n");

        if (parse_blank_line(&token_at, context))
            continue;

        /* Parse Include Statement (Libraries and Files) */
        if (parse_include(&token_at, context))
            continue;

        /* Parse Preprocessor Defines */
        if (parse_define(&token_at, context))
            continue;

        if (parse_general_preprocessor(&token_at, context))
            continue;

        /* Type Definitions */
        if (parse_enum_def(&token_at, context))
            continue;

        if (parse_struct_def(&token_at, context))
            continue;

        if (parse_typedef(&token_at, context))
            continue;

        /* Parse Function Definitions */
        if (parse_function_definition(&token_at, context))
            continue;

        /* Variable Definitions */
        if (parse_variable_declaration(&token_at, context))
            continue;

        /* Unrecognized Structures */
        eat_token_unrecognized(&token_at, context, "Global Scope");
    }

    /* Close up any remaning unrecognized blocks. */
    eat_token(&token_at, context, "End of File");

    int line_count = token_at[-1].line_number;

    /* Cleanup Token Buffer */
    cleanup_token_buffer(token_buffer, last_token);

#if GENERATE_STRUCTURE_FILE
    fclose(structure_file);
#endif
    fclose(output_file);

    free(input_buffer);
    free(token_buffer);
    free(output_file_path);

    printf("Processing Complete.\n");
    printf("  %i lines and %i tokens parsed.\n", line_count, token_context->last_token_id);
    printf("  %i unrecognized syntax structure(s) found.\n", context->unrecognized_count);
    printf("  %i unsupported syntax structure(s) found.\n", context->unsupported_count);

    exit(EXIT_SUCCESS);
}
