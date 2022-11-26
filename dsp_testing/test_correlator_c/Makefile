correlator: correlator.c
	#gcc -Wall -fsanitize=address,signed-integer-overflow,undefined -g -o correlator correlator.c
	gcc -Wall -g -o correlator correlator.c
run: correlator
	./correlator ../../fpga_signal_dumps/FT3D_bufferdump_1.bin ../../fpga_signal_dumps/FT3D_bufferdump_2.bin
clean:
	rm -f correlator
