
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int main (int argc, char *argv[]) {
    char *input_file_path;
    if (argc < 2) {
        printf("Must pass a file to translate.\n");
        return 1;
    } else if (argc > 2) {
        printf("Only single file processing currently supported.\n");
        printf("Please process one file at a time.\n");
        return 1;
    } else {
        input_file_path = argv[1];
        printf("File to process: %s\n", input_file_path);
    }

    int base_path_len = strchr(input_file_path, '.') - input_file_path + 1;

    char *output_file_path = malloc(base_path_len + 4);
    strncpy(output_file_path, input_file_path, base_path_len);
    output_file_path[base_path_len] = 0;
    strcat(output_file_path, "jai");

    printf("Output file: %s\n", output_file_path);

    FILE *output_file = NULL;
    output_file = fopen(output_file_path, "w");
    if (output_file) {
        fprintf(output_file, "/* Output file generated for: %s", input_file_path);
        fclose(output_file);
    }

    free(output_file_path);
}
