#!/usr/bin/env python3

import os
import os.path
import numpy as np
import matplotlib.pyplot as plt

#filenames = os.listdir("../fpga_signal_dumps")
filenames = ["FT3D_bufferdump_1.bin", "FT3D_bufferdump_2.bin", "FT3D_bufferdump_3.bin", "FT70D_bufferdump_2.bin", "FT70D_bufferdump_3.bin", "FT70D_bufferdump_4.bin"]

samples = {}

for filename in filenames:
    samples[filename] = np.frombuffer(open(os.path.join("../fpga_signal_dumps", filename), "rb").read(), dtype = np.uint8)
    mean = np.mean(samples[filename].astype(np.int16))
    samples[filename] = samples[filename].astype(np.int16) - mean
    samples[filename] = samples[filename].astype(np.int32)

fig, axs = plt.subplots(len(filenames), len(filenames) - 1, sharex = True)

for i, filename in enumerate(filenames):
    j = 0
    for other_filename in filenames:
        if other_filename != filename:
            correlation = np.correlate(samples[filename], samples[other_filename], mode = "full")
            phase_shift = np.argmax(correlation) - 1000
            print(f"{phase_shift} is phase_shift for {filename} vs {other_filename}")
            #axs[i, j].plot(correlation)
            axs[i, j].plot(samples[filename])
            axs[i, j].plot(np.array(range(phase_shift, phase_shift + 1000)), samples[other_filename])
            similarity = []
            for x in range(0, 1000):
                buf1_value = samples[filename][x]
                if x - phase_shift < 0 or x - phase_shift >= 1000:
                    buf2_value = 0
                else:
                    buf2_value = samples[other_filename][x - phase_shift]
                similarity.append(abs(buf2_value - buf1_value))
            axs[i, j].plot(similarity)
            title = axs[i, j].set_title(f"{other_filename.replace('.bin', '')} = {sum(similarity)}")
            if sum(similarity) < 3600:
                plt.setp(title, color = "green")
            else:
                plt.setp(title, color = "red")
            axs[i, j].axvline(x = np.argmax(correlation), color = "red")
            if j == 0:
                axs[i, j].set_ylabel(filename, rotation = 0, size = "large")
            j += 1

fig.tight_layout()
plt.show()
