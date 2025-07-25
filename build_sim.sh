#!/bin/sh
PATH=/opt/questasim/bin:$PATH
test -d work && rm -rf work
vlib work
vmap work work
vlog -quiet -sv -work work src/filter.sv
vlog -quiet -sv -work work src/top.sv
vlog -quiet -sv -work work src/uart_receiver_hex_printer.sv
vlog -quiet -sv -work work src/testbench.sv
vmake > Makefile
make -f Makefile
