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
wire chn1_fifo_empty;
wire chn1_fifo_full;
reg chn1_rdreq;

sync_fifo chn1_fifo
(
	aclr(~reset_n | rst_all_fifo),
	clock(clk),
	data(chn1_Dataout),
	wrreq(chn1_Dataout_en),
	empty(),
	full(),
	rdreq(),  
	q(),
	usedw()
);
sync_fifo chn2_fifo
(
	aclr(~reset_n | rst_all_fifo),
	clock(clk),
	data(chn2_Dataout),
	wrreq(chn2_Dataout_en),
	empty(),
	full(),
	rdreq(),  
	q(),
	usedw()
);

endmodule
