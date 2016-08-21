
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>

typedef enum {
    /* KEYWORDS */
    TOKEN_TYPE_KEYWORD_AUTO,
    TOKEN_TYPE_KEYWORD_BREAK,
    TOKEN_TYPE_KEYWORD_CASE,
    TOKEN_TYPE_KEYWORD_CHAR,
    TOKEN_TYPE_KEYWORD_CONST,
    TOKEN_TYPE_KEYWORD_CONTINUE,
    TOKEN_TYPE_KEYWORD_DEFAULT,
    TOKEN_TYPE_KEYWORD_DO,
    TOKEN_TYPE_KEYWORD_DOUBLE,
    TOKEN_TYPE_KEYWORD_ELSE,
    TOKEN_TYPE_KEYWORD_ENUM,
    TOKEN_TYPE_KEYWORD_EXTERN,
    TOKEN_TYPE_KEYWORD_FLOAT,
    TOKEN_TYPE_KEYWORD_FOR,
    TOKEN_TYPE_KEYWORD_GOTO,
    TOKEN_TYPE_KEYWORD_IF,
    TOKEN_TYPE_KEYWORD_INT,
    TOKEN_TYPE_KEYWORD_LONG,
    TOKEN_TYPE_KEYWORD_REGISTER,
    TOKEN_TYPE_KEYWORD_RETURN,
    TOKEN_TYPE_KEYWORD_SHORT,
    TOKEN_TYPE_KEYWORD_SIGNED,
    TOKEN_TYPE_KEYWORD_SIZEOF,
    TOKEN_TYPE_KEYWORD_STATIC,
    TOKEN_TYPE_KEYWORD_STRUCT,
    TOKEN_TYPE_KEYWORD_SWITCH,
    TOKEN_TYPE_KEYWORD_TYPEDEF,
    TOKEN_TYPE_KEYWORD_UNION,
    TOKEN_TYPE_KEYWORD_UNSIGNED,
    TOKEN_TYPE_KEYWORD_VOID,
    TOKEN_TYPE_KEYWORD_VOLATILE,
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
    TOKEN_TYPE_CLOSE_SQUARE_BRACE,
    TOKEN_TYPE_COMPARISON_EQUALS,
    TOKEN_TYPE_GREATER_EQUAL,
    TOKEN_TYPE_LESSER_EQUAL,
    TOKEN_TYPE_ASSIGNMENT_PLUS,
    TOKEN_TYPE_ASSIGNMENT_MINUS,
    TOKEN_TYPE_ASSIGNMENT_MULTPLY,
    TOKEN_TYPE_ASSIGNMENT_DIVIDE,
    TOKEN_TYPE_ASSIGNMENT_MODULUS,
    TOKEN_TYPE_ASSIGNMENT_LEFT_SHIFT,
    TOKEN_TYPE_ASSIGNMENT_RIGHT_SHIFT,
    TOKEN_TYPE_ASSIGNMENT_AND,
    TOKEN_TYPE_ASSIGNMENT_OR,
    TOKEN_TYPE_ASSIGNMENT_XOR,
    TOKEN_TYPE_ASSIGNMENT_EQUALS,
    TOKEN_TYPE_AND,
    TOKEN_TYPE_OR,
    TOKEN_TYPE_NOT,
    TOKEN_TYPE_BITWISE_AND,
    TOKEN_TYPE_BITWISE_OR,
    TOKEN_TYPE_BITWISE_XOR,
    TOKEN_TYPE_BITWISE_NOT,
    TOKEN_TYPE_COMMA,
    TOKEN_TYPE_COLON,
    TOKEN_TYPE_SEMICOLON,
    TOKEN_TYPE_DOT,
    TOKEN_TYPE_STAR,
    TOKEN_TYPE_LEFT_SHIFT,
    TOKEN_TYPE_RIGHT_SHIFT,
    TOKEN_TYPE_INCREMENT,
    TOKEN_TYPE_DECREMENT,
    TOKEN_TYPE_PLUS,
    TOKEN_TYPE_MINUS,
    TOKEN_TYPE_MULTIPLY,
    TOKEN_TYPE_DIVIDE,
    TOKEN_TYPE_MODULUS,
    TOKEN_TYPE_OPEN_ANGLE_BRACE,
    TOKEN_TYPE_CLOSE_ANGLE_BRACE,
    TOKEN_TYPE_SLASH,
    TOKEN_TYPE_BACKSLASH,

    /* PREPROCESSOR */
    TOKEN_TYPE_PRE_INCLUDE_LIB,
    TOKEN_TYPE_PRE_INCLUDE_DEFINE,
    TOKEN_TYPE_PRE_INCLUDE_UNDEF,
    TOKEN_TYPE_PRE_INCLUDE_IF,
    TOKEN_TYPE_PRE_IFDEF,
    TOKEN_TYPE_PRE_IFNDEF,
    TOKEN_TYPE_PRE_ERROR,
    TOKEN_TYPE_PRE_PRAGMA,
    TOKEN_TYPE_PRE_FILE_MACRO,
    TOKEN_TYPE_PRE_LINE_MACRO,
    TOKEN_TYPE_PRE_DATE_MACRO,
    TOKEN_TYPE_PRE_TIME_MACRO,
    TOKEN_TYPE_PRE_TIMESTAMP_MACRO,
    TOKEN_TYPE_PRE_HASH,
    TOKEN_TYPE_PRE_DOUBLE_HASH,

    /* CONTAINER TOKENS */
    TOKEN_TYPE_LINE_COMENT,
    TOKEN_TYPE_BLOCK_COMENT,
    TOKEN_TYPE_STRING_LITERAL,
    TOKEN_TYPE_CHARACTER_LITERAL,
    TOKEN_TYPE_NUMBER,
    TOKEN_TYPE_IDENTIFIER,
    TOKEN_TYPE_BLANK_LINE,

    TOKEN_TYPE_COUNT
} token_type;


