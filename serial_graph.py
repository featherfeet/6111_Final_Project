#!/usr/bin/env python3

import serial
import numpy as np
import matplotlib.pyplot as plt

s = serial.Serial("/dev/ttyUSB0", 115200, parity = serial.PARITY_ODD)
if s.in_waiting == 1:
    s.read(s.in_waiting)

data = s.read(1000)
buffer = np.frombuffer(data, dtype = np.uint8)

plt.plot(buffer)
plt.show()
