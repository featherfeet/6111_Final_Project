#!/usr/bin/env python3

import os

files = os.listdir()

for filename in files:
    new_filename = filename.replace(".bin.csv", ".csv")
    input_file = open(filename, "rb")
    data = input_file.read()
    input_file.close()
    data = data.replace(b'\x00', b'')
    output_file = open(new_filename, "wb")
    output_file.write(data)
    output_file.close()
