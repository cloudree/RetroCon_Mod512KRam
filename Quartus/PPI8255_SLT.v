module PPI8255_SLT(
	input RST,
	input [1:0] A,
	input CSb,
	input RDb,
	input WRb,
	input MREQb,
	input RFSHb,
	input SEL_PPI,
	input [1:0] PAGE,
	
	input [7:0] DIN,
	
	input [7:0] PB,
	output reg [3:0] SLTb,
	output [7:0] PC,
	

	
	output reg [7:0] DOUT
);

	reg [7:0] REGA;
	//reg [7:0] REGB;
	reg [7:0] REGC;

	reg [7:0] regCTRL;	// Mode Definition Register
	
	// assign PA = REGA;
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
			//REGB = 8'h00;
			REGC = 8'h00;
		end
		else if (~CSb)
			begin
				case ({A,DIN[7]})
					3'b000: REGA = DIN;
					//3'b010: REGB = DIN;
					3'b100: REGC = DIN;
					3'b110: REGC[ DIN[3:1] ] = DIN[0];
					
					3'b001: REGA = DIN;
					//3'b011: REGB = DIN;
					3'b101: REGC = DIN;
					3'b111: regCTRL = DIN;
					
				endcase
			end
	end
	
	reg [1:0] YPA;	// Slot MUX
		reg EN153;
		
		always @(*)	// EN153 Latch
		begin
			if (RST)
				EN153 = 1'b0;
			else
				if( SEL_PPI)
					EN153 = 1'b1;
		end
		
		
		always @(*)
		begin
			if (EN153)
			begin
				case (PAGE)
					2'b00: YPA = REGA[1:0];
					2'b01: YPA = REGA[3:2];
					2'b10: YPA = REGA[5:4];
					2'b11: YPA = REGA[7:6];
				endcase
			end
			else
				YPA = 2'b00;
		end
		
		assign ENSLT = ~MREQb & RFSHb;
		
		always @(*)
		begin
			if (ENSLT)
				case (YPA)
					2'b00: SLTb = 4'b1110;
					2'b01: SLTb = 4'b1101;
					2'b10: SLTb = 4'b1011;
					2'b11: SLTb = 4'b0111;
				endcase
			else	
				case (YPA)
				2'b00: SLTb = 4'b1111;
				2'b01: SLTb = 4'b1111;
				2'b10: SLTb = 4'b1111;
				2'b11: SLTb = 4'b1111;
			endcase
		end
	
	
	
	
endmodule