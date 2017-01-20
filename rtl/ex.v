`include "define.v"
module ex(
					//input
					rst,
					aluop_i,
					alusel_i,
					reg1_i,
					reg2_i,
					wreg_i,
					wd_i,
					//input: HI LO
					hi_i,
					lo_i,
					//input RAW
					mem_whilo_i,
					mem_hi_i,
					mem_lo_i,
					wb_whilo_i,
					wb_hi_i,
					wb_lo_i,
					//output
					wdata_o,
					wreg_o,
					wd_o,
					whilo_o,
					hi_o,
					lo_o
				 );
				 
input rst;
input [`AluOpBus] aluop_i;
input [`AluSelBus] alusel_i;
input [`RegBus] reg1_i;
input [`RegBus] reg2_i;
input wreg_i;
input [`RegAddrBus] wd_i;
input [`RegBus] hi_i;
input [`RegBus] lo_i;
//RAW
input mem_whilo_i;
input [`RegBus] mem_hi_i;
input [`RegBus] mem_lo_i;
input wb_whilo_i;
input [`RegBus] wb_hi_i;
input [`RegBus] wb_lo_i;

output reg [`RegBus] wdata_o;
output reg wreg_o;
output reg [`RegAddrBus] wd_o;
output reg whilo_o;
output reg [`RegBus] hi_o;
output reg [`RegBus] lo_o;

reg [`RegBus] logicout;
reg [`RegBus] shiftres;
reg [`RegBus] moveres;
reg [`RegBus] HI;
reg [`RegBus] LO;

reg [`RegBus] arithmeticres;
reg [`DoubleBus] mulres;
wire ov_sum;
//wire reg1_eq_reg2;
wire reg1_lt_reg2;
wire [`RegBus] reg2_i_mux;		//reg2_i complement
wire [`RegBus] reg1_i_not;		//reg1_i negate
wire [`RegBus] result_sum;
wire [`RegBus] opdata1_mult;
wire [`RegBus] opdata2_mult;
wire [`DoubleBus] hilo_temp;

assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) || (aluop_i == `EXE_SUBU_OP) ||
									  (aluop_i == `EXE_SLT_OP)) ? (~reg2_i)+1 : (reg2_i);
									  
assign result_sum = reg1_i + reg2_i_mux;

assign ov_sum = (reg1_i[31] && reg2_i[31] && !result_sum[31]) || 
								(!reg1_i[31] && !reg2_i[31] && result_sum[31]);

assign reg1_lt_reg2 = (aluop_i == `EXE_SLT_OP) ? 
										  (reg1_i[31] && !reg2_i[31]) || (reg1_i[31] && reg2_i[31] && result_sum[31]) ||
										  (!reg1_i[31] && !reg2_i[31] && result_sum[31]) : (reg1_i < reg2_i);
										  
assign reg1_i_not = ~reg1_i;

