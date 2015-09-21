onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ADC_AD7985_Control_tb/uut/clk
add wave -noupdate /ADC_AD7985_Control_tb/uut/reset_n
add wave -noupdate /ADC_AD7985_Control_tb/uut/iRunStart
add wave -noupdate /ADC_AD7985_Control_tb/uut/SDO
add wave -noupdate /ADC_AD7985_Control_tb/uut/TURBIO
add wave -noupdate /ADC_AD7985_Control_tb/uut/CNV
add wave -noupdate /ADC_AD7985_Control_tb/uut/SCK
add wave -noupdate -radix hexadecimal /ADC_AD7985_Control_tb/uut/Dataout
add wave -noupdate /ADC_AD7985_Control_tb/uut/Dataout_en
add wave -noupdate -radix unsigned /ADC_AD7985_Control_tb/uut/sdo_cnt
add wave -noupdate -radix unsigned /ADC_AD7985_Control_tb/uut/cnt
add wave -noupdate /ADC_AD7985_Control_tb/uut/SCK_en
add wave -noupdate /ADC_AD7985_Control_tb/uut/State
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1090 ns} 0}
configure wave -namecolwidth 280
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {861 ns} {1748 ns}
