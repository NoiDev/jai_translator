
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

#define PARSE_MODE_OUTPUT    1
#define PARSE_MODE_NO_OUTPUT 0

typedef struct {
    FILE *output_file;
#if GENERATE_STRUCTURE_FILE
    FILE *structure_file;
#endif
    bool parse_mode;
    int parse_depth;
    int indent_depth;
    int line_number;
    token *first_unrecognized_token;
    int last_unrecognized_line_emitted;
    char *last_input_file_char_emitted;
    int unrecognized_count;
    int unsupported_count;

    /* @HACK */
    bool parse_type_as_argument;
} parse_context;

/* Forward Declarations */
bool parse_scope();
bool parse_variable_declaration();
bool parse_evaluable_expression();

void eat_token(token **token_at) {
    token *it = *token_at;
    it++;
    *token_at = it;
}

void eat_tokens(token **token_at, int count) {
    token *it = *token_at;
    it+=count;
    *token_at = it;
}

typedef enum {
    variable_type_void, /* void */
    variable_type_integer,
    variable_type_floating_point,
    variable_type_struct,
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
    if (it.type == TOKEN_TYPE_STAR            ||
            it.type == TOKEN_TYPE_BITWISE_AND ||  /* (Address) */
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

void flag_recognized_structure(token **token_at, parse_context *context, char *structure_identifier) {
    token *it = *token_at;

#if GENERATE_STRUCTURE_FILE
    if (context->parse_mode == PARSE_MODE_OUTPUT)
        fprintf(context->structure_file, "%s (%s) Token: %i, Line: %i, Char: %i \n", structure_identifier, it->text, it->id, it->line_number, it->char_number);
    else
        fprintf(context->structure_file, "HYPOTHETICAL - %s (%s) Token: %i, Line: %i, Char: %i \n", structure_identifier, it->text, it->id, it->line_number, it->char_number);
#else
    if (context->parse_mode == PARSE_MODE_NO_OUTPUT)
        return;
#endif

    if (context->first_unrecognized_token) {
        EMIT_TEXT("\n");
        EMIT_TEXT_INDENT("/*END: Unrecognized Token Structure */\n");
        EMIT_TEXT("\n");
        context->first_unrecognized_token = NULL;
    }
}

void flag_unrecognized_structure(token **token_at, parse_context *context, char *expected_structure) {
    if (context->parse_mode == PARSE_MODE_NO_OUTPUT)
        return;

    token *it = *token_at;

#if GENERATE_STRUCTURE_FILE
    fprintf(context->structure_file, "***UNREC %i (%s) Exp:%s Line: %i, Char: %i \n", it->type, it->text, expected_structure, it->line_number, it->char_number);
#endif

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
    context->parse_depth++;
    if (it[0].type == TOKEN_TYPE_BLANK_LINE) {
        flag_recognized_structure(&it, context, "Blank Line");
        EMIT_TEXT("\n");
        it++;
        *token_at = it;
        context->parse_depth--;
        return true;
    }
    context->parse_depth--;
    return false;
}

bool parse_line_comment(token **token_at, parse_context *context) {
    token *it = *token_at;
    context->parse_depth++;
    if (it[0].type == TOKEN_TYPE_LINE_COMMENT) {
        flag_recognized_structure(&it, context, "Line Comment");
        if (it[-1].line_number == it[0].line_number) {
            EMIT_TEXT("  //%s", it->text);
        } else {
            EMIT_TEXT("\n");
            EMIT_TEXT_INDENT("//%s", it->text);
        }
        it++;
        *token_at = it;
        context->parse_depth--;
        return true;
    }
    context->parse_depth--;
    return false;
}

bool parse_block_comment(token **token_at, parse_context *context) {
    token *it = *token_at;
    context->parse_depth++;
    if (it[0].type == TOKEN_TYPE_BLOCK_COMMENT) {
        flag_recognized_structure(&it, context, "Block Comment");
        if (it[-1].line_number == it[0].line_number) {
            if (it[0].line_number == it[1].line_number) {
                EMIT_TEXT("/*%s*/", it->text);
            } else {
                EMIT_TEXT("  /*%s*/", it->text);
            }
        } else {
            EMIT_TEXT("\n");
            EMIT_TEXT_INDENT("/*%s*/", it->text);
        }
        it++;
        *token_at = it;
        context->parse_depth--;
        return true;
    }
    context->parse_depth--;
    return false;
}

bool parse_include(token **token_at, parse_context *context) {
    token *it = *token_at;
    context->parse_depth++;
    if (it[0].type == TOKEN_TYPE_PRE_INCLUDE) {
        if (it[1].type == TOKEN_TYPE_OPEN_ANGLE_BRACE
                && it[2].type == TOKEN_TYPE_IDENTIFIER) {
            flag_recognized_structure(&it, context, "Include Library");
            char *library_name = it[2].text;
            EMIT_TEXT("#import \"%s\";\n", library_name);
            eat_tokens(&it, 3);
            while (it[0].type != TOKEN_TYPE_CLOSE_ANGLE_BRACE) {
                eat_token(&it);
            }
            eat_token(&it); /* ">" */

            *token_at = it;
            context->parse_depth--;
            return true;
        } else if (it[1].type == TOKEN_TYPE_STRING_LITERAL) {
            flag_recognized_structure(&it, context, "Include File");
            char *file_name = it[1].text;
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
            EMIT_TEXT("#load \"%s\";\n", converted_file_name);
            free(converted_file_name);
            eat_tokens(&it, 2);

            *token_at = it;
            context->parse_depth--;
            return true;
        }
    }
    context->parse_depth--;
    return false;
}

bool parse_define(token **token_at, parse_context *context) {
    token *it = *token_at;
    context->parse_depth++;
    if (it[0].type == TOKEN_TYPE_PRE_DEFINE &&
            it[1].type == TOKEN_TYPE_IDENTIFIER &&
            (it[2].type == TOKEN_TYPE_IDENTIFIER ||
             it[2].type == TOKEN_TYPE_NUMBER     ||
             it[2].type == TOKEN_TYPE_CHARACTER_LITERAL ||
             it[2].type == TOKEN_TYPE_STRING_LITERAL)) {
        flag_recognized_structure(&it, context, "Define");
        EMIT_TEXT("%s :: %s\n", it[1].text, it[2].text);
        eat_tokens(&it, 3);
        *token_at = it;
        context->parse_depth--;
        return true;
    }
    context->parse_depth--;
    return false;
}

bool parse_general_preprocessor(token **token_at, parse_context *context) {
    token *it = *token_at;
    context->parse_depth++;
    if (!is_preprocessor_token(it[0])) {
        context->parse_depth--;
        return false;
    }

    context->unsupported_count++;
    issue_warning(warning_type_ternary);

    int line_number_of_directive = it[0].line_number;

    char *line_start = it[0].line_start;
    char *line_end = strchr(line_start, '\n');
    if (!line_end)
        line_end = strchr(line_start, '\r');
    assert(line_end);

    EMIT_TEXT("\n%.*s", (int)(line_end-line_start), line_start);
    eat_token(&it);

    while (it[0].line_number == line_number_of_directive) {
        eat_token(&it);
    }

    *token_at = it;
    context->parse_depth--;
    return true;
}

bool parse_type_expression(token **token_at, parse_context *context) {
    token *it = *token_at;
    context->parse_depth++;
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
            flag_recognized_structure(&it, context, "Type Expression");
            desc.var_type = variable_type_void;
            eat_token(&it);

        /* Floating-Point Types */
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_FLOAT) {
            flag_recognized_structure(&it, context, "Type Expression");
            desc.var_type = variable_type_floating_point;
            desc.size = 32;
            eat_token(&it);
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_DOUBLE) {
            flag_recognized_structure(&it, context, "Type Expression");
            desc.var_type = variable_type_floating_point;
            desc.size = 64;
            eat_token(&it);
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_LONG &&
                it[1].type == TOKEN_TYPE_KEYWORD_DOUBLE) {
            flag_recognized_structure(&it, context, "Type Expression");
            desc.var_type = variable_type_floating_point;
            desc.size = 80;
            eat_tokens(&it, 2);

        /* Integer Types */
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_CHAR) {
            flag_recognized_structure(&it, context, "Type Expression");
            desc.var_type = variable_type_integer;
            desc.size = 8;
            eat_token(&it);
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_SHORT) {
            flag_recognized_structure(&it, context, "Type Expression");
            desc.var_type = variable_type_integer;
            desc.size = 16;
            eat_token(&it);
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_INT) {
            flag_recognized_structure(&it, context, "Type Expression");
            desc.var_type = variable_type_integer;
            desc.size = 16;
            eat_token(&it);
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_LONG) {
            flag_recognized_structure(&it, context, "Type Expression");
            desc.var_type = variable_type_integer;
            desc.size = 32;
            eat_token(&it);

        /* Sign Types */
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_SIGNED) {
            flag_recognized_structure(&it, context, "Type Expression");
            desc.sign = sign_type_signed;
            eat_token(&it);
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_UNSIGNED) {
            flag_recognized_structure(&it, context, "Type Expression");
            desc.sign = sign_type_unsigned;
            eat_token(&it);

        /* Struct */
        } else if (it[0].type == TOKEN_TYPE_KEYWORD_STRUCT) {
            flag_recognized_structure(&it, context, "Type Expression");
            desc.var_type = variable_type_struct;
            if (it[1].type == TOKEN_TYPE_IDENTIFIER) {
            flag_recognized_structure(&it, context, "Type Expression");
                desc.text = it[1].text;
                eat_token(&it);
            }
            eat_token(&it);

        /* Typedef */
        } else if (it[0].type == TOKEN_TYPE_IDENTIFIER &&
                (it[1].type == TOKEN_TYPE_IDENTIFIER ||
                 it[1].type == TOKEN_TYPE_STAR ||
                    (context->parse_type_as_argument &&
                     it[1].type == TOKEN_TYPE_CLOSE_PAREN))) {
            /* Extra check to differentiate custom types from variable names. */
            flag_recognized_structure(&it, context, "Type Expression");
            desc.var_type = variable_type_typedef;
            desc.text = it[0].text;
            eat_token(&it);

        /* Pointers */
        } else if (it[0].type == TOKEN_TYPE_STAR) {
            flag_recognized_structure(&it, context, "Type Expression");
            desc.indirection_count++;
            eat_token(&it);

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

    /* No tokens eaten, not a type expression */
    if (it == type_expr_start) {
        context->parse_depth--;
        return false;
    }

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
            if (desc.size==8) {  /* char => u8 */
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
    } else if (desc.var_type == variable_type_struct) {
        EMIT_TEXT("struct %s", desc.text);
    } else if (desc.var_type == variable_type_typedef) {
        EMIT_TEXT("%s", desc.text);
    } else {
        printf("Unrecognized Variable Type: %i\n", desc.var_type);
        assert(false);
    }

    *token_at = it;
    context->parse_depth--;
    return true;
}

bool parse_array_subscript(token **token_at, parse_context *context) {
    token *it = *token_at;
    context->parse_depth++;
    if (it[0].type==TOKEN_TYPE_OPEN_SQUARE_BRACE) {
        while (it[0].type==TOKEN_TYPE_OPEN_SQUARE_BRACE) {
            eat_token(&it); /* "[" */
            EMIT_TEXT("[");
            if (!parse_evaluable_expression(&it, context)) {
                flag_unrecognized_structure(&it, context, "Array Subscript Expression");
            }
            if (it[0].type == TOKEN_TYPE_CLOSE_SQUARE_BRACE) {
                eat_token(&it); /* "]" */
                flag_recognized_structure(&it, context, "Array Subscript: End");
                EMIT_TEXT("]");
            } else {
                flag_unrecognized_structure(&it, context, "Array Subscript: End");
            }
        }
        *token_at = it;
        context->parse_depth--;
        return true;
    }
    return false;
}

bool parse_subscripts_and_dereferences(token **token_at, parse_context *context) {
    token *it = *token_at;
    context->parse_depth++;
    bool found = false;
    bool parsing = true;
    while (parsing) {
        parsing = false;

        /* subscripts */
        if (parse_array_subscript(&it, context)) {
            found = true;
            parsing = true;
        }

        /* Struct Dereference */
        if (it[0].type == TOKEN_TYPE_DOT && it[1].type == TOKEN_TYPE_IDENTIFIER) {
            found = true;
            parsing = true;
            EMIT_TEXT(".%s", it[1].text);
            eat_tokens(&it, 2);  /* '.', <name> */

            /* Pointer Dereference */
        } else if (it[0].type == TOKEN_TYPE_ARROW && it[1].type == TOKEN_TYPE_IDENTIFIER) {
            found = true;
            parsing = true;
            EMIT_TEXT(".%s", it[1].text);
            eat_tokens(&it, 2);  /* '->', <name> */
        }
    }
    context->parse_depth--;
    *token_at = it;
    return found;
}

bool parse_evaluable_expression(token **token_at, parse_context *context) {
    token *it = *token_at;
    context->parse_depth++;
    bool test_for_following_expression = false;

    if (parse_block_comment(&it, context))
        test_for_following_expression = true;

    /* Parenthetical */
    if (it[0].type==TOKEN_TYPE_OPEN_PAREN) {
        test_for_following_expression = true;
        flag_recognized_structure(&it, context, "Parentheical");
        eat_token(&it);
        token *parenthetical_start = it;
        bool found = false;
        context->parse_mode = PARSE_MODE_NO_OUTPUT;
        context->parse_type_as_argument = true;
        if (parse_type_expression(&it, context)) {
            if (it[0].type == TOKEN_TYPE_CLOSE_PAREN) {
                eat_token(&it);
                context->parse_type_as_argument = false;
                if (parse_evaluable_expression(&it, context)) { /* Check for object of cast */
                    found = true;

                    context->parse_mode = PARSE_MODE_OUTPUT;

                    it = parenthetical_start;
                    flag_recognized_structure(&it, context, "Caste");
                    EMIT_TEXT("cast(");
                    context->parse_type_as_argument = true;
                    parse_type_expression(&it, context);
                    eat_token(&it); /* ")" */
                    EMIT_TEXT(") ");
                }
            }
        }
        context->parse_type_as_argument = false;
        context->parse_mode = PARSE_MODE_OUTPUT;
        if (!found) {
            EMIT_TEXT("(");
            it = parenthetical_start;
            bool parsing = true;
            while (parsing && it[0].type != TOKEN_TYPE_CLOSE_PAREN) {

                if (!parse_evaluable_expression(&it, context))
                    parsing = false;
            }
            flag_recognized_structure(&it, context, "Parentheical: End");
            EMIT_TEXT(")");
            eat_token(&it);
        }
    }

    /* Operators */

    if (is_unary_prefix_operator_token(it[0]) && it[1].type==TOKEN_TYPE_IDENTIFIER) {
        test_for_following_expression = true;
        flag_recognized_structure(&it, context, "Evaluable: Unary Prefix Operator");
        EMIT_TEXT("%s", it[0].text);
        eat_token(&it); /* <operator> */

        parse_evaluable_expression(&it, context);
    }


    /* sizeof */
    if (it[0].type == TOKEN_TYPE_KEYWORD_SIZEOF && it[1].type == TOKEN_TYPE_OPEN_PAREN) {
        test_for_following_expression = true;
        flag_recognized_structure(&it, context, "Evaluable: sizeof");
        EMIT_TEXT("%s(", it[0].text);
        eat_tokens(&it, 2); /* "sizeof", "(" */
        context->parse_depth++;
        context->parse_type_as_argument = true;
        if (!parse_type_expression(&it, context)) {
            flag_unrecognized_structure(&it, context, "Evaluable: sizeof: Type Expression");
        }
        context->parse_type_as_argument = false;
        if (it[0].type != TOKEN_TYPE_CLOSE_PAREN) {
            flag_recognized_structure(&it, context, "Evaluable: sizeof: End");
            eat_token(&it); /* ")" */
        }
        context->parse_depth--;
        EMIT_TEXT(")");
        eat_token(&it); /* ")" */
    }



    /* Function Call */
    if (it[0].type == TOKEN_TYPE_IDENTIFIER && it[1].type == TOKEN_TYPE_OPEN_PAREN) {
        test_for_following_expression = true;
        flag_recognized_structure(&it, context, "Evaluable: Function");
        EMIT_TEXT("%s(", it[0].text);
        eat_tokens(&it, 2); /* <name>, "(" */
        context->parse_depth++;
        while (it[0].type != TOKEN_TYPE_CLOSE_PAREN) {
            if (!parse_evaluable_expression(&it, context)) {
                flag_unrecognized_structure(&it, context, "Function Call");
            }

            if (it[0].type == TOKEN_TYPE_COMMA) {
                flag_recognized_structure(&it, context, "Evaluable: Function: Argument");
                EMIT_TEXT(", ");
                eat_token(&it); /* "," */
            }
        }
        context->parse_depth--;
        flag_recognized_structure(&it, context, "Evaluable: Function: End of Arguments");
        EMIT_TEXT(")");
        eat_token(&it); /* ")" */
    }

    /* Values */
    if (it[0].type == TOKEN_TYPE_NUMBER) {
        test_for_following_expression = true;
        flag_recognized_structure(&it, context, "Evaluable: Number");
        EMIT_TEXT("%s", it[0].text);
        eat_token(&it);
    } else if (it[0].type == TOKEN_TYPE_MINUS && it[1].type == TOKEN_TYPE_NUMBER) {
        test_for_following_expression = true;
        flag_recognized_structure(&it, context, "Evaluable: Negative Number");
        EMIT_TEXT("-%s", it[1].text);
        eat_tokens(&it, 2);
    } else if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
        test_for_following_expression = true;
        flag_recognized_structure(&it, context, "Evaluable: Identifier");
        EMIT_TEXT("%s", it[0].text);
        eat_token(&it);
        parse_subscripts_and_dereferences(&it, context);
    } else if (it[0].type == TOKEN_TYPE_STRING_LITERAL) {
        test_for_following_expression = true;
        flag_recognized_structure(&it, context, "Evaluable: String Literal");
        EMIT_TEXT("\"%s\"", it[0].text);
        eat_token(&it);
    } else if (it[0].type == TOKEN_TYPE_CHARACTER_LITERAL) {
        test_for_following_expression = true;
        flag_recognized_structure(&it, context, "Evaluable: Character Literal");
        EMIT_TEXT("#char \"%s\"", it[0].text);
        eat_token(&it);
    }

    if (test_for_following_expression) {
        if (is_unary_postfix_operator_token(it[0])) {
            flag_recognized_structure(&it, context, "Evaluable: Unary Postfix Operator");
            EMIT_TEXT("%s", it[0].text);
            eat_token(&it); /* <operator> */
        }
        if (is_binary_operator_token(it[0])) {
            flag_recognized_structure(&it, context, "Evaluable: Binary Operator");
            EMIT_TEXT(" %s ", it[0].text);
            eat_token(&it); /* <operator> */
            parse_evaluable_expression(&it, context);
        }
        if (it[0].type == TOKEN_TYPE_TERNARY) {

            context->unsupported_count++;
            issue_warning(warning_type_ternary);

            flag_recognized_structure(&it, context, "Evaluable: Ternary Operator");
            EMIT_TEXT(" %s ", it[0].text);
            eat_token(&it); /* '?' */
            parse_evaluable_expression(&it, context);
            if (it[0].type == TOKEN_TYPE_COLON) {
                flag_recognized_structure(&it, context, "Evaluable: Ternary Operator");
                EMIT_TEXT(" %s ", it[0].text);
                eat_token(&it); /* ':' */
                parse_evaluable_expression(&it, context);

            }
        }
        *token_at = it;
        context->parse_depth--;
        return true;
    }
    context->parse_depth--;
    return false;
}

bool parse_statement(token **token_at, parse_context *context) {
    token *it = *token_at;
    context->parse_depth++;
    token *statement_start = it;

    /* Variable Declaration */
    if (parse_variable_declaration(&it, context)) {
        flag_recognized_structure(&it, context, "Statement: Variable Declaration");
        /* Note parse_vairable_declaration eats entire statement to ';'. */
        *token_at = it;
        context->parse_depth--;
        return true;
    }

    /* Assignment */
    bool parse_asignment = false;
    while (it[0].type != TOKEN_TYPE_SEMICOLON) {
        if (is_assignment_operator_token(it[1])) {
            parse_asignment = true;
            break;
        }
        eat_token(&it);
    }
    it = statement_start;
    if (parse_asignment) {
        flag_recognized_structure(&it, context, "Statement: Assignment");
        EMIT_TEXT("%s", it[0].text);
        eat_token(&it); /* <name> */
        parse_subscripts_and_dereferences(&it, context);
        EMIT_TEXT(" %s ", it[0].text);
        eat_token(&it); /* <operator> */
        if (parse_evaluable_expression(&it, context)) {
            flag_recognized_structure(&it, context, "Statement: Assignment: Evaluable");
        }

    /* Return */
    } else if (it[0].type == TOKEN_TYPE_KEYWORD_RETURN) {
        flag_recognized_structure(&it, context, "Statement: Return");
        EMIT_TEXT("return ");
        eat_token(&it); /* "return" */
        if (parse_evaluable_expression(&it, context)) {
            flag_recognized_structure(&it, context, "Statement: Return: Evaluable");
        }

    /* Single-Line Statements */
    } else if (it[0].type == TOKEN_TYPE_KEYWORD_CONTINUE || it[0].type == TOKEN_TYPE_KEYWORD_BREAK) {
        flag_recognized_structure(&it, context, "Statement: Break or Continue");
        EMIT_TEXT("%s", it[0].text);
        eat_token(&it); /* <keyword> */

    /* Generic Evaluable */
    } else if (parse_evaluable_expression(&it, context)) {
        flag_recognized_structure(&it, context, "Statement: Evaluable");
    }

    /* Emply Statement */
    if (it[0].type == TOKEN_TYPE_SEMICOLON) {
        flag_recognized_structure(&it, context, "Statement: Semi-Colon");
        EMIT_TEXT(";");
        eat_token(&it); /* ";" */
        *token_at = it;
        context->parse_depth--;
        return true;
    }

    context->parse_depth--;
    return false;
}

bool parse_if(token **token_at, parse_context *context) {
    token *it = *token_at;
    context->parse_depth++;
    token *statement_start = it;

    if (it[0].type == TOKEN_TYPE_KEYWORD_IF && it[1].type == TOKEN_TYPE_OPEN_PAREN) {
        flag_recognized_structure(&it, context, "If Statement");
        EMIT_TEXT("if (");
        eat_tokens(&it, 2); /* "if", "(" */

        context->parse_depth++;
        bool parsing = true;
        while (parsing && it[0].type != TOKEN_TYPE_CLOSE_PAREN) {
            if (!parse_evaluable_expression(&it, context)) {
                parsing = false;
                flag_unrecognized_structure(&it, context, "If Statement: Condition");
            }
        }
        context->parse_depth--;
        flag_recognized_structure(&it, context, "If Statement: End of Condition");
        EMIT_TEXT(") ");
        eat_token(&it); /* ")" */

        if (parse_scope(&it, context)) {
            EMIT_TEXT(" ");
        } else {
            context->indent_depth++;
            if (!parse_statement(&it, context))
                flag_unrecognized_structure(&it, context, "If Statement: Inline");
            context->indent_depth--;
        }

        if (it[0].type == TOKEN_TYPE_KEYWORD_ELSE) {
            flag_recognized_structure(&it, context, "Else Statement");
            EMIT_TEXT("else ");
            eat_token(&it);

            if (it[0].type == TOKEN_TYPE_KEYWORD_IF) {
                parse_if(&it, context);
            } else if (!parse_scope(&it, context)) {
                context->indent_depth++;
                if (!parse_statement(&it, context))
                    flag_unrecognized_structure(&it, context, "Else Statement: Inline");
                context->indent_depth--;
            }
        }
        *token_at = it;
        context->parse_depth--;
        return true;
    }
    context->parse_depth--;
    return false;
}

bool parse_for(token **token_at, parse_context *context) {
    token *it = *token_at;
    context->parse_depth++;
    token *statement_start = it;

    if (it[0].type == TOKEN_TYPE_KEYWORD_FOR && it[1].type == TOKEN_TYPE_OPEN_PAREN) {
        flag_recognized_structure(&it, context, "For Statement");
        EMIT_TEXT("for (");
        eat_tokens(&it, 2); /* "for", "(" */

        context->parse_depth++;
        if (!parse_statement(&it, context)) {
            flag_unrecognized_structure(&it, context, "For Statement: Initializer");
        }
        EMIT_TEXT(" ");

        if (!parse_statement(&it, context)) {
            flag_unrecognized_structure(&it, context, "For Statement: Conditional");
        }
        EMIT_TEXT(" ");

        if (!parse_evaluable_expression(&it, context)) {
            flag_unrecognized_structure(&it, context, "For Statement: Increment");
        }
        context->parse_depth--;

        if (it[0].type==TOKEN_TYPE_CLOSE_PAREN) {
            flag_recognized_structure(&it, context, "For Statement: End of Arguments");
            eat_token(&it); /* ")" */
            EMIT_TEXT(") ");
        } else {
            flag_unrecognized_structure(&it, context, "For Statement: End of Arguments");
        }

        if (parse_scope(&it, context)) {
            *token_at = it;
            context->parse_depth--;
            return true;
        } else {
            flag_unrecognized_structure(&it, context, "For Statement: Scope");
        }
    }
    context->parse_depth--;
    return false;
}

bool parse_while(token **token_at, parse_context *context) {
    token *it = *token_at;
    context->parse_depth++;
    token *statement_start = it;

    if (it[0].type == TOKEN_TYPE_KEYWORD_WHILE && it[1].type == TOKEN_TYPE_OPEN_PAREN) {
        flag_recognized_structure(&it, context, "While Statement");
        EMIT_TEXT("while (");
        eat_tokens(&it, 2); /* "while", "(" */

        context->parse_depth++;
        if (!parse_evaluable_expression(&it, context)) {
            flag_unrecognized_structure(&it, context, "While Statement: Conditional");
        }
        context->parse_depth--;

        if (it[0].type==TOKEN_TYPE_CLOSE_PAREN) {
            flag_recognized_structure(&it, context, "While Statement: End of Conditional");
            eat_token(&it); /* ")" */
            EMIT_TEXT(") ");
        } else {
            flag_unrecognized_structure(&it, context, "While Statement: End of Conditional");
        }

        if (parse_scope(&it, context)) {
            *token_at = it;
            context->parse_depth--;
            return true;
        } else {
            flag_unrecognized_structure(&it, context, "While Statement: Scope");
        }
    }
    context->parse_depth--;
    return false;
}

bool parse_do(token **token_at, parse_context *context) {
    token *it = *token_at;
    token *statement_start = it;

    if (it[0].type != TOKEN_TYPE_KEYWORD_DO) {
        return false;
    }

    flag_recognized_structure(&it, context, "Do-While Statement");
    EMIT_TEXT("do ");
    eat_token(&it); /* "do" */

    context->parse_depth++;
    if (!parse_scope(&it, context)) {
        flag_unrecognized_structure(&it, context, "Do-While Statement: Scope");
    }

    if (it[0].type == TOKEN_TYPE_KEYWORD_WHILE && it[1].type == TOKEN_TYPE_OPEN_PAREN) {
        EMIT_TEXT(" while (");
        eat_tokens(&it, 2); /* "while", "(" */

        if (!parse_evaluable_expression(&it, context)) {
            flag_unrecognized_structure(&it, context, "Do-While Statement: Conditional");
        }

        if (it[0].type==TOKEN_TYPE_CLOSE_PAREN) {
            flag_recognized_structure(&it, context, "While Statement: End of Conditional");
            eat_token(&it); /* ")" */
            EMIT_TEXT(");");
        } else {
            flag_unrecognized_structure(&it, context, "While Statement: End of Conditional");
        }
        if (it[0].type==TOKEN_TYPE_SEMICOLON) {
            eat_token(&it); /* ";" */
        }
    }
    context->parse_depth--;
    *token_at = it;
    return true;
}

bool parse_goto(token **token_at, parse_context *context) {
    token *it = *token_at;
    token *statement_start = it;

    if (it[0].type != TOKEN_TYPE_KEYWORD_GOTO) {
        return false;
    }

    context->unsupported_count++;
    issue_warning(warning_type_goto);


    flag_recognized_structure(&it, context, "Goto Statement");
    EMIT_TEXT("goto ");
    eat_token(&it);
    if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
        EMIT_TEXT("%s;", it[0].text);
        eat_token(&it);
    }
    if (it[0].type == TOKEN_TYPE_SEMICOLON)
        eat_token(&it); /* ";" */

    context->parse_depth--;
    *token_at = it;
    return true;
}

