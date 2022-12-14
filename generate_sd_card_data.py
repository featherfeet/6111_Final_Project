#!/usr/bin/env python3

import sys
import numpy as np

filenames = ["fpga_signal_dumps/FT3D_bufferdump_1.bin", "fpga_signal_dumps/FT70D_bufferdump_2.bin"]

with open("sd_card_data.bin", "wb") as output_file:
    for filename in filenames:
        data = open(filename, "rb").read()
        buffer = np.frombuffer(data, dtype = np.uint8)

        buffer_zero_mean = buffer.astype(np.int16) - np.mean(buffer)
        buffer_zero_mean = buffer_zero_mean.astype(np.uint8)
        output_file.write(buffer_zero_mean.tobytes())
