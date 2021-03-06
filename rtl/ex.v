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
          //input 
          cnt_i,
          hilo_temp_i,
          //input div
          div_ready_i,
          div_result_i,
          //input jump && branch
          is_in_delayslot_i,
          link_address_i,
          //input load && store
          inst_i,
          //input cp0
          cp0_reg_data_i,
          wb_cp0_reg_data,
          wb_cp0_reg_write_addr,
          wb_cp0_reg_we,
          mem_cp0_reg_data,
          mem_cp0_reg_write_addr,
          mem_cp0_reg_we,
          //input exception
          excepttype_i,
          current_inst_addr_i,
          //output
          wdata_o,
          wreg_o,
          wd_o,
          whilo_o,
          hi_o,
          lo_o,
          cnt_o,
          hilo_temp_o,
          stallreq,
          //output div
          div_start_o,
          signed_div_o,
          div_opdata1_o,
          div_opdata2_o,
          //output load && store
          aluop_o,
          mem_addr_o,
          reg2_o, 
          //output cp0
          cp0_reg_read_addr_o,
          cp0_reg_data_o,
          cp0_reg_write_addr_o,
          cp0_reg_we_o,
          //output exception
          excepttype_o,
          current_inst_addr_o,
          is_in_delayslot_o
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
//
input [1:0] cnt_i;
input [`DoubleBus] hilo_temp_i;
//input div
input div_ready_i;
input [`DoubleBus] div_result_i;
//input jump && branch
input is_in_delayslot_i;
input [`RegBus] link_address_i;
//input load && store
input [`RegBus] inst_i; 
//input cp0
input [`RegBus] cp0_reg_data_i;
input [`RegBus] wb_cp0_reg_data;
input [4:0] wb_cp0_reg_write_addr;
input wb_cp0_reg_we;
input [`RegBus] mem_cp0_reg_data;
input [4:0] mem_cp0_reg_write_addr;
input mem_cp0_reg_we;
//input exception
input [31:0] excepttype_i;
input [`RegBus] current_inst_addr_i;

output reg [`RegBus] wdata_o;
output reg wreg_o;
output reg [`RegAddrBus] wd_o;
output reg whilo_o;
output reg [`RegBus] hi_o;
output reg [`RegBus] lo_o;
output reg [1:0] cnt_o;
output reg [`DoubleBus] hilo_temp_o;
output reg stallreq;
//output div
output reg div_start_o;
output reg signed_div_o;
output reg [`RegBus] div_opdata1_o;
output reg [`RegBus] div_opdata2_o;
//output load && store
output [`AluOpBus] aluop_o;
output [`RegBus] mem_addr_o;
output [`RegBus] reg2_o;
//output cp0
output reg [4:0] cp0_reg_read_addr_o;
output reg [`RegBus] cp0_reg_data_o;
output reg [4:0] cp0_reg_write_addr_o;
output reg cp0_reg_we_o;
//output exception
output wire [31:0] excepttype_o;
output wire [`RegBus] current_inst_addr_o;
output wire is_in_delayslot_o;

reg [`RegBus] logicout;
reg [`RegBus] shiftres;
reg [`RegBus] moveres;
reg [`RegBus] HI;
reg [`RegBus] LO;

reg [`RegBus] arithmeticres;
reg [`DoubleBus] mulres;
reg [`DoubleBus] hilo_temp1;    //temp value
reg stallreq_for_madd_msub;     //stall request 
reg stallreq_for_div; 
wire ov_sum;
//wire reg1_eq_reg2;
wire reg1_lt_reg2;
wire [`RegBus] reg2_i_mux;      //reg2_i complement
wire [`RegBus] reg1_i_not;      //reg1_i negate
wire [`RegBus] result_sum;
wire [`RegBus] opdata1_mult;
wire [`RegBus] opdata2_mult;
wire [`DoubleBus] hilo_temp;

//exception
reg trapassert;
reg ovassert;

assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) || (aluop_i == `EXE_SUBU_OP) ||
                     (aluop_i == `EXE_SLT_OP) || (aluop_i == `EXE_TLTI_OP) ||
                     (aluop_i == `EXE_TLT_OP) || (aluop_i == `EXE_TGEI_OP) ||
                     (aluop_i == `EXE_TGE_OP)) ? (~reg2_i)+1 : (reg2_i);
                    
assign result_sum = reg1_i + reg2_i_mux;

assign ov_sum = (reg1_i[31] && reg2_i[31] && !result_sum[31]) || 
                (!reg1_i[31] && !reg2_i[31] && result_sum[31]);