bool parse_goto_label(token **token_at, parse_context *context) {
    token *it = *token_at;
    token *statement_start = it;

    if (!(it[0].type == TOKEN_TYPE_IDENTIFIER && it[1].type == TOKEN_TYPE_COLON)) {
        return false;
    }

    context->unsupported_count++;
    issue_warning(warning_type_goto);

    flag_recognized_structure(&it, context, "Goto Label");
    EMIT_TEXT("%s:", it[0].text);
    eat_tokens(&it, 2);

    context->parse_depth--;
    *token_at = it;
    return true;
}

bool parse_switch(token **token_at, parse_context *context) {
    token *it = *token_at;
    context->parse_depth++;
    token *statement_start = it;

    if (!(it[0].type == TOKEN_TYPE_KEYWORD_SWITCH && it[1].type == TOKEN_TYPE_OPEN_PAREN)) {
        context->parse_depth--;
        return false;
    }

    context->unsupported_count++;
    issue_warning(warning_type_switch);

    flag_recognized_structure(&it, context, "Switch Statement");
    EMIT_TEXT("switch (");
    eat_tokens(&it, 2); /* "if", "(" */

    context->parse_depth++;
    bool parsing = true;
    while (parsing && it[0].type != TOKEN_TYPE_CLOSE_PAREN) {
        if (!parse_evaluable_expression(&it, context)) {
            parsing = false;
            flag_unrecognized_structure(&it, context, "Switch Statement: Test Value");
        }
    }
    context->parse_depth--;
    flag_recognized_structure(&it, context, "Switch Statement: End of Test Value");
    EMIT_TEXT(") ");
    eat_token(&it); /* ")" */

    /*context->indent_depth++;*/
    if (!parse_scope(&it, context)) {
        flag_unrecognized_structure(&it, context, "Switch Statement: Scope");
    }
    /*context->indent_depth--;*/

    *token_at = it;
    context->parse_depth--;
    return true;
}

