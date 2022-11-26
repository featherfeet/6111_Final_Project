#!/usr/bin/env python3

import matplotlib.pyplot as plt
import numpy as np

CAPTURE_LENGTH = 1000

buf1 = np.frombuffer(open("../fpga_signal_dumps/FT3D_bufferdump_1.bin", "rb").read(), dtype = np.uint8)
buf2 = np.frombuffer(open("../fpga_signal_dumps/FT3D_bufferdump_2.bin", "rb").read(), dtype = np.uint8)

buf1 = buf1.astype(np.int32)
buf2 = buf2.astype(np.int32)

buf1 -= int(np.mean(buf1))
buf2 -= int(np.mean(buf2))

max_dot_product = 0
correlation = []

for phase_shift in range(-CAPTURE_LENGTH, CAPTURE_LENGTH):
    dot_product = 0
    for buf1_index in range(0, CAPTURE_LENGTH):
        buf1_value = buf1[buf1_index]
        if buf1_index - phase_shift < 0 or buf1_index - phase_shift >= CAPTURE_LENGTH:
            buf2_value = 0
        else:
            buf2_value = buf2[buf1_index - phase_shift]
        mult = buf1_value * buf2_value
        dot_product += mult
    correlation.append(dot_product)
    if dot_product > max_dot_product:
        max_dot_product = dot_product

plt.plot(correlation)
plt.show()
