// Project: MSX2 Compatible Game Console
// Created by Kevin Cho
// Santa Clara, USA
// ckevin@hanmail.net
// Under GNU GPL 3.0 Lincense

module ramMapper (
	input RSTb,
	input [4:0] DIN,
	input IOMM,			// Mapper IO Asserted  FC thru FFh
	input WRb,
	input [1:0] RN,	// Mapper Designator
	input [1:0] PAGE,		// Page 
	
	output reg [7:0] DOUT,
	output reg [7:0] MO		// RAM Selector
);
	
	// Memory Mapper
	reg [7:0] regFC, regFD, regFE, regFF;
	
	always @( negedge RSTb or negedge WRb)
	if (~RSTb)
	begin	
		regFC <= 8'b00000000;
		regFD <= 8'b00000001;
		regFE <= 8'b00000010;
		regFF <= 8'b00000011;
	end
	else
		if (IOMM)
		case (RN)
			2'b00: regFC <= DIN;
			2'b01: regFD <= DIN;
			2'b10: regFE <= DIN;
			2'b11: regFF <= DIN;
		endcase	

	// Memory Mapper MUX for reading
	always @(*)
	case (RN)
		2'b00: DOUT = regFC;
		2'b01: DOUT = regFD;
		2'b10: DOUT = regFE;
		2'b11: DOUT = regFF;
	endcase
	
	// Memory Mapper MUX for reading
	always @(*)
	case (PAGE)
		2'b00: MO = regFC;
		2'b01: MO = regFD;
		2'b10: MO = regFE;
		2'b11: MO = regFF;
	endcase

endmodule