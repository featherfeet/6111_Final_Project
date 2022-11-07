#!/usr/bin/env python3

import os
import numpy as np
import matplotlib.pyplot as plt

sample_filenames = os.listdir("./samples")
samples = {}

for sample_filename in sample_filenames:
    f = open(os.path.join("./samples", sample_filename), "rb")
    raw_data = f.read()
    data_array = np.frombuffer(raw_data, dtype = np.uint8)
    data_array = data_array.astype(np.int32) - 128
    samples[sample_filename] = data_array

for sample_to_compare in sample_filenames:
    print(f"Comparisons for {sample_to_compare}:")
    sample_to_compare_fft = np.conj(np.fft.fft(samples[sample_to_compare]))
    for comparison in sample_filenames:
        if comparison != sample_to_compare:
            comparison_fft = np.fft.fft(samples[comparison])
            correlation_fft = np.multiply(sample_to_compare_fft, comparison_fft)
            correlation = np.fft.ifft(correlation_fft)
            print(f"    - {comparison.ljust(20)} : {str(max(correlation)).rjust(6)}")
            """
            plt.title(comparison)
            plt.plot(np.fft.ifft(correlation_fft))
            plt.plot()
            plt.show()
            """