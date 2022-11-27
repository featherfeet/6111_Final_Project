#!/usr/bin/env python3

import sys
import serial
import numpy as np
import matplotlib.pyplot as plt

s = serial.Serial("/dev/ttyUSB2", 115200, parity = serial.PARITY_ODD)
if s.in_waiting == 1:
    s.read(s.in_waiting)

data = s.read(1000)
buffer = np.frombuffer(data, dtype = np.uint8)

plt.plot(buffer)
plt.show()

if len(sys.argv) == 2:
    with open(sys.argv[1], "wb") as fout:
        fout.write(data)
