if [file exists work] {vdel -lib work -all}

vlib work

project compileall
project compileall
project compileall
project compileall


vcom ./*.vhd 
vlog ./*.sv

vsim -coverage work.tb


add wave -position end sim:/tb/dut/*
add wave -position end sim:/tb/i_intf_apb/*
add wave -position end sim:/tb/i_intf_axi/*


run 500000ns

coverage report -html -output covhtmlreport -annotate -details -assert -directive -cvg -code bcefst -threshL 50 -threshH 90


