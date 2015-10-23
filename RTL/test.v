module test
(
  input clk,
  input reset_n,
  input iRunStart,
  output reg Dataout_en,
  output reg [15:0] Dataout
);
reg [9:0] cnt;
localparam ADC_PERIOD = 10'd23;
localparam OutState = 1'b0;
localparam CountState = 1'b1;
reg State;
always @ (posedge clk , negedge reset_n)begin
  if(~reset_n)begin
    Dataout_en <= 1'b0;
    Dataout <= 16'b0;
    cnt <= 10'b0;
    State <= CountState;
  end
  else begin
    case(State)
      CountState:begin
        if(!iRunStart)
          State <= CountState;
        else if(cnt == ADC_PERIOD)begin
          Dataout_en <= 1'b1;
          cnt <= 10'b0;
          State <= OutState;
        end//end if
        else begin
          cnt <= cnt + 1'b1;
          State <= CountState;
        end//end else
      end//end CountState
      OutState:begin
        Dataout_en <= 1'b0;
        Dataout <= Dataout + 1'b1;
        State <= CountState;
      end//end Out_State
    endcase
  end
end//end always
endmodule
