//top level logic of this project
module FPGA_TOP
(
  input GCLK, //时钟输入管脚
  input rst_n,//复位输入管脚
  /*------cy7c68013a IO------*/
  input IFCLK,
  input FLAGA,
  input FLAGB,
  input FLAGC,
  input FLAGD,
  output nSLOE,
  output nSLRD,
  output nSLWR,
  output nPKTEND,
  output [1:0] FIFOADR,
  inout [15:0] FD_BUS,
  /*------AD7985 IO-------*/
  //chn1
  input SDO1,//ADC serial data in
  output TURBIO1,//ADC sampling rate control
  output CNV1,//ADC serial data read clock
  //chn2
  input SDO2,//ADC serial data in
  output TURBIO2,//ADC sampling rate control
  output CNV2,//ADC serial data read clock
  /*------LED------*/
  output LED[4:0]
);
/*-------Clock_Generator instantiation------*/
wire clk;
wire IFCLK;
wire reset_n;
Clock_Generator clock_gen
(
  .GCLK(GCLK),
  .rst_n(rst_n),
  .clk(clk),
  .reset_n(reset_n),
  .IFCLK(IFCLK)
);
/*------ADC_AD7985_Control------*/
//chn1
wire iRunStart1;
wire TURBIO1;
wire SDO1;
wire TURBIO1;
wire CNV1;
wire SCK1;
wire [15:0] chn1_Dataout;
wire chn1_Dataout_en;
ADC_AD7985_Control ADC_Channel1
(
  .clk(clk),
  .reset_n(reset_n),
  .iRunStart(iRunStart1),
  .SDO(SDO1),
  .TURBIO(TURBIO1),
  .CNV(CNV1),
  .SCK(SCK1),
  .Dataout(chn1_Dataout),
  .Dataout_en(chn1_Dataout_en)
);
//chn2
wire iRunStart2;
wire TURBIO2;
wire SDO2;
wire TURBIO2;
wire CNV2;
wire SCK2;
wire [15:0] chn2_Dataout;
wire chn2_Dataout_en;
ADC_AD7985_Control ADC_Channel2
(
  .clk(clk),
  .reset_n(reset_n),
  .iRunStart(iRunStart2),
  .SDO(SDO2),
  .TURBIO(TURBIO2),
  .CNV(CNV2),
  .SCK(SCK2),
  .Dataout(chn2_Dataout),
  .Dataout_en(chn2_Dataout_en)
);
/*------2Channel ADC fifo Control------*/
wire rst_all_fifo;
wire [1:0] Channel_Select;
wire [15:0] out_to_usb_ext_fifo_din;
wire out_to_usb_ext_fifo_en;
Chn_fifo_Control FIFO_Control
(
  .clk(clk),
  .reset_n(reset_n),
  .rst_all_fifo(rst_all_fifo),
  .Channel_Select(Channel_Select),
  .chn1_Dataout(chn1_Dataout),
  .chn1_Dataout_en(chn1_Dataout_en),
  .chn2_Dataout(chn2_Dataout),
  .chn2_Dataout_en(chn2_Dataout_en),
  .out_to_usb_ext_fifo_din(out_to_usb_ext_fifo_din),
  .out_to_usb_ext_fifo_en(out_to_usb_ext_fifo_en)
);
/*------usb synchronous slavefifo control------*/
//usb command
wire out_to_usb_Acq_Start_Stop;
wire in_from_usb_Ctr_rd_en;
wire [15:0] in_from_usb_ControlWord;
//usb fifo
wire [15:0] usb_data_fifo_dout;

usb_synchronous_slavefifo Cy7c68013A_slavefifo
(
  .IFCLK(IFCLK),
  .FLAGA(FLAGA),
  .FLAGB(FLAGB),
  .FLAGC(FLAGC),
  .nSLCS(FLAGD),
  .nSLOE(nSLOE),
  .nSLRD(nSLRD),
  .nPKTEND(nPKTEND),
  .FIFOADR(FIFOADR),
  .FD_BUS(FD_BUS),
  //interface with control
  .Acq_Start_Stop(out_to_usb_Acq_Start_Stop),
  .Ctr_rd_en(in_from_usb_Ctr_rd_en),
  .ControlWord(in_from_usb_ControlWord),
  //interface with external fifo
  .in_from_ext_fifo_dout(),
  .infrom_ext_fifo_empty(),
  .in_from_ext_fifo_rd_data_count(),
  .out_to_ext_fifo_rd_en()
);
/*------usb command process------*/
usb_command_interpreter CCC
(
  .IFCLK(IFCLK),
  .clk(clk),
  .reset_n(reset_n),
  .in_from_usb_Ctr_rd_en(in_from_usb_Ctr_rd_en),
  .in_from_usb_ControlWord(in_from_usb_ControlWord),
  .out_to_usb_Acq_Start(out_to_usb_Acq_Start_Stop),
  .out_to_rst_usb_data_fifo(),
  .LED(LED)
);
endmodule