bool parse_case(token **token_at, parse_context *context) {
    token *it = *token_at;
    token *statement_start = it;

    if (it[0].type != TOKEN_TYPE_KEYWORD_CASE) {
        return false;
    }

    context->unsupported_count++;
    issue_warning(warning_type_switch);


    flag_recognized_structure(&it, context, "Case Statement");
    eat_token(&it);

    EMIT_TEXT("\n");
    context->indent_depth--;
    EMIT_TEXT_INDENT("case ");

    if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
        EMIT_TEXT("%s:", it[0].text);
        eat_token(&it);
    }
    context->indent_depth++;

    if (it[0].type == TOKEN_TYPE_COLON)
        eat_token(&it);

    context->parse_depth--;
    *token_at = it;
    return true;
}

bool parse_default(token **token_at, parse_context *context) {
    token *it = *token_at;
    token *statement_start = it;

    if (it[0].type != TOKEN_TYPE_KEYWORD_DEFAULT) {
        return false;
    }

    context->unsupported_count++;
    issue_warning(warning_type_switch);


    flag_recognized_structure(&it, context, "Default Statement");
    eat_token(&it);

    EMIT_TEXT("\n");
    context->indent_depth--;
    EMIT_TEXT_INDENT("default:");
    context->indent_depth++;

    if (it[0].type == TOKEN_TYPE_COLON)
        eat_token(&it);

    context->parse_depth--;
    *token_at = it;
    return true;
}

