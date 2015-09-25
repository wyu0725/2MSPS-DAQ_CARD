//System clock_Generator
//quartusII 15.0
//University of Science and Technology of China
//Junbin Zhang
//20150914
module Clock_Generator
(
  input GCLK,
  input rst_n,
  input usb_ifclk,
  output clk,
  output IFCLK,
  output reset_n
);
//50M clk
clock_buf clk_gen
(
	.inclk(GCLK),
	.outclk(clk)
);
//48M IFCLK
clock_buf IFCLK_gen
(
	.inclk(usb_ifclk),
	.outclk(IFCLK)
);
//Asynchronous reset synchronous release
reg sysrst_nr1,sysrst_nr2;
always @ (posedge clk , negedge rst_n) begin
  if(!rst_n)
    sysrst_nr1 <= 1'b0;
  else
    sysrst_nr1 <= 1'b1;
end
always @ (posedge clk , negedge rst_n) begin
  if(!rst_n)
    sysrst_nr2 <= 1'b0;
  else
    sysrst_nr2 <= sysrst_nr1;
end
assign reset_n = sysrst_nr2; //reset signal generated
endmodule
