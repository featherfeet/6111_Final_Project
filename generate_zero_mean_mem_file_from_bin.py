#!/usr/bin/env python3

import sys
import numpy as np

data = open(sys.argv[1], "rb").read()
buffer = np.frombuffer(data, dtype = np.uint8)

buffer_zero_mean = buffer.astype(np.int16) - np.mean(buffer)
buffer_zero_mean = buffer_zero_mean.astype(np.uint8)

with open(sys.argv[1] + ".memh", "w") as output_file:
    for value in buffer_zero_mean:
        output_file.write(f"{value:02x}\n")