bool parse_variable_declaration(token **token_at, parse_context *context) {
    token *it = *token_at;
    context->parse_depth++;
    token *declaration_start = it;
    context->parse_mode = PARSE_MODE_NO_OUTPUT;
    if (parse_type_expression(&it, context)) {
        context->parse_mode = PARSE_MODE_OUTPUT;
        if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
            flag_recognized_structure(&it, context, "Variable Declaration");
            char *variable_name = it[0].text;
            EMIT_TEXT("%s : ", variable_name);

            it = declaration_start;
            parse_type_expression(&it, context);
            eat_token(&it); /* <name> */

            parse_array_subscript(&it, context);

            if (it[0].type == TOKEN_TYPE_SEMICOLON) {
                EMIT_TEXT(";");
                eat_token(&it); /* ";" */
                *token_at = it;
                context->parse_depth--;
                return true;
            } else if (it[0].type == TOKEN_TYPE_COMMA) {
                while (it[0].type != TOKEN_TYPE_SEMICOLON) {
                    EMIT_TEXT(";");
                    eat_token(&it);
                    if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
                        flag_recognized_structure(&it, context, "Variable Declaration");
                        EMIT_TEXT("\n");
                        variable_name = it[0].text;
                        EMIT_TEXT_INDENT("%s : ", variable_name);
                        eat_token(&it);
                        token *next = it;
                        it = declaration_start;
                        parse_type_expression(&it, context);
                        it = next;
                        parse_array_subscript(&it, context);
                    }
                }
                eat_token(&it);
                EMIT_TEXT(";");
                *token_at = it;
                context->parse_depth--;
                return true;
            } else if (is_assignment_operator_token(it[0])) {
                EMIT_TEXT(" %s ", it[0].text);
                eat_token(&it); /* "=" */
                if (parse_evaluable_expression(&it, context)) {
                    flag_recognized_structure(&it, context, "Assignment expression after declaration");
                    if (it[0].type == TOKEN_TYPE_SEMICOLON) {
                        flag_recognized_structure(&it, context, "Closing ';' after assignment expression in declaration");
                        EMIT_TEXT(";");
                        eat_token(&it); /* ";" */
                    } else {
                        flag_unrecognized_structure(&it, context, "Closing ';' after assignment expression in declaration");
                    }
                    *token_at = it;
                    context->parse_depth--;
                    return true;
                }
                flag_unrecognized_structure(&it, context, "Assignment expression after declaration");
                context->parse_depth--;
                return false;
            }
            flag_unrecognized_structure(&it, context, "\';\' or assignment");
        }
    }
    context->parse_mode = PARSE_MODE_OUTPUT;
    context->parse_depth--;
    return false;
}

