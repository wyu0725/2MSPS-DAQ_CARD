`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:32:05 07/08/2015 
// Design Name: 
// Module Name:    usb_synchronous_slavefifo 
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
module usb_synchronous_slavefifo(
    input IFCLK,
    input FLAGA,//EP6 Empty flag
    input FLAGB,//EP6 full flag
    input FLAGC, //EP2 Empty flag
    output nSLCS, //Chip select
    output reg nSLOE,//READ
    output reg nSLRD,//READ
    output reg nSLWR,    //WRITE
    output reg nPKTEND,  //WRITE
    output [1:0] FIFOADR,
    inout [15:0] FD_BUS,
    /*----interface with control---*/
    input Acq_Start_Stop, //from clk domain
    output reg Ctr_rd_en,
    output reg [15:0] ControlWord,
    /*----interface with external fifo---*/
    input [15:0] in_from_ext_fifo_dout,
    input in_from_ext_fifo_empty,
    input [11:0] in_from_ext_fifo_rd_data_count,
    output reg out_to_ext_fifo_rd_en
    );
    /*--------Chip select---------------*/
    assign nSLCS = 1'b0;
    /*--------EP address define---------*/
    localparam EP6_ADDR = 2'b10;
    localparam EP2_ADDR = 2'b00;
    /*-------SlaveFifo Read process-----*/
    localparam [1:0] READ_IDLE = 2'b00,
                     READ_CHECK= 2'b01,
                     READ_START = 2'b10,
                     READ_PROCESS = 2'b11;
    reg [1:0] READ_State = READ_IDLE;
    always @ (posedge IFCLK) begin
      case(READ_State)
        READ_IDLE:begin
          ControlWord <= 16'b0;
          Ctr_rd_en <= 1'b0;
          nSLOE <= 1'b1;
          nSLRD <= 1'b1;
          READ_State <= READ_CHECK;
        end
        READ_CHECK:begin
          Ctr_rd_en <= 1'b0;
          if(!FLAGC) begin //wait for EP2 address settle
            READ_State <= READ_START;
          end
          else
            READ_State <= READ_CHECK;
        end
        READ_START:begin
          nSLOE <= 1'b0;
          nSLRD <= 1'b0;
          READ_State <= READ_PROCESS;
        end
        READ_PROCESS:begin
          Ctr_rd_en <= 1'b1;
          ControlWord <= FD_BUS;
          nSLOE <= 1'b1;
          nSLRD <= 1'b1;
          READ_State <= READ_CHECK;
        end
        /*
        READ_DONE:begin
          Ctr_rd_en <= 1'b0;
          ControlWord <= 16'b0;
          READ_State <= READ_CHECK;
        end
        */
        default:
          READ_State <= READ_IDLE;
      endcase
    end
    /*--------synchronized Acq_Start_Stop in IFCLK domain-----*/
    reg Acq_Start_Stop_sync1 = 1'b0;
    reg Acq_Start_Stop_sync2 = 1'b0;
    always @ (posedge IFCLK) begin
      Acq_Start_Stop_sync1 <= Acq_Start_Stop;
      Acq_Start_Stop_sync2 <= Acq_Start_Stop_sync1;
    end
    /*--------Slavefifo Write process-------*/
    localparam [2:0] WR_IDLE = 3'd0,
                     WR_STATE = 3'd1,
                     WR_STEP1 = 3'd2,
                     WR_STEP2 = 3'd3,
                     WR_PKTEND = 3'd4;
    reg [2:0] WRITE_State = WR_IDLE;
    reg [15:0] FD_BUS_OUT = 16'b0;
    always @ (posedge IFCLK) begin
      case(WRITE_State)
        WR_IDLE:begin
          nSLWR <= 1'b1;
          nPKTEND <= 1'b1;
          out_to_ext_fifo_rd_en <= 1'b0;
          if(Acq_Start_Stop_sync2 && FLAGC && in_from_ext_fifo_rd_data_count >= 12'd256) //make sure usb is not in read mode and Acq start
            WRITE_State <= WR_STATE;
          else
            WRITE_State <= WR_IDLE;
        end
        WR_STATE:begin
          if(!Acq_Start_Stop_sync2)begin //when write operation is terminated
            if(!FLAGA & !FLAGB)    //if EP6 is not empty either not full,remain data in EP6 should be upload
              WRITE_State <= WR_PKTEND;
            else if(FLAGA) //if EP6 is empty return to idle
              WRITE_State <= WR_IDLE;
            else           //if EP6 is full,drive data on the bus,then turn to pktend
              WRITE_State <= WR_IDLE;
          end
          else begin //normal acq is running
            if(!in_from_ext_fifo_empty && !FLAGB) begin//external fifo is not empty and EP6 is not full
              WRITE_State <= WR_STEP1;
              out_to_ext_fifo_rd_en <= 1'b1;         //read the external fifo
            end
            else
              WRITE_State <= WR_STATE;
          end
        end
        WR_STEP1:begin //drive data on the bus
          out_to_ext_fifo_rd_en <= 1'b0;
          //FD_BUS_OUT <= in_from_ext_fifo_dout;
          FD_BUS_OUT <= Swap(in_from_ext_fifo_dout);
          //FD_BUS_OUT <= {in_from_ext_fifo_dout[7:0],in_from_ext_fifo_dout[15:8]};
          nSLWR  <= 1'b0;//assert SLWR
          WRITE_State <= WR_STEP2;
        end
        WR_STEP2:begin //deassert SLWR,if more data to write turn to WR_STATE
          nSLWR <= 1'b1; 
          WRITE_State <= WR_STATE;
        end
        WR_PKTEND:begin
          nPKTEND <= 1'b0;
          WRITE_State <= WR_IDLE;
        end
        default:WRITE_State <= WR_IDLE;
      endcase
    end
    /*-------assignment------------------------*/
    assign FIFOADR = FLAGC ? EP6_ADDR : EP2_ADDR;
    assign FD_BUS = FLAGC ? FD_BUS_OUT : 16'bz;
    /*********************************************/
    function [15:0] Swap(input [15:0] num);//swap high byte and low byte
      begin:swap
        Swap = {num[7:0],num[15:8]};
      end
    endfunction
endmodule
