//Top level of the whole design
//quartusII 15.0
//University of Science and Technology of China
//Junbin Zhang
//20150914
module FPGA_TOP
(
	input CLK_OSC,
	input NRESET,
	/*-----IO interface of cy7c68013a---*/
	input usb_ifclk,
	input FLAGA,
	input FLAGB,
	input FLAGC,
	output SLCS,
	output SLOE,
	output SLWR,
	output SLRD,
	output PKTEND,
	output [1:0] FIFOADDR,
	inout [15:0] FD,
	/*----IO interface of AD7985--------*/
  /*for test modified 20151008 wyu
	input SDO1,
	output TURBIO1,
	output CNV1,
	output SCK1,
	input SDO2,
	output TURBIO2,
	output CNV2,
	output SCK2,
  */
	/*----IO interface of LEDs----*/
	output [3:0] LED,
  /*------POWER ON INDICATOR------*/
  output PW_LED
);
//assign PW_LED = 1'b0;
wire clk;//system clk 50M
wire IFCLK;//48M USB clock
wire reset_n;//system reset
/*-----Clock_Generator instantiation-----*/
Clock_Generator Clock_Gen
(
	.GCLK(CLK_OSC),
	.rst_n(NRESET),
	.usb_ifclk(usb_ifclk),
	.clk(clk),
	.IFCLK(IFCLK),
	.reset_n(reset_n)	
);
/*------usb_Command_interpreter instantiation-----*/
wire in_from_usb_Ctr_rd_en;
wire [15:0] in_from_usb_ControlWord;
wire [1:0] Channel_Select;
wire out_to_rst_all_fifo;
usb_command_interpreter usb_control
(
	.IFCLK(IFCLK),
	.clk(clk),
	.reset_n(reset_n),
	.in_from_usb_Ctr_rd_en(in_from_usb_Ctr_rd_en),  //
	.in_from_usb_ControlWord(in_from_usb_ControlWord),//
	.Channel_Select(Channel_Select),//
	.out_to_rst_all_fifo(out_to_rst_all_fifo),//
	//.LED(LED)
  .LED()
);
/*------usb_synchronous_slavefifo instantiation-----*/
wire [15:0] in_from_ext_fifo_dout;
wire in_from_ext_fifo_empty;
wire [13:0] in_from_ext_fifo_rd_data_count;//FIFO 16384*16
wire out_to_ext_fifo_rd_en;
usb_synchronous_slavefifo usb_cy7c68013A
(
	.IFCLK(IFCLK),
	.FLAGA(FLAGA),
	.FLAGB(FLAGB),
	.FLAGC(FLAGC),
	.nSLCS(SLCS),
	.nSLOE(SLOE),
	.nSLRD(SLRD),
	.nSLWR(SLWR),
	.nPKTEND(PKTEND),
	.FIFOADR(FIFOADDR),
	.FD_BUS(FD),
	.Acq_Start_Stop(Channel_Select[0] | Channel_Select[1]),//
	.Ctr_rd_en(in_from_usb_Ctr_rd_en),//
	.ControlWord(in_from_usb_ControlWord),//
	.in_from_ext_fifo_dout(in_from_ext_fifo_dout),
	.in_from_ext_fifo_empty(in_from_ext_fifo_empty),
	.in_from_ext_fifo_rd_data_count(in_from_ext_fifo_rd_data_count),
	.out_to_ext_fifo_rd_en(out_to_ext_fifo_rd_en)
);
/*-----ADC_AD7985_Control instantiation-------*/
//ADC channel 1
wire [15:0] chn1_Dataout;
wire chn1_Dataout_en;
/*For USB test.Modified by wyu 20151008
ADC_AD7985_Control AD7985_Chn1
(
	.clk(clk),
	.reset_n(reset_n),
	.iRunStart(Channel_Select[0]),//
	.SDO(SDO1), //pin
	.TURBIO(TURBIO1),//pin
	.CNV(CNV1),//pin
	.SCK(SCK1),//pin
	.Dataout(chn1_Dataout),
	.Dataout_en(chn1_Dataout_en)
);
*/
//For USB test.Modified by wyu 20151008
//channel 1 TEST
test chn1_test
(
  .clk(clk),
  .reset_n(reset_n),
  .iRunStart(Channel_Select[0]),
  .Dataout_en(chn1_Dataout_en),
  .Dataout(chn1_Dataout)
);
//ADC channel 2
wire [15:0] chn2_Dataout;
wire chn2_Dataout_en;
/*For USB test.Modified by wyu 20151008
ADC_AD7985_Control AD7985_Chn2
(
	.clk(clk),
	.reset_n(reset_n),
	.iRunStart(Channel_Select[1]),//
	.SDO(SDO2), //pin
	.TURBIO(TURBIO2),//pin
	.CNV(CNV2),//pin
	.SCK(SCK2),//pin
	.Dataout(chn2_Dataout),
	.Dataout_en(chn2_Dataout_en)
);
*/
//For USB test.Modified by wyu 20151008
//channel 2 TEST
test chn2_test
(
  .clk(clk),
  .reset_n(reset_n),
  .iRunStart(Channel_Select[1]),
  .Dataout_en(chn2_Dataout_en),
  .Dataout(chn2_Dataout)
);
/*-----Chn_fifo_Control instantiation------*/
wire [15:0] out_to_usb_ext_fifo_din;
wire out_to_usb_ext_fifo_en;
wire chn1_fifo_full_LED;
wire chn2_fifo_full_LED;
Chn_fifo_Control Chn_fifo_Control
(
	.clk(clk),
	.reset_n(reset_n),
	.rst_all_fifo(out_to_rst_all_fifo),//
	.Channel_Select(Channel_Select),//
	.chn1_Dataout(chn1_Dataout),//
	.chn1_Dataout_en(chn1_Dataout_en),//
	.chn2_Dataout(chn2_Dataout),//
	.chn2_Dataout_en(chn2_Dataout_en),//
  .chn1_fifo_full_LED(chn1_fifo_full_LED),
  .chn2_fifo_full_LED(chn2_fifo_full_LED),
	.out_to_usb_ext_fifo_din(out_to_usb_ext_fifo_din),
	.out_to_usb_ext_fifo_en(out_to_usb_ext_fifo_en)
);
/*-----usb data fifo instantiation-------*/
wire usb_fifo_wrfull;//Modified by wyu for test 20151009
usb_data_fifo usb_data
(
	.aclr(out_to_rst_all_fifo | ~reset_n),
	.wrclk(~clk),
	.wrreq(out_to_usb_ext_fifo_en & (!usb_fifo_wrfull)),
	.data(out_to_usb_ext_fifo_din),
	.wrfull(usb_fifo_wrfull),//Modified by wyu for test 20151009
	.rdclk(~IFCLK),
	.rdreq(out_to_ext_fifo_rd_en),
	.q(in_from_ext_fifo_dout),
	.rdempty(in_from_ext_fifo_empty),	
	.wrusedw(in_from_ext_fifo_rd_data_count) //[13:0]
);
assign PW_LED = ~usb_fifo_wrfull;
assign LED[0] = ~chn1_fifo_full_LED;
assign LED[1] = ~chn2_fifo_full_LED;
assign LED[2] = ~FLAGB;
assign LED[3] = 1'b1;

endmodule
