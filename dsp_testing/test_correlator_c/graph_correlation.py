#!/usr/bin/env python3

import matplotlib.pyplot as plt
import numpy as np

f = open("correlation.bin", "rb")
data = f.read()
buf = np.frombuffer(data, dtype = np.int32)
plt.plot(buf)
plt.show()
