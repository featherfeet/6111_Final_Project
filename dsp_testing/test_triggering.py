#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt

raw_data = pd.read_csv("./assorted_samples/FT50R-1.1.csv")["1"][1:]
raw_data_tmp = []
for pt in raw_data:
    raw_data_tmp.append(float(pt))
raw_data = raw_data_tmp

def minmax_filter(raw_data):
    filtered = []
    LOOK_BACK = 50
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
    LOW_THRESHOLD = 0.5
    HIGH_THRESHOLD = 0.8
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

plt.title("Keyup")
plt.xlabel("Samples")
plt.ylabel("Voltage")
plt.plot(raw_data, label = "Raw")
plt.plot(schmitt_trigger(minmax_filter(raw_data)), label = "Filtered")
plt.legend()
plt.show()