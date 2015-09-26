`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:08:40 07/09/2015 
// Design Name: 
// Module Name:    usb_command_interpreter 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module usb_command_interpreter(
      input IFCLK,
      input clk,
      input reset_n,
      /*--------USB interface------------*/
      input in_from_usb_Ctr_rd_en,
      input [15:0] in_from_usb_ControlWord,
      //output reg out_to_usb_Acq_Start_Stop,
      output reg [1:0] out_to_ADC_chn_Select, 
      /*-------clear usb fifo------------*/
      output reg out_to_rst_usb_data_fifo, //asynchronized reset
      /*-------LED test------------------*/
      output reg [4:0] LED
    );
wire [15:0] USB_COMMAND;
reg fifo_rden;
wire fifo_empty;
//wire fifo_full;
usb_commad_fifo usbcmdfifo_16depth (
  .rst(~reset_n),                // input rst
  .wr_clk(~IFCLK),                // input wr_clk
  .rd_clk(~clk),                  // input rd_clk
  .din(in_from_usb_ControlWord), // input [15 : 0] din
  .wr_en(in_from_usb_Ctr_rd_en), // input wr_en
  .rd_en(fifo_rden),             // input rd_en
  .dout(USB_COMMAND),            // output [15 : 0] dout
  //.full(fifo_full),              // output full
  .full(),
  .empty(fifo_empty)             // output empty
);
localparam Idle = 1'b0;
localparam READ = 1'b1;
reg State;
always @ (posedge clk , negedge reset_n) begin
  if(~reset_n) begin
    fifo_rden <= 1'b0;
    State <= Idle;
  end
  else begin
    case(State)
      Idle:begin
        if(fifo_empty)
          State <= Idle;
        else begin
          fifo_rden <= 1'b1;
          State <= READ;
        end
      end
      READ:begin
        fifo_rden <= 1'b0;
        State <= Idle;
      end
      default:State <= Idle;
    endcase
  end
end
//command process
//acq start or stop f0f0,f0f1
always @ (posedge clk , negedge reset_n) begin
  if(~reset_n)
    out_to_usb_Acq_Start_Stop <= 1'b0;
  else if(fifo_rden && USB_COMMAND[15:4] == 12'hf0f)begin
    out_to_ADC_chn_Select <= USB_COMMAND[1:0];
    LED[1:0] <= ~USB_COMMAND[1:0];//暂时先不用灯，等USB测试好了再用灯
  end
  /*else if(fifo_rden && USB_COMMAND == 16'hf0f1)
    out_to_usb_Acq_Start_Stop <= 1'b0;*/
  else
    out_to_usb_Acq_Start_Stop <= out_to_usb_Acq_Start_Stop;
end
//clear usb data fifo a0f0
always @ (posedge clk , negedge reset_n) begin
  if(~reset_n)
    out_to_rst_usb_data_fifo <= 1'b0;
  else if(fifo_rden && USB_COMMAND == 16'ha0f0)
    out_to_rst_usb_data_fifo <= 1'b1;
  else
    out_to_rst_usb_data_fifo <= 1'b0;
end
//led interface
always @ (posedge clk , negedge reset_n) begin
  if(~reset_n)
    LED[4:2] <= 3'b111;
  else if(fifo_rden && USB_COMMAND[15:4] == 12'hB00)
    LED[4:2] <= USB_COMMAND[2:0];
  else
    LED[4:2] <= LED[4:2];
end


endmodule
