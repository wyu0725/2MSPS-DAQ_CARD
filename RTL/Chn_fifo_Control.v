//Deassert the wrreq signal in the same clock cycle when the full signal is asserted.
//Deassert the rdreq signal in the same clock cycle when the empty signal is asserted.
//
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
reg chn1_fifo_rdreq;
reg [15:0] chn1_out_to_usb_fifo;
reg [10:0] chn1_fifo_usedw;
sync_fifo chn1_fifo
(
	aclr(~reset_n | rst_all_fifo),
	clock(clk),
	data(chn1_Dataout),
	wrreq(chn1_Dataout_en & (!chn2_fifo_full)),
	empty(chn1_fifo_empty),
	full(chn1_fifo_full),
	rdreq(chn1_fifo_rdreq),  
	q(chn1_out_to_usb_fifo),
	usedw(chn1_fifo_usedw)
);
//chn2
reg chn2_fifo_empty;
reg chn2_fifo_full;
reg chn2_fifo_rdreq;
reg [15:0] chn2_out_to_usb_fifo;
reg [10:0] chn2_fifo_usedw;
sync_fifo chn2_fifo
(
	aclr(~reset_n | rst_all_fifo),
	clock(clk),
	data(chn2_Dataout),
	wrreq(chn2_Dataout_en & (!chn2_fifo_full)),
	empty(chn2_fifo_empty),
	full(chn2_fifo_full),
	rdreq(chn2_fifo_rdreq),  
	q(chn2_out_to_usb_fifo),
	usedw(chn2_fifo_usedw)
);
always @ (posedge clk , negedge reset_n) begin
  if(!reset_n) begin
    chn1_fifo_empty = 1'b0;
    chn1_fifo_full = 1'b0;
    chn1_rdreq = 1'b0;
    [15:0] chn1_out_to_usb_fifo = 16'h0;
    [10:0] chn1_usedw = 11'b000_0000_0000;
    chn2_fifo_empty = 1'b0;
    chn2_fifo_full = 1'b0;
    chn2_rdreq = 1'b0;
    [15:0] chn2_out_to_usb_fifo = 16'h0000;
    [10:0] chn2_usedw = 11'b000_0000_0000;
  end
end 
//选择读取哪一个FIFO的数据，每次读完一个FIFO后就读另外一个FIFO
parameter Chn1_fifo_selected = 1'b0;
          Chn2_fifo_selected = 1'b1;
reg Select_State;
reg fifo_rdreq;
//reg fifo_full;
//reg fifo_empty;
reg [15:0] fifo_buffer;
reg [10:0] fifo_usedw;
always @ (posedge clk , negedge reset_n) begin
  if (~reset_n) begin
    Select_State <= Chn1_fifo_selected;
    fifo_rdreq <= 1'b0;
    //fifo_full <= 1'b0;
    //fifo_empty <= 1'b0;
    fifo_buffer <= 16'h0;
    fifo_usedw <= 11'b0;
  end
  else begin
    case (Select_State)
      Chn1_fifo_selected:begin
        chn1_fifo_rdreq <= fifo_rdreq;
        //fifo_full <= chn1_fifo_full;
        //fifo_empty <= chn1_fifo_empty;
        fifo_buffer <= chn1_out_to_usb_fifo;
        fifo_usedw <= chn1_fifo_used;
      end
      Chn2_fifo_selected:begin 
        chn2_fifo_rdreq <= fifo_rdreq;
        //fifo_full <= chn2_fifo_full;
        //-fifo_empty <= chn2_fifo_empty;
        fifo_buffer <= chn2_out_to_usb_fifo;
        fifo_usedw <= chn2_fifo_usedw;
      end 
  end
//fifo读取操作
parameter fifo_read_num = 10'd1023;//每次读fifo的一半容量，读其中一个fifo时保证另外一个fifo不要装满
reg [9:0] fifo_read_cnt;//
parameter [2:0] IDLE = 3'd0;
                CHECK = 3'd1;
                WAIT = 3'd2;
                READ = 3'd3;
                WAIT_DONE = 3'd4;
                DONE = 3'd5;
reg [2:0] State;
always @ (posedge clk , negedge reset_n) begin
  if(~reset_n) begin
    fifo_rdreq <=  1'b0;
    fifo_usedw <= 11'd0;
    fifo_buffer <= 16'h0;
  end
  else begin
    case(State)
      IDLE:begin
        fifo_read_cnt <= 10'b0;
        State <= CHECK;
      end
      CHECK:begin
        if(fifo_usedw > fifo_read_num-1) begin
          fifo_rdreq <= 1'b1;//发出读的信号
          fifo_read_cnt <= 1'b0;
          State <= WAIT;
        end
        else State <= CHECK;
      end
      WAIT:State <= READ;//等待一周期，使得fifo_rdreq信号到达rdreq
      READ:begin
        if(fifo_read_cnt < fifo_read_num)begin
          out_to_usb_ext_fifo_en <= 1'b1;
          out_to_usb_ext_fifo_din <= fifo_buffer;
          fifo_read_cnt <= fifo_read_cnt + 1'b1;
        end
        else begin
          out_to_usb_ext_fifo_en <= 1'b0;
          fifo_rdreq <= 1'b0;
          fifo_read_cnt <= 10'd0;
          State <= WAIT_DONE;
        end
      end
      WAIT_DONE:State <= DONE;
      DONE:begin
        Select_State <= ~Select_State;
        State <= CHECK;
      end
      default:State <= IDLE;
  end
end
endmodule
