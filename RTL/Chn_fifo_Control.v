//QuartusII 15.0
//University of Science and Technology of China
//Junbin Zhang
//discriptions:
//USB interface read data according to Channel_Select inputs
//Channel_Select = 2'b00, no channels selected, read nothing 
//Channel_Select = 2'b01, only channel_1 selected, reading channel1's data
//Channel_Select = 2'b10, only channel_2 selected, reading channel2's data
//Channel_Select = 2'b11, all channels selected, first read 1024 words of
//channel1,then read 1024 words of channel2,again and again until stoped. 

//Channel 1 packect starts at AAAA (end with 55aa if stopped)
//Channel 2 packect starts at BBBB (end with 55aa if stopped)
//All Channels packet: AAAA (1024 words) 55aa BBBB (1024 words) 55aa (end with FFFF if stopped)
module Chn_fifo_Control
(
  input clk,
  input reset_n,
  input rst_all_fifo,
  input [1:0] Channel_Select,
  input [15:0] chn1_Dataout,
  input chn1_Dataout_en,
  input [15:0] chn2_Dataout,
  input chn2_Dataout_en,
  output reg [15:0] out_to_usb_ext_fifo_din,
  output reg out_to_usb_ext_fifo_en
);
/*---------Channel1 fifo instantiation------*/
wire chn1_fifo_empty;
wire chn1_fifo_full;
reg chn1_fifo_rdreq;
wire [15:0] chn1_out_to_usb_fifo;
//wire [10:0] chn1_fifo_usedw;
sync_fifo chn1_fifo
(
	.aclr(~reset_n | rst_all_fifo),
	.clock(~clk),
	.data(chn1_Dataout),
	.wrreq(chn1_Dataout_en & (!chn1_fifo_full)),
	.empty(chn1_fifo_empty),
	.full(chn1_fifo_full),
	.rdreq(chn1_fifo_rdreq),  
	.q(chn1_out_to_usb_fifo)
	//.usedw(chn1_fifo_usedw) //no use
);
/*--------Channel2 fifo instantiation-------*/
wire chn2_fifo_empty;
wire chn2_fifo_full;
reg chn2_fifo_rdreq;
wire [15:0] chn2_out_to_usb_fifo;
//wire [10:0] chn2_fifo_usedw;
sync_fifo chn2_fifo
(
	.aclr(~reset_n | rst_all_fifo),
	.clock(~clk),
	.data(chn2_Dataout),
	.wrreq(chn2_Dataout_en & (!chn2_fifo_full)),
	.empty(chn2_fifo_empty),
	.full(chn2_fifo_full),
	.rdreq(chn2_fifo_rdreq),  
	.q(chn2_out_to_usb_fifo)
	//.usedw(chn2_fifo_usedw) //no use
);
/*-------------------------------------------------*/
localparam NO_CHANNELS = 2'b00;
localparam CHANNEL_1 = 2'b01;
localparam CHANNEL_2 = 2'b10;
localparam ALL_CHANNELS = 2'b11;
localparam WORD_1024 = 11'd1024;
localparam [4:0] Idle = 5'd0,
        //channel 1 States
        ONLY_CHANNEL1 = 5'd1,
        READ_CHANNEL1 = 5'd2,
        WRITE_CHANNEL1= 5'd3,
        END_CHANNEL1  = 5'd4,
        //channel 2 States
        ONLY_CHANNEL2 = 5'd5,
        READ_CHANNEL2 = 5'd6,
        WRITE_CHANNEL2= 5'd7,
        END_CHANNEL2  = 5'd8,
        //channel all States
        ALL_CHANNEL   = 5'd9,
        START_CHANNEL1= 5'd10,
   FIRST_READ_CHANNEL1= 5'd11,
  FIRST_WRITE_CHANNEL1= 5'd12,
    END_FIRST_CHANNEL1= 5'd13,
        START_CHANNEL2= 5'd14,
  SECOND_READ_CHANNEL2= 5'd15,
 SECOND_WRITE_CHANNEL2= 5'd16,
   END_SECOND_CHANNEL2= 5'd17,
       END_ALL_CHANNEL= 5'd18;
