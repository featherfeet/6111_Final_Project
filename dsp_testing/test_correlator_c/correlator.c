#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>

typedef struct {
    uint8_t *data;
    size_t length;
} Signal;

Signal load_signal(const char *filename) {
    FILE *input_file = fopen(filename, "rb");
    fseek(input_file, 0, SEEK_END);
    long file_size = ftell(input_file);
    fseek(input_file, 0, SEEK_SET);

    Signal ret;

    ret.data = (uint8_t *) malloc(file_size);
    ret.length = fread(ret.data, 1, file_size, input_file);

    return ret;
}

int correlate(Signal a, Signal b) {
    if (a.length != b.length) {
        return 0;
    }

    int8_t *a_zero_mean = malloc(a.length);
    int8_t *b_zero_mean = malloc(a.length);
    uint32_t a_accumulator = 0;
    uint32_t b_accumulator = 0;

    for (int i = 0; i < a.length; i++) {
        a_accumulator += a.data[i];
        b_accumulator += b.data[i];
    }
    a_accumulator /= a.length;
    b_accumulator /= b.length;
    for (int i = 0; i < a.length; i++) {
        a_zero_mean[i] = a.data[i] - a_accumulator;
        b_zero_mean[i] = b.data[i] - b_accumulator;
    }

    int32_t max = 0;
    for (int phase_shift = 0; phase_shift < a.length; phase_shift++) {
        int32_t dot_product = 0;
        for (int a_index = 0; a_index < a.length; a_index++) {
            int8_t a_value = a_zero_mean[a_index];
            int8_t b_value = b_zero_mean[(a_index - phase_shift) < 0 ? 0 : (a_index - phase_shift)];
            int16_t mult = a_value * b_value;
            dot_product += mult;
        }

        if (dot_product > max) {
            max = dot_product;
        }
    }

    free(a_zero_mean);
    free(b_zero_mean);

    return max;
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Usage: ./test_matched_filtering signal_of_interest.bin fingerprint.bin\n");
        return -1;
    }

    Signal signal_of_interest = load_signal(argv[1]);
    Signal fingerprint = load_signal(argv[2]);

    printf("max(correlation) = %d\n", correlate(signal_of_interest, fingerprint));

    free(signal_of_interest.data);
    free(fingerprint.data);

    return 0;
}
