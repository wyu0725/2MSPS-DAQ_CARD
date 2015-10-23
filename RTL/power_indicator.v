module power_indicator
(
  input reset_n,
  output reg PW_LED
);
always @ (*)begin
  if(!reset_n)
    PW_LED = 1'b1;
  else
    PW_LED = 1'b0;
end
endmodule