reg [4:0] State;
reg [10:0] word_cnt;
/*-----------------fsm--------------------------*/
always @ (posedge clk , negedge reset_n) begin
  if(~reset_n) begin
    out_to_usb_ext_fifo_din <= 16'b0;
    out_to_usb_ext_fifo_en <= 1'b0;
    chn1_fifo_rdreq <= 1'b0;
    chn2_fifo_rdreq <= 1'b0;
    word_cnt <= 11'b0;
    State <= Idle;
  end
  else begin
    case(State)
      Idle:begin
        out_to_usb_ext_fifo_en <= 1'b0;
        case(Channel_Select)
          NO_CHANNELS:State <= Idle;          //no channel selected,return to Idle
          CHANNEL_1:State <= ONLY_CHANNEL1;   //only selected channel 1
          CHANNEL_2:State <= ONLY_CHANNEL2;   //only selected channel 2
          ALL_CHANNELS:State <= ALL_CHANNEL;  //all channels selected
        endcase
      end
      /*-------channel 1-----------*/
      ONLY_CHANNEL1:begin
        out_to_usb_ext_fifo_en <= 1'b1;     //write chn1 header to usb fifo
        out_to_usb_ext_fifo_din <= 16'hAAAA;//AAAA represent channel 1
        State <= READ_CHANNEL1;
      end
      READ_CHANNEL1:begin
        out_to_usb_ext_fifo_en <= 1'b0;
        if(Channel_Select != CHANNEL_1)  
          State <= END_CHANNEL1;       
        else if(chn1_fifo_empty)
          State <= READ_CHANNEL1; //stay here wait for data
        else begin
          chn1_fifo_rdreq <= 1'b1;
          State <= WRITE_CHANNEL1;
        end
      end
      WRITE_CHANNEL1:begin
        chn1_fifo_rdreq <= 1'b0;
        out_to_usb_ext_fifo_en <= 1'b1; //write data to usb fifo
        out_to_usb_ext_fifo_din <= chn1_out_to_usb_fifo;
        State <= READ_CHANNEL1; //if more data to be writed return to ONLY_CHANNEL1;
      end
      END_CHANNEL1:begin
        out_to_usb_ext_fifo_en <= 1'b1;   //write chn1 header to usb fifo
        out_to_usb_ext_fifo_din <= 16'h55AA;
        State <= Idle; //back to Idle
      end
      /*--------channel 2-----------*/
      ONLY_CHANNEL2:begin
        out_to_usb_ext_fifo_en <= 1'b1;     //write chn1 header to usb fifo
        out_to_usb_ext_fifo_din <= 16'hBBBB;//BBBB represent channel 2
        State <= READ_CHANNEL2;
      end
      READ_CHANNEL2:begin
        out_to_usb_ext_fifo_en <= 1'b0;
        if(Channel_Select != CHANNEL_2)
          State <= END_CHANNEL2; 
        else if(chn2_fifo_empty)
          State <= READ_CHANNEL2; //stay here wait for data
        else begin
          chn2_fifo_rdreq <= 1'b1;
          State <= WRITE_CHANNEL2;
        end
      end
      WRITE_CHANNEL2:begin
        chn2_fifo_rdreq <= 1'b0;
        out_to_usb_ext_fifo_en <= 1'b1; //write data to usb fifo
        out_to_usb_ext_fifo_din <= chn2_out_to_usb_fifo;
        State <= READ_CHANNEL2; //if more data to be writed return to ONLY_CHANNEL1;
      end
      END_CHANNEL2:begin
        out_to_usb_ext_fifo_en <= 1'b1;   //write chn1 header to usb fifo
        out_to_usb_ext_fifo_din <= 16'h55AA;
        State <= Idle; //back to Idle
      end
      /*--------all channel----------*/
      ALL_CHANNEL:begin   //if all channels select, first read out 1024 words from channel1, then channel2.
        out_to_usb_ext_fifo_en <= 1'b0;
        if(Channel_Select != ALL_CHANNELS)//Modified
          State <= END_ALL_CHANNEL;       //
        else
          State <= START_CHANNEL1;
      end
      //channel1
      START_CHANNEL1:begin
        out_to_usb_ext_fifo_en <= 1'b1;     //write chn1 header to usb fifo
        out_to_usb_ext_fifo_din <= 16'hAAAA;//AAAA represent channel 1
        State <= FIRST_READ_CHANNEL1;        
      end
      FIRST_READ_CHANNEL1:begin   
        out_to_usb_ext_fifo_en <= 1'b0;
        //else if(chn1_fifo_usedw < WORD_1024)
       if(chn1_fifo_empty) begin
          if(Channel_Select != ALL_CHANNELS) //when stop the ADC,jump out of this state,//modified
            State <= END_ALL_CHANNEL;
          else
            State <= FIRST_READ_CHANNEL1; //wait here
        end
        else if(word_cnt == WORD_1024) begin
          word_cnt <= 11'b0;
          State <= END_FIRST_CHANNEL1;
        end
        else begin //read channel 1
          chn1_fifo_rdreq <= 1'b1;
          State <= FIRST_WRITE_CHANNEL1;
        end
      end
      FIRST_WRITE_CHANNEL1:begin
        chn1_fifo_rdreq <= 1'b0;
        out_to_usb_ext_fifo_en <= 1'b1; //write data to usb fifo
        out_to_usb_ext_fifo_din <= chn1_out_to_usb_fifo;
        word_cnt <= word_cnt + 1'b1;
        State <= FIRST_READ_CHANNEL1;
      end
      END_FIRST_CHANNEL1:begin
        out_to_usb_ext_fifo_en <= 1'b1;     //write chn1 header to usb fifo
        out_to_usb_ext_fifo_din <= 16'h55AA;
        State <= START_CHANNEL2;        
      end
      //channel2
      START_CHANNEL2:begin
        out_to_usb_ext_fifo_din <= 16'hBBBB;//BBBB represent channel 2    
        State <= SECOND_READ_CHANNEL2;
      end
      SECOND_READ_CHANNEL2:begin
        out_to_usb_ext_fifo_en <= 1'b0;
       if(chn2_fifo_empty) begin
          if(Channel_Select != ALL_CHANNELS) //when stop the ADC,jump out of this state,//modified
            State <= END_ALL_CHANNEL;
          else
            State <= SECOND_READ_CHANNEL2; //wait here
        end
        else if(word_cnt == WORD_1024) begin
          word_cnt <= 11'b0;
          State <= END_SECOND_CHANNEL2;
        end
        else begin //read channel 2
          chn2_fifo_rdreq <= 1'b1;
          State <= SECOND_WRITE_CHANNEL2;
        end        
      end
      SECOND_WRITE_CHANNEL2:begin
        chn2_fifo_rdreq <= 1'b0;
        out_to_usb_ext_fifo_en <= 1'b1; //write data to usb fifo
        out_to_usb_ext_fifo_din <= chn2_out_to_usb_fifo;
        word_cnt <= word_cnt + 1'b1;
        State <= SECOND_READ_CHANNEL2;        
      end
      END_SECOND_CHANNEL2:begin
        out_to_usb_ext_fifo_en <= 1'b1;     //write chn1 header to usb fifo
        out_to_usb_ext_fifo_din <= 16'h55AA;
        State <= ALL_CHANNEL;      
      end
      END_ALL_CHANNEL:begin
        out_to_usb_ext_fifo_en <= 1'b1;     //write chn1 header to usb fifo
        out_to_usb_ext_fifo_din <= 16'hFFFF;
        State <= Idle;            
      end
      default:State <= Idle;
    endcase
  end
end
endmodule