bool parse_scope(token **token_at, parse_context *context) {
    token *it = *token_at;
    if (it[0].type == TOKEN_TYPE_OPEN_CURLY_BRACE) {
        flag_recognized_structure(&it, context, "Scope: Start");
        EMIT_TEXT("{");
        eat_token(&it); /* "{" */
        context->indent_depth++;
        context->parse_depth++;

        while (it[0].type != TOKEN_TYPE_CLOSE_CURLY_BRACE) {

            if (parse_blank_line(&it, context))
                continue;

            if (parse_line_comment(&it, context))
                continue;

            if (parse_block_comment(&it, context))
                continue;

            if (parse_general_preprocessor(&it, context))
                continue;

            if (parse_default(&it, context))
                continue;

            if (parse_case(&it, context))
                continue;

            if (parse_goto_label(&it, context))
                continue;

            EMIT_TEXT("\n");
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

            flag_unrecognized_structure(&it, context, "Statement In Scope");
        }
        flag_recognized_structure(&it, context, "Scope: End");
        eat_token(&it); /* "}" */
        context->indent_depth--;
        context->parse_depth--;

        EMIT_TEXT("\n");
        EMIT_TEXT_INDENT("}");

        *token_at = it;
        context->parse_depth--;
        return true;
    }
    context->parse_depth--;
    return false;
}

