#!/usr/bin/env python3

import os
import numpy as np
from numpy import linalg as LA
import matplotlib.pyplot as plt

sample_filenames = os.listdir("./samples")
samples = {}

for sample_filename in sample_filenames:
    f = open(os.path.join("./samples", sample_filename), "rb")
    raw_data = f.read()
    data_array = np.frombuffer(raw_data, dtype = np.uint8)
    data_array = data_array.astype(np.int32) - 128
    #samples[sample_filename] = data_array[0:500]
    samples[sample_filename] = data_array
    #plt.title(sample_filename)
    #plt.plot(data_array)
    #plt.show()

for sample_to_compare in sample_filenames:
    print(f"Comparisons for {sample_to_compare}:")
    for comparison in sample_filenames:
        if comparison != sample_to_compare:
            a = samples[sample_to_compare] / LA.norm(samples[sample_to_compare])
            b = samples[comparison] / LA.norm(samples[comparison])
            a = samples[sample_to_compare]
            b = samples[comparison]
            correlation = np.correlate(a, b, mode = "full")
            max_correlation = max(correlation)
            min_correlation = min(correlation)
            #plt.title(f"{sample_to_compare} against {comparison}")
            #plt.plot(correlation)
            #plt.show()
            score = max_correlation / abs(min_correlation)
            if score > 2.0:
                print("\033[1;32m", end = "")
            print(f"    - {comparison.ljust(20)} : {str(score).rjust(6)}\033[0m")