// SLT SLTU SLTI SLTIU ADD ADDU ADDI ADDIU SUB SUBU CLZ CLO
always@(*) begin
	if(rst == `RstEnable) begin
		arithmeticres <= `ZeroWord;
	end
	else begin
		case(aluop_i)
			`EXE_SLT_OP,`EXE_SLTU_OP: begin
				arithmeticres <= reg1_lt_reg2;
			end
			`EXE_ADDU_OP,`EXE_SUBU_OP,`EXE_ADDIU_OP,`EXE_ADD_OP,`EXE_SUB_OP,`EXE_ADDI_OP: begin
				arithmeticres <= result_sum;
			end
			`EXE_CLZ_OP: begin
				arithmeticres <= reg1_i[31] ? 0  : reg1_i[30] ? 1  : reg1_i[29] ? 2  : reg1_i[28] ? 3  :
												 reg1_i[27] ? 4  : reg1_i[26] ? 5  : reg1_i[25] ? 6  : reg1_i[24] ? 7  :
												 reg1_i[23] ? 8  : reg1_i[22] ? 9  : reg1_i[21] ? 10 : reg1_i[20] ? 11 :
												 reg1_i[19] ? 12 : reg1_i[18] ? 13 : reg1_i[17] ? 14 : reg1_i[16] ? 15 : 
												 reg1_i[15] ? 16 : reg1_i[14] ? 17 : reg1_i[13] ? 18 : reg1_i[12] ? 19 :
												 reg1_i[11] ? 20 : reg1_i[10] ? 21 : reg1_i[9]  ? 22 : reg1_i[8]  ? 23 :
												 reg1_i[7]  ? 24 : reg1_i[6]  ? 25 : reg1_i[5]  ? 26 : reg1_i[4]  ? 27 :
												 reg1_i[3]  ? 28 : reg1_i[2]  ? 29 : reg1_i[1]  ? 30 : reg1_i[0]  ? 31 : 32;								 
			end
			`EXE_CLO_OP: begin
				arithmeticres <= reg1_i_not[31] ? 0  : reg1_i_not[30] ? 1  : reg1_i_not[29] ? 2  : reg1_i_not[28] ? 3  :
												 reg1_i_not[27] ? 4  : reg1_i_not[26] ? 5  : reg1_i_not[25] ? 6  : reg1_i_not[24] ? 7  :
												 reg1_i_not[23] ? 8  : reg1_i_not[22] ? 9  : reg1_i_not[21] ? 10 : reg1_i_not[20] ? 11 :
												 reg1_i_not[19] ? 12 : reg1_i_not[18] ? 13 : reg1_i_not[17] ? 14 : reg1_i_not[16] ? 15 : 
												 reg1_i_not[15] ? 16 : reg1_i_not[14] ? 17 : reg1_i_not[13] ? 18 : reg1_i_not[12] ? 19 :
												 reg1_i_not[11] ? 20 : reg1_i_not[10] ? 21 : reg1_i_not[9]  ? 22 : reg1_i_not[8]  ? 23 :
												 reg1_i_not[7]  ? 24 : reg1_i_not[6]  ? 25 : reg1_i_not[5]  ? 26 : reg1_i_not[4]  ? 27 :
												 reg1_i_not[3]  ? 28 : reg1_i_not[2]  ? 29 : reg1_i_not[1]  ? 30 : reg1_i_not[0]  ? 31 : 32;
			end	
			default: begin
				arithmeticres <= `ZeroWord;
			end
		endcase
	end
end

assign opdata1_mult = ((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP)) && 
											reg1_i[31] ? (~reg1_i)+1 : reg1_i;
										  
assign opdata2_mult = ((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP)) &&
											reg2_i[31] ? (~reg2_i)+1 : reg2_i;
											
assign hilo_temp = opdata1_mult * opdata2_mult;

// MUL MULT MULTU
always@(*) begin
	if(rst == `RstEnable) begin
		mulres <= 64'h0;
	end
	else begin
		case(aluop_i)
			`EXE_MULTU_OP: begin
				mulres <= hilo_temp;
			end
			`EXE_MULT_OP,`EXE_MUL_OP: begin
				mulres <= (reg1_i[31] ^ reg2_i[31]) ? (~hilo_temp)+1 : hilo_temp;
			end
		  default: begin
		  	mulres <= 64'h0;
		  end
		endcase
	end
end							  										

// AND ANDI OR ORI XOR XORI NOR LUI 
always@(*) begin
	if(rst == `RstEnable) begin
		logicout <= `ZeroWord;
	end
	else begin
		case(aluop_i)
			`EXE_AND_OP: begin
				logicout <= reg1_i & reg2_i;
			end
			`EXE_OR_OP: begin
				logicout <= reg1_i | reg2_i;
			end
			`EXE_XOR_OP: begin
				logicout <= reg1_i ^ reg2_i;
			end
			`EXE_NOR: begin
				logicout <= ~(reg1_i | reg2_i);
			end
			default: begin
				logicout <= `ZeroWord;
			end
		endcase
	end
