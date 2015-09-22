module Chn_fifo_Control
(
  input clk,
  input reset_n,
  input rst_all_fifo,
  input [15:0] chn1_Dataout,
  input chn1_Dataout_en,
  input [15:0] chn2_Dataout,
  input chn2_Dataout_en,
  output reg [15:0] out_to_usb_ext_fifo_din,
  output reg out_to_usb_ext_fifo_en
);
//chn1
reg chn1_fifo_empty;
reg chn1_fifo_full;
reg chn1_rdreq;
reg [15:0] chn1_out_to_usb_fifo;
reg [10:0] chn1_usedw;
sync_fifo chn1_fifo
(
	aclr(~reset_n | rst_all_fifo),
	clock(clk),
	data(chn1_Dataout),
	wrreq(chn1_Dataout_en),
	empty(chn1_fifo_empty),
	full(chn1_fifo_full),
	rdreq(chn1_rdreq),  
	q(chn1_out_to_usb_fifo),
	usedw(chn1_usedw)
);
//chn2
reg chn2_fifo_empty;
reg chn2_fifo_full;
reg chn_rdreq;
reg [15:0] chn2_out_to_usb_fifo;
reg [10:0] chn2_usedw;
sync_fifo chn2_fifo
(
	aclr(~reset_n | rst_all_fifo),
	clock(clk),
	data(chn2_Dataout),
	wrreq(chn2_Dataout_en),
	empty(chn2_fifo_empty),
	full(chn2_fifo_full),
	rdreq(chn2_rdreq),  
	q(chn2_out_to_usb_fifo),
	usedw(chn2_usedw)
);
always @ (posedge clk , negedge reset_n) begin
  if(!reset_n) begin
    chn1_fifo_empty = 1'b0;
    chn1_fifo_full = 1'b0;
    chn1_rdreq = 1'b0;
    [15:0] chn1_out_to_usb_fifo = 16'h0000;
    [10:0] chn1_usedw = 11'b000_0000_0000;
    chn2_fifo_empty = 1'b0;
    chn2_fifo_full = 1'b0;
    chn2_rdreq = 1'b0;
    [15:0] chn2_out_to_usb_fifo = 16'h0000;
    [10:0] chn2_usedw = 11'b000_0000_0000;
  end
end 



endmodule