bool parse_function_definition(token **token_at, parse_context *context) {
    token *it = *token_at;
    context->parse_depth++;

    token *function_start = it;
    context->parse_mode = PARSE_MODE_NO_OUTPUT;
    if (parse_type_expression(&it, context)) {
        context->parse_mode = PARSE_MODE_OUTPUT;
        token function_name_token = it[0];
        flag_recognized_structure(&it, context, "Function: Name");
        eat_token(&it);
        flag_recognized_structure(&it, context, "Function: Start of Arguments");
        eat_token(&it); /* "(" */

        EMIT_TEXT("\n%s :: (", function_name_token.text);

        /* Parse Argument List */

        context->parse_depth++;
        while (it && it[0].type != TOKEN_TYPE_CLOSE_PAREN) {
            bool arguemnt_is_pointer = false;
            token argument_type_token;
            token argument_name_token;

            if (parse_block_comment(&it, context))
                continue;

            if (it[0].type == TOKEN_TYPE_KEYWORD_CONST) {
                flag_recognized_structure(&it, context, "Function: Arguemnts: Const");
                eat_token(&it);
                /* Quietly eat all const tokens */
            }

            token *argument_start = it;
            context->parse_mode = PARSE_MODE_NO_OUTPUT;
            if (parse_type_expression(&it, context)) {
                context->parse_mode = PARSE_MODE_OUTPUT;
                bool has_name = false;
                if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
                    flag_recognized_structure(&it, context, "Function: Arguemnts: Name");
                    has_name = true;
                    EMIT_TEXT("%s: ", it[0].text);
                } else {
                    flag_recognized_structure(&it, context, "Function: Arguemnts: Un-Named Argument");
                    EMIT_TEXT("/* Un-Named : */ ");
                }
                it = argument_start;
                parse_type_expression(&it, context);
                if (has_name)
                    eat_token(&it); /* <name> */
            } else {
                context->parse_mode = PARSE_MODE_OUTPUT;
                flag_unrecognized_structure(&it, context, "Function Argument");
            }

            if (it[0].type == TOKEN_TYPE_OPEN_SQUARE_BRACE && it[1].type == TOKEN_TYPE_CLOSE_SQUARE_BRACE) {
                EMIT_TEXT("[..]");
                eat_tokens(&it, 2);
            }

            if (it[0].type == TOKEN_TYPE_COMMA) {
                EMIT_TEXT(", ");
                eat_token(&it);
            }

        }
        context->parse_depth--;
        flag_recognized_structure(&it, context, "Function: Arguments: End");
        eat_token(&it); /* ")" */

        it = function_start;
        if (it[0].type == TOKEN_TYPE_KEYWORD_VOID && it[1].type == TOKEN_TYPE_STAR) {
            EMIT_TEXT(") ");
        } else {
            EMIT_TEXT(") -> ");
            parse_type_expression(&it, context);
        }

        while (it[0].type != TOKEN_TYPE_SEMICOLON && it[0].type != TOKEN_TYPE_OPEN_CURLY_BRACE) {
            eat_token(&it);
        }

        if (it[0].type == TOKEN_TYPE_SEMICOLON) {
            flag_recognized_structure(&it, context, "Function Prototype");
            EMIT_TEXT(";");
            eat_token(&it);
            *token_at = it;
            context->parse_depth--;
            return true;
        } else {
            EMIT_TEXT(" ");
        }
        if (parse_scope(&it, context)) {
            *token_at = it;
            context->parse_depth--;
            return true;
        } else {
            flag_unrecognized_structure(&it, context, "Function Body");
        }
    }
    context->parse_mode = PARSE_MODE_OUTPUT;
    context->parse_depth--;
    return false;
}

