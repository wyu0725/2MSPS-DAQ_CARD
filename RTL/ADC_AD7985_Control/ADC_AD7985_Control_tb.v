`timescale 1ns/1ns
module ADC_AD7985_Control_tb;
reg clk;
reg reset_n;
reg iRunStart;
reg SDO;
wire TURBIO;
wire CNV;
wire SCK;
wire [15:0] Dataout;
wire Dataout_en;
ADC_AD7985_Control uut (
  .clk(clk),
  .reset_n(reset_n),
  .iRunStart(iRunStart),
  .SDO(SDO),
  .TURBIO(TURBIO),
  .CNV(CNV),
  .SCK(SCK),
  .Dataout(Dataout),
  .Dataout_en(Dataout_en)
);
//initial
parameter PEROID = 20;
initial begin  
  clk = 1'b0;
  reset_n = 1'b0;
  iRunStart = 1'b0;
  SDO = 1'bz;
  #(100);
  reset_n = 1'b1;
  iRunStart = 1'b1;
  #(70);//CNV turn low
  SDO = 1'b0;
  #(10);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b1;//读完了
  #(5*PEROID);
  #(PEROID/2);
  SDO = 1'bz;
  #(4*PEROID);  
  //2新的数据
  SDO = 1'b0;
  #(10);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b1;//读完了
  #(5*PEROID);
  #(PEROID/2);
  SDO = 1'bz;
  #(4*PEROID); 
  //3新的数据
  SDO = 1'b0;
  #(10);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b1;
  #(PEROID);
  SDO = 1'b0;
  #(PEROID);
  SDO = 1'b1;//读完了
  #(5*PEROID);
  #(PEROID/2);
  SDO = 1'bz;


end
always #(PEROID/2) clk = ~clk;
endmodule
