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
		
      output reg [1:0] Channel_Select,
      /*-------clear usb fifo------------*/
      output reg out_to_rst_all_fifo, //asynchronized reset
      /*-------LED test------------------*/
      output reg [3:0] LED
    );
wire [15:0] USB_COMMAND;
reg fifo_rden;
wire fifo_empty;
//wire fifo_full;
usb_cmd_fifo usbcmdfifo_16depth (
  	.aclr(~reset_n),
	.wrclk(~IFCLK),
	.wrreq(in_from_usb_Ctr_rd_en),
	.data(in_from_usb_ControlWord),	
	.rdclk(~clk),
	.rdreq(fifo_rden),
	.q(USB_COMMAND),
	.rdempty(fifo_empty),
	.wrfull()
);
//read process
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
//ADC channel select
always @ (posedge clk , negedge reset_n) begin
	if(~reset_n) 
		Channel_Select <= 2'b00;
	else if(fifo_rden && USB_COMMAND == 16'hf000)
		Channel_Select <= 2'b00; //turn off all channels
	else if(fifo_rden && USB_COMMAND == 16'hf001)
		Channel_Select <= 2'b01; //only select channel 1
	else if(fifo_rden && USB_COMMAND == 16'hf002)
		Channel_Select <= 2'b10; //only select channel 2
	else if(fifo_rden && USB_COMMAND == 16'hf003)
		Channel_Select <= 2'b11; //select all channels
	else
		Channel_Select <= Channel_Select;
end
//clear all fifo
always @ (posedge clk , negedge reset_n) begin
  if(~reset_n)
    out_to_rst_all_fifo <= 1'b0;
  else if(fifo_rden && USB_COMMAND == 16'hA000)
    out_to_rst_all_fifo <= 1'b1;
  else
    out_to_rst_all_fifo <= 1'b0;
end
//led interface
always @ (posedge clk , negedge reset_n) begin
  if(~reset_n)
    LED <= 4'b1111;
  else if(fifo_rden && USB_COMMAND[15:4] == 12'hB00)
    LED <= USB_COMMAND[3:0];
  else
    LED <= LED;
end
endmodule
