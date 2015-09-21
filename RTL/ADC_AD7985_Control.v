//ADC AD7985 Control
//quartusII 15.0
//University of Science and Technology of China
//Junbin Zhang
//discriptions:
//1. Reading During Conversion, Fast Host(Turbo or Normal Mode)
//--When reading during conversion(n),conversion results are for the previous(n-1) conversion.
//--Reading should be occur only up to tDATA,because this time is limitied the host must use a fast SCK
//--fsck >=(Number_SCK_Edges)/tDATA; Number_SCK_Edges = 16
//--For turbo mode(2.5MSPS), tDATA = 190ns; fsck = 84.2MHz
//--For normal mode(2.0MSPS), tDATA = 290ns; fsck = 55.2MHz
//2. Spilt-Reading, Any Speed Host(Turbo or Normal Mode)
//--To allow for a slower SCK, there is the option of a split read, where data access starts at the current acquisition(n)
//and spans into the conversion(n) Conversion results are for the previous n-1 conversion
//--For turbo mode, fsck = 70MHz;tDATA = 190ns; Number_SCK_Edges = 13.3;Thirteen bits are read during conversion(n)
//and three bits are read during acquisition
//--For normal mode, fsck = 45MHz; tDATA = 290ns; Number_SCK_Edges = 13.05;Thirteen bits are read during conversion(n)
//and three bits are read during acquisition
//3.Reading During Acquisition, Any Speed Host(Turbo or normal)
//When reading during acquisition(n), conversion results are for the previous(n-1) conversion.Maximum throughput
//is achievable in normal mode(2.0MSPS);however, in turbo mode,2.5MSPS throughput is not achievable.
/*----------------design----------------*/
//------- nCS mode；3-wire without busy indicator
//-------Readout mode: 1.During Conversion;2.During Acquisition(in turbo mode,2.5MSPS is not achievable)
//-------Readout mode: Turbo and Normal
//tcyc = tACQ + tCONV; tcyc >= 400ns/500ns 2.5Msps/2Msps
//tACQ >= 80ns, tCONV <= 320/420ns; tQUIET >=20ns;
/*--------------solution1-------------------*/
//----when sampling rate = 1Msps, tcyc = 1000ns, cyc_counter = 1000/20 = 50; acq_counter>=4;conv_counter <= 16/21;tQuIET_count>= 1
//----Read Druing Acquisition，normal mode; 

/*--------------solution2-------------------*/
//----when sampling rate = 2Msps, tcyc = 500ns, cyc_counter = 500/20 = 25; acq_counter>= 4; conv_counter<= 16/21;tQuIET_count>= 1
//----Read Druing Acquisition, normal mode; 

/*--------------solution3-------------------*/
//----when sampling rate = 2.5Msps, tcyc = 400ns, cyc_counter = 20; acq_counter>= 4; conv_counter<= 16/21;
//----Read Druing Conversion,turbo mode; acq_counter = 4, conv_counter = 16;

/*-------This module for solution2---2Msps---*/
module ADC_AD7985_Control #(parameter DATA_WIDTH = 16)
(
	input clk,//50M
	input reset_n,
	input iRunStart, //starts ADC
	//input [1:0] sample_rate,
	input SDO,    //Data out with the clock of SCK
	output TURBIO,//High 2.5MSPS, LOW 2MSPS
	output reg CNV,   //Rising edge start the conversion; Busy indicator:CNV stay low before conversion done; NO indicator:CNV stay high 
	output SCK,    //Serial data output clock
	output reg [15:0] Dataout,
	output reg Dataout_en
);
assign TURBIO = 1'b0;//normal mode
assign SCK = ~clk;   //
reg [4:0] sdo_cnt;
reg [5:0] cnt;
//counter defined
localparam Tconv = 6'd4;
localparam Tcompensation = 6'd5;
localparam [1:0] T_CONVERSION = 2'b00,
					  T_ACQUISION  = 2'b01,
					  T_COMPENSATION = 2'b10;
reg [1:0] State;
always @ (posedge clk , negedge reset_n) begin
	if(~reset_n) begin
		Dataout <= 16'b0;
		Dataout_en <= 1'b0;
		CNV <= 1'b1;
		sdo_cnt <= 5'b0;
		cnt <= 6'b0;
		State <= T_CONVERSION;
	end
	else begin
		case(State)
			/*
			Idle:begin //1
				if(!iRunStart)
					State <= Idle;
				else begin
					CNV <= 1'b1; // a rising edge on CNV initial a conversion, selects \CS mode, and force SDO to high impedance.
					State <= T_CONVERSION;
				end
			end
			*/
			T_CONVERSION:begin //4
				if(!iRunStart)
					State <= T_CONVERSION;
				else if(cnt < Tconv) begin
					cnt <= cnt + 1'b1;
					State <= T_CONVERSION;
				end
				else begin
					cnt <= 6'd0;
					CNV <= 1'b0;
					State <= T_ACQUISION;
				end
			end
			T_ACQUISION:begin //16
				if(sdo_cnt < DATA_WIDTH) begin
					Dataout[DATA_WIDTH - cnt] <= SDO;
					sdo_cnt <= sdo_cnt + 1'b1;
					State <= T_ACQUISION;
				end
				else begin
					sdo_cnt <= 5'b0;
					Dataout_en <= 1'b1;
					State <= T_COMPENSATION;
				end
			end
			T_COMPENSATION:begin //5
				Data_en <= 1'b0;
				if(cnt < Tcompensation) begin
					cnt <= cnt + 1'b1;
					State <= T_COMPENSATION;
				end
				else begin
					cnt <= 6'd0;
					CNV <= 1'b1;					
					State <= T_CONVERSION;
				end
			end
			default:State <= T_CONVERSION;
		endcase
	end
end
endmodule
/*
localparam r_1MSPS = 6'd50;
localparam r_2MSPS = 6'd25;
localparam r_2_5MSPS = 6'd20;
reg [5:0] Rate = r_1MSPS;
always @ (*) begin
	casex(sample_rate)
		2'b00:Rate = r_1MSPS;//1
		2'b01:Rate = r_2MSPS;
		2'b1x:Rate = r_2_5MSPS;
	endcase
end
reg[5:0] cyc_counter;
always @ (posedge clk , negedge reset_n) begin
	if(~reset_n) 
		cyc_counter <= 6'b0;
	else if(!iRunStart || cyc_counter == Rate)
		cyc_counter <= 6'b0;
	else
		cyc_counter <= cyc_counter + 1'b1;
end
*/
//fsm for data output
//assign TURBIO = 1'b0; //normal mode 2Msps
//assign SCK = SCK_en & clk;
//reg [15:0] Dataout;
//reg SCK_en;
//reg Data_en;