assign reg1_lt_reg2 = ((aluop_i == `EXE_SLT_OP) || (aluop_i == `EXE_TLTI_OP) ||
                       (aluop_i == `EXE_TLT_OP) || (aluop_i == `EXE_TGEI_OP) ||
                       (aluop_i == `EXE_TGE_OP)) ? 
                       (reg1_i[31] && !reg2_i[31]) || (reg1_i[31] && reg2_i[31] && result_sum[31]) ||
                       (!reg1_i[31] && !reg2_i[31] && result_sum[31]) : (reg1_i < reg2_i);
                      
assign reg1_i_not = ~reg1_i;

// load && store
assign aluop_o = aluop_i;
assign mem_addr_o = reg1_i + {{16{inst_i[15]}},inst_i[15:0]};
assign reg2_o = reg2_i;

// exception
assign is_in_delayslot_o = is_in_delayslot_i;
assign current_inst_addr_o = current_inst_addr_i;
assign excepttype_o = {excepttype_i[31:12],ovassert,trapassert,excepttype_i[9:0]};

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

assign opdata1_mult = ((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) ||
                      (aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP)) && 
                      reg1_i[31] ? (~reg1_i)+1 : reg1_i;
                      
assign opdata2_mult = ((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) ||
                      (aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP)) &&
                      reg2_i[31] ? (~reg2_i)+1 : reg2_i;
                      
assign hilo_temp = opdata1_mult * opdata2_mult;

// MUL MULT MULTU
always@(*) begin
  if(rst == `RstEnable) begin
    mulres <= 64'h0;
  end
  else begin
    case(aluop_i)
      `EXE_MULTU_OP,`EXE_MADDU_OP,`EXE_MSUBU_OP: begin
        mulres <= hilo_temp;
      end
      `EXE_MULT_OP,`EXE_MUL_OP,`EXE_MADD_OP,`EXE_MSUB_OP: begin
        mulres <= (reg1_i[31] ^ reg2_i[31]) ? (~hilo_temp)+1 : hilo_temp;
      end
      default: begin
        mulres <= 64'h0;
      end
    endcase
  end
end 

// MADD MADDU MSUB MSUBU
always@(*) begin
  if(rst == `RstEnable) begin
    cnt_o <= 2'b00;
    hilo_temp_o <= {`ZeroWord,`ZeroWord};
    stallreq_for_madd_msub <= `NoStop;
  end
  else begin
    case(aluop_i)
      `EXE_MADD_OP,`EXE_MADDU_OP: begin
        if(cnt_i == 2'b00) begin
          stallreq_for_madd_msub <= `Stop;
          hilo_temp_o <= mulres;
          hilo_temp1 <= {`ZeroWord,`ZeroWord};
          cnt_o <= 2'b01;
        end
        else if(cnt_i == 2'b01) begin
          stallreq_for_madd_msub <= `NoStop;
          hilo_temp_o <= {`ZeroWord,`ZeroWord};
          hilo_temp1 <= hilo_temp_i + {HI,LO};
          cnt_o <= 2'b10;     //importent
        end
        else ;
      end
      `EXE_MSUB_OP,`EXE_MSUBU_OP: begin
        if(cnt_i == 2'b00) begin
          stallreq_for_madd_msub <= `Stop;
          hilo_temp_o <= ~mulres +1 ;
          hilo_temp1 <= {`ZeroWord,`ZeroWord};
          cnt_o <= 2'b01;
        end
        else if(cnt_i == 2'b01) begin
          stallreq_for_madd_msub <= `NoStop;
          hilo_temp_o <= {`ZeroWord,`ZeroWord};
          hilo_temp1 <= hilo_temp_i + {HI,LO};
          cnt_o <= 2'b10;     //importent
        end
        else ;
      end
      default: begin
        cnt_o <= 2'b00;
        hilo_temp_o <= {`ZeroWord,`ZeroWord};
        stallreq_for_madd_msub <= `NoStop;  
      end
    endcase
  end
end 

always@(*) begin
  if(rst == `RstEnable) begin
    div_start_o <= `DivStop;
    signed_div_o <= 1'b0;
    div_opdata1_o <= `ZeroWord;
    div_opdata2_o <= `ZeroWord;
    stallreq_for_div <= `NoStop;
  end
  else begin
    div_start_o <= `DivStop;
    signed_div_o <= 1'b0;
    div_opdata1_o <= `ZeroWord;
    div_opdata2_o <= `ZeroWord;
    stallreq_for_div <= `NoStop;
    case(aluop_i)
      `EXE_DIV_OP: begin
        if(div_ready_i == `DivResultNotReady) begin
          div_start_o <= `DivStart;
          signed_div_o <= 1'b1;
          div_opdata1_o <= reg1_i;
          div_opdata2_o <= reg2_i;
          stallreq_for_div <= `Stop;
        end
        else begin
          /*div_start_o <= `DivStop;
          signed_div_o <= 1'b1;
          div_opdata1_o <= `ZeroWord;
          div_opdata2_o <= `ZeroWord;
          stallreq_for_div <= `NoStop;*/
        end
      end
      `EXE_DIVU_OP: begin
        if(div_ready_i == `DivResultNotReady) begin
          div_start_o <= `DivStart;
          signed_div_o <= 1'b0;
          div_opdata1_o <= reg1_i;
          div_opdata2_o <= reg2_i;
          stallreq_for_div <= `Stop;
        end
        else begin
          /*div_start_o <= `DivStop;
          signed_div_o <= 1'b0;
          div_opdata1_o <= `ZeroWord;
          div_opdata2_o <= `ZeroWord;
          stallreq_for_div <= `NoStop;*/
        end
      end
      default: begin
      end
    endcase
  end
end

always@(*) begin
  stallreq <= stallreq_for_madd_msub || stallreq_for_div;
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

// MOVZ MOVN MFHI MFLO MFC0
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
      `EXE_MFC0_OP: begin
        cp0_reg_read_addr_o <= inst_i[15:11];
        if(mem_cp0_reg_we == 1'b1 && mem_cp0_reg_write_addr == inst_i[15:11]) begin
          moveres <= mem_cp0_reg_data;
        end
        else if(wb_cp0_reg_we == 1'b1 && wb_cp0_reg_write_addr == inst_i[15:11]) begin
          moveres <= wb_cp0_reg_data;
        end 
        else begin
          moveres <= cp0_reg_data_i;
        end
      end
      default: begin
        moveres <= `ZeroWord;
      end
    endcase 
  end
end

// MTC0
always@(*) begin
  if(rst == `RstEnable) begin
    cp0_reg_read_addr_o <= 5'b00000;
    cp0_reg_data_o <= `ZeroWord;
    cp0_reg_write_addr_o = 5'b00000;
    cp0_reg_we_o <= `WriteDisable;
  end
  else begin
    cp0_reg_data_o <= reg2_i;
    cp0_reg_write_addr_o = 5'b00000;
    cp0_reg_we_o <= `WriteDisable;
    if(aluop_i == `EXE_MTC0_OP) begin
      cp0_reg_write_addr_o = inst_i[15:11];
      cp0_reg_we_o <= `WriteEnable;
    end
    else ;
  end
end

always@(*) begin
  if(((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_SUB_OP) || 
    (aluop_i == `EXE_ADDI_OP)) && (ov_sum == 1'b1)) begin
    wreg_o <= `WriteDisable;
    ovassert <= 1'b1;
  end
  else begin
    wreg_o <= wreg_i;
    ovassert <= 1'b0;
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
    `EXE_RES_JUMP_BRANCH: begin
      wdata_o <= link_address_i;
    end
    default: begin
      wdata_o <= `ZeroWord;
    end 
  endcase
end

// MTHI MTLO MADD MADDU MSUB MSUBS DIV DIVU
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
        lo_o <= mulres[31:0];         //take care
      end
      `EXE_DIV_OP,`EXE_DIVU_OP: begin
        whilo_o <= `WriteEnable;
        hi_o <= div_result_i[63:32];
        lo_o <= div_result_i[31:0];
      end
      `EXE_MTHI_OP: begin
        whilo_o <= `WriteEnable;
        hi_o <= reg1_i;
        lo_o <= LO;         //take care
      end
      `EXE_MTLO_OP: begin
        whilo_o <= `WriteEnable;
        hi_o <= HI;         //take care
        lo_o <= reg1_i;
      end
      `EXE_MADD_OP,`EXE_MADDU_OP,`EXE_MSUB_OP,`EXE_MSUBU_OP: begin
        whilo_o <= `WriteEnable;
        hi_o <= hilo_temp1[63:32];
        lo_o <= hilo_temp1[31:0]; 
      end
      default: begin
        whilo_o <= `WriteDisable;
        hi_o <= `ZeroWord;
        lo_o <= `ZeroWord;
      end
    endcase 
  end
end

// TEQ TEQI TNE TNEI TGE TGEI TGEU TGEIU TLT TLTI TLTU TLTIU
always@(*) begin
  if(rst == `RstEnable) begin
    trapassert <= `TrapNotAssert;
  end
  else begin
    case(aluop_i)
      `EXE_TEQ_OP,`EXE_TEQI_OP: begin
        trapassert <= (reg1_i == reg2_i);
      end
      `EXE_TNE_OP,`EXE_TNEI_OP: begin
        trapassert <= (reg1_i != reg2_i);
      end
      `EXE_TGE_OP,`EXE_TGEI_OP,`EXE_TGEU_OP,`EXE_TGEIU_OP: begin
        trapassert <= (reg1_lt_reg2 == 1'b0);
      end
      `EXE_TLT_OP,`EXE_TLTI_OP,`EXE_TLTU_OP,`EXE_TLTIU_OP: begin
        trapassert <= (reg1_lt_reg2 == 1'b1);
      end
      default: begin
        trapassert <= `TrapNotAssert;
      end
    endcase
  end
end 

endmodule
    
