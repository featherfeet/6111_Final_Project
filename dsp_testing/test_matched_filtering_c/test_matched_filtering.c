#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <stdint.h>

typedef struct {
    int8_t *data;
    size_t length;
} Signal;

Signal load_signal(const char *filename) {
    FILE *input_file = fopen(filename, "rb");
    fseek(input_file, 0, SEEK_END);
    long file_size = ftell(input_file);
    fseek(input_file, 0, SEEK_SET);

    Signal ret;

    ret.data = (int8_t *) malloc(file_size);
    ret.length = fread(ret.data, 1, file_size, input_file);

    return ret;
}

#define LOOK_BACK 500
#define LOW_THRESHOLD 37
#define HIGH_THRESHOLD 74
int find_fingerprint(int8_t *signal, int len) {
    bool state = true;
    int8_t prev_state = true;
    for (int i = LOOK_BACK; i < len; i++) {
        // "Minmax" filter
        int8_t min = 127;
        int8_t max = -128;
        for (int j = i - LOOK_BACK; j < i; j++) {
            if (signal[j] < min) {
                min = signal[j];
            }
            else if (signal[j] > max) {
                max = signal[j];
            }
        }
        int16_t difference = max - min;

        // Schmitt trigger
        if (difference < LOW_THRESHOLD) {
            state = false;
        }
        else if (difference > HIGH_THRESHOLD) {
            state = true;
        }

        // Falling-edge detector.
        if (prev_state && !state) {
            return i - LOOK_BACK;
        }
    }
    return -1;
}

int main(int argc, char *argv[]) {
    Signal ft3d = load_signal("FT3D.1.bin");

    int fingerprint_location = find_fingerprint(ft3d.data, ft3d.length);
    printf("%d\n", fingerprint_location);

    free(ft3d.data);
}
