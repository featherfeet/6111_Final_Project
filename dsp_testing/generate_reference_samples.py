#!/usr/bin/env python3

import os
import os.path
import pickle
import pandas as pd
import matplotlib.pyplot as plt

# Load reference CSV data.
reference_filenames = os.listdir("./assorted_reference_samples_original")
reference_samples = {}

for reference_filename in reference_filenames:
    raw_data = pd.read_csv(os.path.join("./assorted_reference_samples_original", reference_filename))["1"][1:]
    raw_data_tmp = []
    for pt in raw_data:
        raw_data_tmp.append(float(pt))
    reference_samples[reference_filename] = raw_data_tmp

for reference_filename in reference_filenames:
    plt.title(reference_filename)
    plt.plot(reference_samples[reference_filename])
    plt.show()
    start = int(input("Start? "))
    end = int(input("End? "))
    fingerprint = list(reference_samples[reference_filename][start:end])
    pickle.dump(fingerprint, open(os.path.join("./assorted_reference_samples", reference_filename.replace(".csv", ".pickle")), 'wb'))