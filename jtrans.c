
#include <stdlib.h>
#include <stdio.h>

int main (int argc, char *argv[]) {
    char *file_name;
    if (argc < 2) {
        printf("Must pass a file to translate.\n");
        return 1;
    } else if (argc > 2) {
        printf("Only single file processing currently supported.\n");
        printf("Please process one file at a time.\n");
        return 1;
    } else {
        file_name = argv[1];
        printf("File to process: %s\n", file_name);
    }
}
