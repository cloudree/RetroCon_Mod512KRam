module slotExp (	
	input RSTb,
	input ADFFFF,
	input SLTSL,
	input WRb,
	input [7:0] DIN,
	input [1:0] PAGE,
	
	output [7:0] DOUT,
	
	output reg [3:0] subSLT,
	output outSSREG
		);
		
	reg [7:0] regSS;
	reg [1:0] BSEL;
	
	always @(negedge WRb or negedge RSTb)
	if (~RSTb)
		regSS <= 8'h00;
	else
		if (ADFFFF & SLTSL)
			regSS <= DIN;
			
	assign DOUT = ~regSS;
	
	assign outSSREG = SLTSL & ADFFFF;
	
	always @(*)
	begin
		case (PAGE)
			2'b00: BSEL = regSS[1:0];
			2'b01: BSEL = regSS[3:2];
			2'b10: BSEL = regSS[5:4];
			2'b11: BSEL = regSS[7:6];
		endcase
	end
	
	always @(*)
	begin
	if (SLTSL)
		case (BSEL)
			2'b00: subSLT = 4'b0001;
			2'b01: subSLT = 4'b0010;
			2'b10: subSLT = 4'b0100;
			2'b11: subSLT = 4'b1000;
		endcase
	else
		subSLT = 4'b0000;
	end
		
endmodule