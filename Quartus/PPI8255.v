module PPI8255(
	input RST,
	input [1:0] A,
	input CSb,
	input RDb,
	input WRb,
	input [7:0] DIN,
	
	input [7:0] PB,
	output [7:0] PA,
	output [7:0] PC,
	
	output reg [7:0] DOUT
);

	reg [7:0] REGA;
	reg [7:0] REGB;
	reg [7:0] REGC;

	reg [7:0] regCTRL;	// Mode Definition Register
	
	assign PA = REGA;
	assign PC = REGC;
	
	always @(*)
	begin
		case (A)
			2'b00: DOUT = REGA;
			2'b01: DOUT = PB;
			2'b10: DOUT = REGC;
			2'b11: DOUT = regCTRL;
		endcase
	end
	
	// Writing 
	always @(posedge RST or posedge WRb)
	begin
		if (RST)
		begin
			regCTRL = 8'h9b;
			REGA = 8'h00;
			REGB = 8'h00;
			REGC = 8'h00;
		end
		else if (~CSb)
			begin
				case ({A,DIN[7]})
					3'b000: REGA = DIN;
					3'b010: REGB = DIN;
					3'b100: REGC = DIN;
					3'b110: REGC[ DIN[3:1] ] = DIN[0];
					
					3'b001: REGA = DIN;
					3'b011: REGB = DIN;
					3'b101: REGC = DIN;
					3'b111: regCTRL = DIN;
					
				endcase
			end
	end
	
	
	
	
	
endmodule