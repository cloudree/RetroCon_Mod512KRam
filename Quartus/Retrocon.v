// Project: MSX2 Compatible Game Console
// Created by Kevin Cho
// Santa Clara, USA
// ckevin@hanmail.net
// Under GNU GPL 3.0 Lincense

module Retrocon (
	input [15:14] addrH,
	input [7:0] addrL,
	inout [7:0] data,
	input addr13_8b,	// ADDR[13:8] all ones
	
	input RSTb,
	//input CLK,
	input WRb,
	input RDb,
	input IORQb,
	input MREQb,
	input M1b, 
	input VDP_INTb,
	input SLT_INTb,
	input [7:0] PB,		// 8255 Port B for Slot.. Keyboard Input
	input RFSHb,
	
	output CAPS,			// Caps Lock
	output [3:0] keyMAT,	// Keyboard Matrix 
	output PSGBC1,			// PSG BC1 Signal
	output PSGBDIR,		// PSG
	output CK_RTCAL,		// RTC Address
	output RTCCSb,			// RTC Enable Signal
	
	output VDP_CSWb,
	output VDP_CSRb,
	
	output RAM_CSb,		// RAM CS 
	output ROM_OEb,		// ROM OE 
	
	output CPU_INTb,
	output SPK,				// PC7
	output [2:1] SLTbo,
	output PG1RDb,
	output PG2RDb,
	output PG12RDb,
	output [4:0] RAMA,		// RAM Bank Address for Mapper (256KB)
	output reg [2:0] ROMA	// ROM Bank Bits	Total 128KB each 16KB Bank
);

	PPI8255_SLT xPPI(
		.RST(~RSTb),
		.A(addrL[1:0]),
		.CSb(1'b0),
		.RDb( ~SEL_PPI | RDb ),
		.WRb( ~SEL_PPI | WRb),
		.DIN(data),
		.MREQb(MREQb),
		.RFSHb(RFSHb),
		.PB(PB),
		.SLTb(SLTb),
		.PC(PC),
		.SEL_PPI(SEL_PPI),
		.PAGE(addrH),
		
		.DOUT(DOPPI)
	);
	
	ramMapper xrMapper(
		.RSTb(RSTb),
		.DIN(data),
		.IOMM(IOMM),
		.WRb(WRb),
		.RN(addrL[1:0]),
		.PAGE(addrH),
		
		.MO(MMUX),		// Mapper Output for page
		.DOUT(DOMM)
	);

	wire [7:0] DOMM;	// Mapper Data Output
	wire [7:0] MMUX;	// for RAM BAnk Selection
	
	// Expanding the SLOT
	slotExp xsltExp_0(	
		.RSTb(RSTb),
		.ADFFFF(ADFFFF),
		.SLTSL(~SLTb[0]),		// Main Slot into 0-0,0-1,0-2,0-3
		.WRb(WRb),
		.DIN(data),				// Sub Slot Register Input Bus
		.PAGE(addrH[15:14]),
		
		.DOUT(DOSSREG),		// Sub Slot Register Data Output Bus	
		.subSLT(SLT0SS),		// Sub Slot Signals
		.outSSREG(outSSREG)	// Sub Slot Register Output Enable
	);
	
	wire [7:0] PC, DOPPI;	// DOPPI = 8255 DATA OUTPUT BUS
	wire [3:0] SLT0SS;	// Slot0 Sub-slot Signals
	wire [7:0] DOSSREG;	// Slot0 Expander Register
	wire [3:0] SLTb;
	
	reg [1:0] sysREG;
	
	assign SPK = PC[7];
	assign CAPS = ~PC[6];
	assign IORQ = ~IORQb;
	assign ADFFFF = (addrH == 2'b11) & (addrL == 8'hff) & ~addr13_8b;
	
	// IO Space Decoder
	assign IOC2F = IORQ & addrL[7] & addrL[6] & M1b;	// IO C0h thru CFh
	assign IO82B = IORQ & addrL[7] & ~addrL[6] & M1b;  // IO  80h thru BFh   
	
	// IO Space 80h thru BFh
	assign IO98 = IO82B & ( addrL[5:3] == 3'b011);    // VDP
	assign IOA0 = IO82B & ( addrL[5:3] == 3'b100);    // PSG
	assign IOA8 = IO82B & ( addrL[5:3] == 3'b101);    // PPI
	assign IOB0 = IO82B & ( addrL[5:3] == 3'b110);    // RTC
	assign IOB8 = IO82B & ( addrL[5:3] == 3'b111);    // 
	
	assign SEL_PPI = IOA8;
	assign SEL_PSG = IOA0;
	assign SEL_RTC = IOB0;
	assign SEL_VDP = IO98;
	
	// IO Space C0h thru CFh;
	assign IOF0 = IOC2F & ( addrL[5:3] == 3'b110);	// IOSYS
	assign IOSYS = IOF0;

	// RTC 
	assign CLK_IOSYS = WRb | ~IOSYS | ~(addrL[2:0] == 3'b101);	// IOSYS(f5h) bit Setting Clock 
	always @(negedge RSTb or posedge CLK_IOSYS)
	if (~RSTb)
		sysREG = 2'b00;
	else	
		sysREG = {data[7], data[0]};	// {RTCEN, KROMEN} bits
	
	assign RTCEN = sysREG[1];
	assign RTCDEC = RTCEN & IOB0 & ( addrL[2:1] == 2'b10);
	assign RTCCSb = ~(RTCDEC & addrL[0]);	// IO B5h for RTC CS
	assign CK_RTCAL = RTCDEC  & ~addrL[0] & WRb;	// B4h for RTC Address Latch Clock

	// Slot Signal Generator
	assign SLTbo[2:1] = SLTb[2:1];
	
	// Slot Page 12,1,2,0
	assign PG12RDb = PG1RDb & PG2RDb;
	assign PG1RDb = ~(~addrH[15] & addrH[14] & ~RDb);
	assign PG2RDb = ~(~addrH[14] & addrH[15] & ~RDb);
	assign PG0RDb =  ~( (addrH == 2'b00) & ~RDb) ; 
	
	// RAM Decoder
	assign RAMA = MMUX;
	assign RAM_CSb = ~SLT0SS[2] | ADFFFF;
	
	// =================================
	// ROM Decoder ZemmixV
	assign ROM_OEb1 =  ~(SLT0SS[0] & ( ~PG1RDb | ~ PG0RDb));	// Slot X-0 ROM
	assign ROM_OEb2 =  ~(SLT0SS[1] & ( ~PG1RDb) );	// Slot X-1 ROM
	assign ROM_OEb3 =  ~(SLT0SS[3] & ( ~ PG0RDb ));	// | ~PG1RDb) );	// Slot X-3 ROM
	assign ROM_OEb =  ROM_OEb1 & ROM_OEb2 & ROM_OEb3;
	
	// 128 KB ROM BANK Decoder
	always @(*)
	case ({SLT0SS,addrH})
		6'b0001_00: ROMA = 3'b000;	// Slot 0-0 to 128KB ROM Page 0
		6'b0001_01: ROMA = 3'b001;	// Slot 0-0, page 1 to ROM Page 1
		6'b1000_00: ROMA = 3'b010;	// Slot 0-3 to 128KB ROM Page 2
		6'b0010_01: ROMA = 3'b011;	// Slot 0-2 to 128KB ROM page 3
		default: ROMA = 3'b000;
	endcase

	// =================================
//	// CPC300 - IQ2000 Requires RTC
//	// ROM Decoder
//	assign ROM_OEb1 =  ~(SLT0SS[0] & ( ~PG1RDb | ~ PG0RDb));	// Slot X-0 ROM
//	assign ROM_OEb2 =  ~(SLT0SS[1] & ( ~PG12RDb) );	// Slot 0-1 Page 1,2
//	assign ROM_OEb3 =  ~(SLT0SS[3] & ( ~ PG0RDb | ~PG1RDb ));	// Slot X-3 ROM, Page 0,1
//	assign ROM_OEb =  ROM_OEb1 & ROM_OEb2 & ROM_OEb3;
//	
//	// 128 KB ROM BANK Decoder
//	always @(*)
//	case ({SLT0SS,addrH})
//		6'b0001_00: ROMA = 3'b000;	// 128K ROM 0000h thru 3fffh for sub-slot 0, page 0
//		6'b0001_01: ROMA = 3'b001;	// 128K ROM 4000h thru 7fffh for sub-slot 0, page 1
//		6'b0010_01: ROMA = 3'b011;	// Slot 0-1 Hangul 1
//		6'b0010_10: ROMA = 3'b010; // Slot 0-1 Kanji Control1
//		6'b1000_00: ROMA = 3'b100;	// Slot 3-0  Sub-rom
//		6'b1000_01: ROMA = 3'b101;	// Slot 3-0  Hangul2
//		
//		default: ROMA = 3'b000;
//	endcase
	
	// PSG Signals
	assign PSGBC1 = ~(addrL[0] | ~SEL_PSG);
	assign PSGBDIR = ~(WRb | ~SEL_PSG);
	
	assign VDP_CSWb = WRb | ~SEL_VDP;
	assign VDP_CSRb = RDb | ~SEL_VDP;

	assign keyMAT = PC[3:0];
	
	// DATA Output Buffer Enable 	
	// DOPPI 8255 DATA to DATA BUS
	// DOSSREG SLOT Expander Register to DATABUS
	// Memory Mapper Reading to DATABUS
	
	// Mapper Disagbled 
	assign enDOBUF = ~RDb & (SEL_PPI | outSSREG | IOMM) ;

	reg [7:0] DOBUF;		// Data Buffer MUX
	always @(*)
	case ({SEL_PPI, IOMM, outSSREG})
		3'b100: DOBUF = DOPPI;
		3'b010: DOBUF = DOMM;
		3'b001: DOBUF = DOSSREG;
		default:
			DOBUF = DOPPI;
	endcase
	
	assign data = enDOBUF ? DOBUF : 'bz;
	assign CPU_INTb = SLT_INTb & VDP_INTb;
	
	// PSG Clock 1/2
	//always @(posedge CLK)
		//PSG_CLK = ~PSG_CLK;
		
	assign IOMM = (IOC2F & (addrL[5:2] == 4'b1111));	// Memory Mapper IO Space 1111_1XXXb

endmodule