bool parse_typedef(token **token_at, parse_context *context) {
    token *it = *token_at;
    context->parse_depth++;
    if (it[0].type == TOKEN_TYPE_KEYWORD_TYPEDEF) {
        if (it[1].type == TOKEN_TYPE_KEYWORD_ENUM &&
                it[2].type == TOKEN_TYPE_OPEN_CURLY_BRACE ) {
            flag_recognized_structure(&it, context, "Typedef: Enum");
            eat_tokens(&it, 3);

            token *enum_contents_start = it;

            while (it->type != TOKEN_TYPE_CLOSE_CURLY_BRACE) {
                eat_token(&it);
            }
            eat_token(&it);

            context->parse_depth++;
            if (it->type == TOKEN_TYPE_IDENTIFIER) {
                flag_recognized_structure(&it, context, "Typedef: Enum: Name");
                char *enum_name = it->text;

                EMIT_TEXT("%s :: enum {", enum_name);
                context->indent_depth++;

                it = enum_contents_start;
                while (it[0].type != TOKEN_TYPE_CLOSE_CURLY_BRACE) {

                    if (parse_blank_line(&it, context))
                        continue;

                    if (parse_line_comment(&it, context))
                        continue;

                    if (parse_block_comment(&it, context))
                        continue;

                    if (parse_general_preprocessor(&it, context))
                        continue;

                    if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
                        flag_recognized_structure(&it, context, "Typedef: Enum: Contents: Identifier");
                        EMIT_TEXT("\n");
                        EMIT_TEXT_INDENT("%s", it->text);
                        eat_token(&it);
                    } else {
                        flag_unrecognized_structure(&it, context, "Enum Contents");
                        continue;
                    }

                    if (it[0].type == TOKEN_TYPE_NUMBER) {
                        EMIT_TEXT(" %s", it->text);
                        eat_token(&it);
                    }
                    if (it[0].type == TOKEN_TYPE_COMMA) {
                        EMIT_TEXT(",");
                        eat_token(&it);
                    }
                }
                context->parse_depth--;
                flag_recognized_structure(&it, context, "Typedef: Enum: Contents: End");
                eat_tokens(&it, 3); /* "}", <name>, ";" */
                context->indent_depth--;

                EMIT_TEXT_INDENT("\n}");

                *token_at = it;
                context->parse_depth--;
                return true;
            }
        } else if (it[1].type == TOKEN_TYPE_KEYWORD_STRUCT &&
                it[2].type == TOKEN_TYPE_OPEN_CURLY_BRACE ) {
            flag_recognized_structure(&it, context, "Typedef: Struct");
            eat_tokens(&it, 3);

            token *struct_contents_start = it;

            while (it[0].type != TOKEN_TYPE_CLOSE_CURLY_BRACE) {
                eat_token(&it);
            }
            eat_token(&it);

            context->parse_depth++;
            if (it[0].type == TOKEN_TYPE_IDENTIFIER) {
                flag_recognized_structure(&it, context, "Typedef: Struct: Name");
                char *struct_name = it->text;

                EMIT_TEXT_INDENT("\n%s :: struct {", struct_name);
                context->indent_depth++;

                it = struct_contents_start;
                while (it[0].type != TOKEN_TYPE_CLOSE_CURLY_BRACE) {

                    if (parse_blank_line(&it, context))
                        continue;

                    if (parse_line_comment(&it, context))
                        continue;

                    if (parse_block_comment(&it, context))
                        continue;

                    if (parse_general_preprocessor(&it, context))
                        continue;

                    EMIT_TEXT("\n");
                    EMIT_TEXT_INDENT("");

                    if (parse_variable_declaration(&it, context))
                        continue;

                    flag_unrecognized_structure(&it, context, "Typedef Struct");
                }
                context->parse_depth--;
                flag_recognized_structure(&it, context, "Typedef: Struct: End of Contents");
                eat_tokens(&it, 3); /* "}", <name>, ";" */
                context->indent_depth--;

                EMIT_TEXT_INDENT("\n}");

                *token_at = it;
                context->parse_depth--;
                return true;
            }
        } else {
            eat_token(&it);

            token *base_type_start = it;

            context->parse_mode = PARSE_MODE_NO_OUTPUT;
            parse_type_expression(&it, context);
            context->parse_mode = PARSE_MODE_OUTPUT;

            if (it[0].type == TOKEN_TYPE_IDENTIFIER && it[1].type == TOKEN_TYPE_SEMICOLON) {
                flag_recognized_structure(&it, context, "Typedef: General");
                token *type_name_token = &it[0];

                EMIT_TEXT("%s :: ", type_name_token->text);

                it = base_type_start;
                parse_type_expression(&it, context);
                eat_tokens(&it, 2); /* <name>, ";" */

                EMIT_TEXT(";");

                *token_at = it;
                context->parse_depth--;
                return true;
            }
        }
    }
    context->parse_depth--;
    return false;
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
    int token_lookup_count = TOKEN_TYPE_COUNT-7; /* Total - number of container tokens (not in lookup table) */
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
                at++;
                continue;
            } else if (at[0] == ASCII_RETURN) {
                /* Windows and Classic Mac newlines */
                if (at[1] == ASCII_LINE_FEED) {
                    at++;
                }
                if (token_context->empty_line) {
                    add_token(TOKEN_TYPE_BLANK_LINE, token_at, "\\n", 2, at, token_context);
                    token_at++;
                }
                at++;
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
                at++;
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
                    at++;
                }
                int comment_string_length = at-comment_start;
                add_token(TOKEN_TYPE_LINE_COMMENT, token_at, comment_start, comment_string_length, comment_start, token_context);
                token_at++;
                at++;
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
                            at++;
                        }
                        token_context->line_number++;
                    } else if (at[0] == ASCII_LINE_FEED) {
                        /* Unix newlines */
                        token_context->line_number++;
                    }
                    at++;
                    token_context->line_start_at = at;
                }
                int comment_string_length = at-comment_start;
                add_token(TOKEN_TYPE_BLOCK_COMMENT, token_at, comment_start, comment_string_length, comment_start, token_context);
                token_at++;
                at++;
                at++;
                continue;
            }

            /* Detect string literals */
            if (at[0]=='"') {
                at++;
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
                            at++;
                        }
                        token_context->line_number++;
                    } else if (at[0] == ASCII_LINE_FEED) {
                        /* Unix newlines */
                        token_context->line_number++;
                    }
                    at++;
                }
                int string_length = at-string_start;
                add_token(TOKEN_TYPE_STRING_LITERAL, token_at, string_start, string_length, string_start, token_context);
                token_at++;
                at++;
                continue;
            }

            /* Detect character literals */
            if (at[0]=='\'') {
                at++;
                char *char_start = at;
                int contiguous_slash_count = 0;
                while (!(at[0] == '\'' && !(contiguous_slash_count%2)) && at[0] != ASCII_NULL) {
                    if (at[0]=='\\') {
                        contiguous_slash_count++;
                    } else {
                        contiguous_slash_count = 0;
                    }
                    at++;
                }
                int char_length = at-char_start;
                add_token(TOKEN_TYPE_CHARACTER_LITERAL, token_at, char_start, char_length, char_start, token_context);
                token_at++;
                at++;
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
                at++;
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
                at++;
            }
            if (at > identifier_start) {
                int identifier_string_length = at - identifier_start;
                add_token(TOKEN_TYPE_IDENTIFIER, token_at, identifier_start, identifier_string_length, identifier_start, token_context);
                token_at++;
                continue;
            }

            /* register unrecognized token */
            printf("Unrecognized character: \'%c\' (%i), Context: \"%.21s\"\n", at[0], (int)at[0], &at[-10]);
            at++;
        }
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

        if (parse_blank_line(&token_at, context))
            continue;

        if (parse_line_comment(&token_at, context))
            continue;

        if (parse_block_comment(&token_at, context))
            continue;

        /* Parse Include Statement (Libraries and Files) */
        if (parse_include(&token_at, context))
            continue;

        /* Parse Preprocessor Defines */
        if (parse_define(&token_at, context))
            continue;

        if (parse_general_preprocessor(&token_at, context))
            continue;

        /* Parse Function Definitions */
        if (parse_function_definition(&token_at, context))
            continue;

        /* Parse Typedef */
        if (parse_typedef(&token_at, context))
            continue;

        /* Variable Definitions */
        if (parse_variable_declaration(&token_at, context))
            continue;

        /* Unrecognized Structures */
        flag_unrecognized_structure(&token_at, context, "Global Scope");
    }

    /* Close up any remaning unirecognized blocks. */
    flag_recognized_structure(&token_at, context, "End of File");

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
