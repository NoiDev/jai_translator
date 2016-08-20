
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

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

    fprintf(output_file, "/* Output file generated for: %s */", input_file_path);

    /* Load input file into memory. */
    char *input_buffer;
    fseek(input_file, 0L, SEEK_END);
    int input_file_size = ftell(input_file);
    fseek(input_file, 0L, SEEK_SET);
    input_buffer = (char *)malloc(input_file_size + 1);
    fread(input_buffer, input_file_size, 1, input_file);
    input_buffer[input_file_size] = 0;
    fclose(input_file);

    fclose(output_file);

    free(input_buffer);
    free(output_file_path);

    exit(EXIT_SUCCESS);
}