end

// SLL SLLV SRL SRLV SRA SRAV 
always@(*) begin
	if(rst == `RstEnable) begin
		shiftres <= `ZeroWord;
	end
	else begin
		case(aluop_i)
			`EXE_SLL_OP: begin
				shiftres <= reg2_i << reg1_i[4:0];
			end
			`EXE_SRL_OP: begin
				shiftres <= reg2_i >> reg1_i[4:0];
			end
			`EXE_SRA_OP: begin
				shiftres <= ({32{reg2_i[31]}} << (6'd32-{1'b0,reg1_i[4:0]})) | (reg2_i >> reg1_i[4:0]);
			end
			default: begin
				shiftres <= `ZeroWord;
			end
		endcase
	end
end

//RAW
always@(*) begin
	if(rst == `RstEnable) begin
		{HI,LO} <= {`ZeroWord,`ZeroWord};
	end
  else if(mem_whilo_i == `WriteEnable) begin
  	{HI,LO} <= {mem_hi_i,mem_lo_i};
  end
  else if(wb_whilo_i == `WriteEnable) begin
  	{HI,LO} <= {wb_hi_i,wb_lo_i};
  end
  else 
  	{HI,LO} <= {hi_i,lo_i};
end

// MOVZ MOVN MFHI MFLO
always@(*) begin
	if(rst == `RstEnable) begin
		moveres <= `ZeroWord;
	end
  else begin
  	case(aluop_i)
  		`EXE_MOVZ_OP: begin
  			moveres <= reg1_i;
  		end
  		`EXE_MOVN_OP: begin
  		  moveres <= reg1_i;
  		end
  		`EXE_MFHI_OP: begin
  		  moveres <= HI;
  		end
  		`EXE_MFLO_OP: begin
  		  moveres <= LO;
  		end
  	  default: begin
  	  	moveres <= `ZeroWord;
  	  end
  	endcase	
  end
end

always@(*) begin
	if(((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_SUB_OP) || 
		(aluop_i == `EXE_ADDI_OP)) && (ov_sum == 1'b1)) begin
		wreg_o <= `WriteDisable;
	end
  else begin
  	wreg_o <= wreg_i;
  end	
	wd_o <= wd_i;
	case(alusel_i)
		`EXE_RES_LOGIC: begin
			wdata_o <= logicout;
		end
		`EXE_RES_SHIFT: begin
			wdata_o <= shiftres;
		end
		`EXE_RES_MOVE: begin
			wdata_o <= moveres;
		end
		`EXE_RES_ARITHMETIC: begin
			wdata_o <= arithmeticres;
		end
		`EXE_RES_MUL: begin
			wdata_o <= mulres[31:0];
		end
		default: begin
			wdata_o <= `ZeroWord;
		end	
	endcase
end

// MTHI MTLO
always@(*) begin
	if(rst == `RstEnable) begin
	  whilo_o <= `WriteDisable;	
	  hi_o <= `ZeroWord;
	  lo_o <= `ZeroWord;
	end
  else begin
  	case(aluop_i)
  		`EXE_MULT_OP,`EXE_MULTU_OP: begin
  			whilo_o <= `WriteEnable;
  			hi_o <= mulres[63:32];
  			lo_o <= mulres[31:0];					//take care
  		end
  		`EXE_MTHI_OP: begin
  			whilo_o <= `WriteEnable;
  			hi_o <= reg1_i;
  			lo_o <= LO;					//take care
  		end
  		`EXE_MTLO_OP: begin
  			whilo_o <= `WriteEnable;
  		  hi_o <= HI;  				//take care
  		  lo_o <= reg1_i;
  		end
  	  default: begin
  			whilo_o <= `WriteDisable;
  	  	hi_o <= `ZeroWord;
				lo_o <= `ZeroWord;
  	  end
  	endcase	
  end
end

endmodule
		