#define ASCII_NULL       0
#define ASCII_TAB        9
#define ASCII_LINE_FEED 10
#define ASCII_RETURN    13
#define ASCII_SPACE     32

typedef struct {
    token_type type;
    char *text;
    // FILE REFERENCE
    int line_number;
    int char_number;
} token;

void add_token(token_type type, char *text, int text_length, token *token_at, int line_number, int char_number) {
    char *token_text =  malloc((text_length+1)*sizeof(char));
    strncpy(token_text, text, text_length);
    token_text[text_length] = 0;
    /*printf("Token Type: %i, Text: \"%s\", Line: %i, Char: %i\n", type, token_text, line_number, char_number);*/
    token_at->type = type;
    token_at->text = token_text;
    token_at->line_number = line_number;
    token_at->char_number = char_number;
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

int main (int argc, char *argv[]) {
    char *input_file_path;
    if (argc < 2) {
        printf("Must pass a file to translate.\n");
        exit(EXIT_FAILURE);
    } else if (argc > 2) {
        printf("Only single file processing currently supported.\n");
        printf("Please process one file at a time.\n");
        exit(EXIT_FAILURE);
    } else {
        input_file_path = argv[1];
        printf("File to process: %s\n", input_file_path);
    }

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
    int token_lookup_count = TOKEN_TYPE_COUNT-7; // Total - number of container tokens (not in lookup table)
    char *token_lookup[token_lookup_count];

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

    /* PREPROCESSOR */
    token_lookup[TOKEN_TYPE_PRE_INCLUDE_LIB] = "#include";
    token_lookup[TOKEN_TYPE_PRE_INCLUDE_DEFINE] = "#define";
    token_lookup[TOKEN_TYPE_PRE_INCLUDE_UNDEF] = "#undef";
    token_lookup[TOKEN_TYPE_PRE_INCLUDE_IF] = "#if";
    token_lookup[TOKEN_TYPE_PRE_IFDEF] = "#ifdef";
    token_lookup[TOKEN_TYPE_PRE_IFNDEF] = "#ifndef";
    token_lookup[TOKEN_TYPE_PRE_ERROR] = "#error";
    token_lookup[TOKEN_TYPE_PRE_PRAGMA] = "#pragma";
    token_lookup[TOKEN_TYPE_PRE_FILE_MACRO] = "__FILE__";
    token_lookup[TOKEN_TYPE_PRE_LINE_MACRO] = "__LINE__";
    token_lookup[TOKEN_TYPE_PRE_DATE_MACRO] = "__DATE__";
    token_lookup[TOKEN_TYPE_PRE_TIME_MACRO] = "__TIME__";
    token_lookup[TOKEN_TYPE_PRE_TIMESTAMP_MACRO] = "__TIMESTAMP__";
    token_lookup[TOKEN_TYPE_PRE_HASH] = "#";
    token_lookup[TOKEN_TYPE_PRE_DOUBLE_HASH] = "##";


    /* Tokenize Input File */
    token token_buffer[1000];
    token *token_at = &token_buffer[0];
    char *at = input_buffer;
    bool empty_line = true;
    int line_number = 1;
    char *line_start_at = at;
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
            if (empty_line) {
                add_token(TOKEN_TYPE_BLANK_LINE, "\\n", 2, token_at, line_number, at-line_start_at+1);
                token_at++;
            }
            at++;
            line_number++;
            line_start_at = at;
            empty_line = true;
            continue;
        } else if (at[0] == ASCII_LINE_FEED) {
            /* Unix newlines */
            if (empty_line) {
                add_token(TOKEN_TYPE_BLANK_LINE, "\\n", 2, token_at, line_number, at-line_start_at+1);
                token_at++;
            }
            at++;
            line_number++;
            line_start_at = at;
            empty_line = true;
            continue;
        }
        empty_line = false;

        /* Detect Line-wise Comments */
        if (at[0] == '/' && at[1] == '/') {
            at += 2;
            char *comment_start = at;
            while (at[0] != ASCII_RETURN && at[0] != ASCII_LINE_FEED  && at[0] != ASCII_NULL ) {
                at++;
            }
            int comment_string_length = at-comment_start;
            add_token(TOKEN_TYPE_LINE_COMENT, comment_start, comment_string_length, token_at, line_number, comment_start-line_start_at+1);
            token_at++;
            at++;
            line_number++;
            line_start_at = at;
            empty_line = true;
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
                    line_number++;
                } else if (at[0] == ASCII_LINE_FEED) {
                    /* Unix newlines */
                    line_number++;
                }
                at++;
                line_start_at = at;
            }
            int comment_string_length = at-comment_start;
            add_token(TOKEN_TYPE_BLOCK_COMENT, comment_start, comment_string_length, token_at, line_number, comment_start-line_start_at+1);
            token_at++;
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
                    line_number++;
                } else if (at[0] == ASCII_LINE_FEED) {
                    /* Unix newlines */
                    line_number++;
                }
                at++;
            }
            int string_length = at-string_start;
            add_token(TOKEN_TYPE_STRING_LITERAL, string_start, string_length, token_at, line_number, string_start-line_start_at+1);
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
            add_token(TOKEN_TYPE_CHARACTER_LITERAL, char_start, char_length, token_at, line_number, char_start-line_start_at+1);
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
                add_token(token_type_index, token_string, token_string_length, token_at, line_number, at-line_start_at+1);
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
            add_token(TOKEN_TYPE_NUMBER, number_start, number_string_length, token_at, line_number, number_start-line_start_at+1);
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
            add_token(TOKEN_TYPE_NUMBER, identifier_start, identifier_string_length, token_at, line_number, identifier_start-line_start_at+1);
            token_at++;
            continue;
        }

        /* register unrecognized token */
        printf("Unrecognized character: \'%c\' (%i), Context: \"%.21s\"\n", at[0], (int)at[0], &at[-10]);
        at++;
    }

    /* Write token list to output file. */
    fprintf(output_file, "/* Output file generated for: %s */\n", input_file_path);

    /* Cleanup Token Buffer */
    token *last_token = token_at;
    token_at = &token_buffer[0];
    while (token_at<last_token) {
        fprintf(output_file, "Line: %3i, Char: %3i, Type: %3i, Text: \"%s\"\n", token_at->line_number, token_at->char_number, token_at->type, token_at->text);
        free(token_at->text);
        token_at++;
    }

    fclose(output_file);

    free(input_buffer);
    free(output_file_path);

    exit(EXIT_SUCCESS);
}
