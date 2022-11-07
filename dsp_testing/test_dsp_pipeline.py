#!/usr/bin/env python3

import os
import pickle
import os.path
import pandas as pd
import matplotlib.pyplot as plt
import scipy.signal
import numpy as np

# Define some helpers for DSP.
def minmax_filter(raw_data):
    filtered = []
    LOOK_BACK = 500
    for i in range(len(raw_data)):
        if i >= LOOK_BACK:
            last_few_samples = raw_data[i - LOOK_BACK:i]
            maximum = max(last_few_samples)
            minimum = min(last_few_samples)
            filtered.append(maximum - minimum)
        else:
            filtered.append(1)
    return filtered

def schmitt_trigger(raw_data):
    LOW_THRESHOLD = 0.3
    HIGH_THRESHOLD = 0.65
    filtered = []
    state = 0
    for pt in raw_data:
        if pt < LOW_THRESHOLD:
            filtered.append(0)
            state = 0
        elif pt > HIGH_THRESHOLD:
            filtered.append(1)
            state = 1
        else:
            filtered.append(state)
    return filtered

# Load sample CSV data.
filenames = os.listdir("./siglent_scope_samples")

filenames_new = []
for filename in filenames:
    if ".csv" in filename:
        filenames_new.append(filename)
filenames = filenames_new

samples = {}

for filename in filenames:
    raw_data = pd.read_csv(os.path.join("./siglent_scope_samples", filename), header = 0, names = ["Time", "CH1"])
    raw_data = raw_data["CH1"]
    raw_data_tmp = []
    for pt in raw_data:
        raw_data_tmp.append(float(pt))
    downsampled = scipy.signal.decimate(np.array(raw_data_tmp), int(2000000 / 10000), ftype = "fir")
    samples[filename] = downsampled

"""
# Load reference CSV data.
reference_filenames = os.listdir("./assorted_reference_samples")
reference_fingerprints = {}

for reference_filename in reference_filenames:
    raw_data = pickle.load(open(os.path.join("./assorted_reference_samples", reference_filename), "rb"))
    reference_fingerprints[reference_filename] = raw_data
"""

# Extract fingerprints
fingerprints = {}
for filename in filenames:
    raw_data = samples[filename]
    trigger_signal = schmitt_trigger(minmax_filter(raw_data))
    trigger_time = trigger_signal.index(0)
    fingerprint = raw_data[trigger_time - 500:trigger_time - 500 + 300]
    fingerprints[filename] = fingerprint

# Correlate
for reference_fingerprint in filenames:
    print(f"Filter {reference_fingerprint}:", end = ' ')
    b = fingerprints[reference_fingerprint] - np.mean(fingerprints[reference_fingerprint])
    #b /= np.linalg.norm(b)
    scores = []
    for sample_fingerprint in filenames:
        if sample_fingerprint != reference_fingerprint:
            a = fingerprints[sample_fingerprint] - np.mean(fingerprints[sample_fingerprint])
            #a /= np.linalg.norm(a)
            correlation = np.correlate(a, b, mode = "full")
            score = max(correlation) / abs(min(correlation))
            scores.append((sample_fingerprint, score))
            """if score > 1.1:
                print("\033[1;32m", end = '')"""
            #print(f"    - {sample_fingerprint} = {score}\033[0m")
    scores = sorted(scores, key = lambda x: x[1])
    print(scores[-1][0])