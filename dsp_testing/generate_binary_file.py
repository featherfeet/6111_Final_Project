#!/usr/bin/env python3

import sys
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

if len(sys.argv) < 3:
    print("Usage: ./generate_binary_file.py input_file.csv output_file.bin")
    print("Convert a .CSV file of voltages from the oscilloscope into a raw binary where each byte is one sample as the ADC would see it.")
    exit()

input_filename = sys.argv[1]
output_filename = sys.argv[2]

input_data = pd.read_csv(input_filename, header = 0, names = ["Time", "CH1"])
voltages = np.array(input_data["CH1"], dtype = np.float64)

voltages *= (255.0 / 0.7)

voltages = np.clip(voltages, -128, 127)

voltages = voltages.astype(np.int8)

voltages_buffer = voltages.tobytes()

with open(output_filename, "wb") as output_file:
    output_file.write(voltages_buffer)
