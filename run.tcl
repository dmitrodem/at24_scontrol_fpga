#create_project -name at24_scontrol -dir . -pn GW5A-LV25MG121NC1/I0 -device_version A -force
set_device GW5A-LV25MG121NC1/I0 -device_version A
set_option -output_base_name at24_scontrol

set_option -verilog_std sysv2017

set_option -use_sspi_as_gpio 1
set_option -use_ready_as_gpio 1
set_option -use_done_as_gpio 1
set_option -use_i2c_as_gpio 1
set_option -use_cpu_as_gpio 1

add_file -type verilog [file normalize "src/filter.sv"]
add_file -type verilog [file normalize "src/top.sv"]
add_file -type cst [file normalize "src/top.cst"]
add_file -type sdc [file normalize "src/top.sdc"]

run all
