`include "define.v"
module id(
          //input 
          rst,
          pc_i,
          inst_i,
          reg1_data_i,
          reg2_data_i,
          ex_aluop_i,
          ex_wreg_i,          
          ex_wd_i,
          ex_wdata_i, 
          mem_wreg_i,
          mem_wd_i,
          mem_wdata_i,
          is_in_delayslot_i,
          //output
          aluop_o,
          alusel_o,
          reg1_o,
          reg2_o,
          wd_o,
          wreg_o,
          reg1_read_o,
          reg1_addr_o,
          reg2_read_o,
          reg2_addr_o,
          stallreq,           //stall request
          is_in_delayslot_o,
          link_addr_o,
          next_inst_in_delayslot_o,
          branch_target_address_o,
          branch_flag_o,
          //
          inst_o,
          //exception
          excepttype_o,
          current_inst_addr_o
         );
         
input rst;
input [`InstAddrBus] pc_i;
input [`InstBus] inst_i;
input [`RegBus] reg1_data_i;
input [`RegBus] reg2_data_i;
// ex: RAM
input [`AluOpBus] ex_aluop_i;
input ex_wreg_i;          
input [`RegAddrBus] ex_wd_i;            
input [`RegBus] ex_wdata_i;
// mem: RAM
input mem_wreg_i;
input [`RegAddrBus] mem_wd_i;
input [`RegBus] mem_wdata_i;
// delay slot
input is_in_delayslot_i;

output reg [`AluOpBus] aluop_o;
output reg [`AluSelBus] alusel_o;
output reg [`RegBus] reg1_o;
output reg [`RegBus] reg2_o;
output reg [`RegAddrBus] reg1_addr_o;
output reg reg1_read_o;
output reg [`RegAddrBus] reg2_addr_o;
output reg reg2_read_o;
output reg wreg_o;
output reg [`RegAddrBus] wd_o;
// stall request
output wire stallreq;
// delay slot
output reg is_in_delayslot_o;
output reg [`RegBus] link_addr_o;
output reg next_inst_in_delayslot_o;
output reg [`RegBus] branch_target_address_o;
output reg branch_flag_o;
// load && store
output wire [`RegBus] inst_o;
// exception
output wire [31:0] excepttype_o;
output wire [`RegBus] current_inst_addr_o;

wire [5:0] op;
wire [4:0] op2;
wire [5:0] op3;
wire [4:0] op4;
reg [`RegBus] imm;
reg instvalid;
reg stallreq_for_reg1_loadrelate;
reg stallreq_for_reg2_loadrelate;
reg excepttype_is_syscall;
reg excepttype_is_eret;

wire [`RegBus] pc_plus_4;
wire [`RegBus] pc_plus_8;
wire [`RegBus] imm_sll2_signedext;
wire pre_inst_is_load; 
                  
assign op  = inst_i[31:26];     
assign op2 = inst_i[10:6];      
assign op3 = inst_i[5:0];       
assign op4 = inst_i[20:16]; 

assign pc_plus_4 = pc_i + 32'h4;
assign pc_plus_8 = pc_i + 32'h8;
assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00};
assign stallreq = stallreq_for_reg1_loadrelate || stallreq_for_reg2_loadrelate;
assign pre_inst_is_load = (ex_aluop_i == `EXE_LB_OP || ex_aluop_i == `EXE_LBU_OP ||
                           ex_aluop_i == `EXE_LH_OP || ex_aluop_i == `EXE_LHU_OP ||
                           ex_aluop_i == `EXE_LW_OP || ex_aluop_i == `EXE_LWL_OP ||
                           ex_aluop_i == `EXE_LL_OP || ex_aluop_i == `EXE_LWR_OP ||
                           ex_aluop_i == `EXE_SC_OP) ? 1'b1 : 1'b0;

// load && store 
assign inst_o = inst_i;

// exception
assign excepttype_o = {19'b0,excepttype_is_eret,2'b00,instvalid,excepttype_is_syscall,8'b0};
assign current_inst_addr_o = pc_i;

always@(*) begin
  if(rst == `RstEnable) begin
    aluop_o <= `EXE_NOP_OP;
    alusel_o <= `EXE_RES_NOP;
    reg1_o <= `ZeroWord;
    reg2_o <= `ZeroWord;
    wreg_o <= `WriteDisable;
    wd_o <= `NOPRegAddr;              // address
    reg1_addr_o <= `NOPRegAddr;
    reg2_addr_o <= `NOPRegAddr;
    reg1_read_o <= `ReadDisable;
    reg2_read_o <= `ReadDisable;
    imm <= `ZeroWord;                 
    instvalid <= `InstValid;
    // jump && branch
    is_in_delayslot_o <= `NotInDelaySlot;
    link_addr_o <= `ZeroWord;
    next_inst_in_delayslot_o <= `NotInDelaySlot;
    branch_target_address_o <= `ZeroWord;
    branch_flag_o <= `NotBranch;
    // exception
    excepttype_is_syscall <= 1'b0;
    excepttype_is_eret <= 1'b0;      
  end
  else begin
    aluop_o <= `EXE_NOP_OP;
    alusel_o <= `EXE_RES_NOP;
    wreg_o <= `WriteDisable;
    wd_o <= inst_i[15:11];
    reg1_addr_o <= inst_i[25:21];
    reg2_addr_o <= inst_i[20:16];
    reg1_read_o <= `ReadDisable;
    reg2_read_o <= `ReadDisable;
    imm <= `ZeroWord; 
    instvalid <= `InstInvalid;
    // jump && branch
    is_in_delayslot_o <= is_in_delayslot_i;
    link_addr_o <= `ZeroWord;
    next_inst_in_delayslot_o <= `NotInDelaySlot;
    branch_target_address_o <= `ZeroWord;
    branch_flag_o <= `NotBranch;
    // exception
    excepttype_is_syscall <= 1'b0;
    excepttype_is_eret <= 1'b0;         
    case(op)
      `EXE_SPECIAL_INST: begin
        case(op2) 
          5'b00000: begin
            case(op3)
              `EXE_AND: begin
                wreg_o <= `WriteEnable;  aluop_o <= `EXE_AND_OP;  alusel_o <=`EXE_RES_LOGIC;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_OR: begin
                wreg_o <= `WriteEnable;  aluop_o <= `EXE_OR_OP;   alusel_o <=`EXE_RES_LOGIC;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_XOR: begin
                wreg_o <= `WriteEnable;  aluop_o <= `EXE_XOR_OP;  alusel_o <=`EXE_RES_LOGIC;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_NOR: begin
                wreg_o <= `WriteEnable;  aluop_o <= `EXE_NOR_OP;  alusel_o <=`EXE_RES_LOGIC;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_SLLV: begin
                wreg_o <= `WriteEnable;  aluop_o <= `EXE_SLL_OP;  alusel_o <=`EXE_RES_SHIFT;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_SRLV: begin
                wreg_o <= `WriteEnable;  aluop_o <= `EXE_SRL_OP;  alusel_o <=`EXE_RES_SHIFT;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_SRAV: begin
                wreg_o <= `WriteEnable;  aluop_o <= `EXE_SRA_OP;  alusel_o <=`EXE_RES_SHIFT;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_SYNC: begin          
                wreg_o <= `WriteEnable;  aluop_o <= `EXE_NOP_OP;  alusel_o <=`EXE_RES_NOP;
                reg1_read_o <= 1'b0;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_MOVZ: begin
                aluop_o <= `EXE_MOVZ_OP; alusel_o <=`EXE_RES_MOVE;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
                wreg_o <= (reg2_o == `ZeroWord) ? 1'b1 : 1'b0;  
              end
              `EXE_MOVN: begin
                aluop_o <= `EXE_MOVN_OP; alusel_o <=`EXE_RES_MOVE;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
                wreg_o <= (reg2_o != `ZeroWord) ? 1'b1 : 1'b0;  
              end
              `EXE_MFHI: begin
                wreg_o <= `WriteEnable;  aluop_o <= `EXE_MFHI_OP; alusel_o <=`EXE_RES_MOVE;
                reg1_read_o <= 1'b0;     reg2_read_o <= 1'b0;     instvalid <= `InstValid;
              end
              `EXE_MFLO: begin
                wreg_o <= `WriteEnable;  aluop_o <= `EXE_MFLO_OP; alusel_o <=`EXE_RES_MOVE;
                reg1_read_o <= 1'b0;     reg2_read_o <= 1'b0;     instvalid <= `InstValid;
              end
              `EXE_MTHI: begin
                wreg_o <= `WriteDisable; aluop_o <= `EXE_MTHI_OP; alusel_o <=`EXE_RES_MOVE;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b0;     instvalid <= `InstValid;
              end
              `EXE_MTLO: begin
                wreg_o <= `WriteDisable; aluop_o <= `EXE_MTLO_OP; alusel_o <=`EXE_RES_MOVE;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b0;     instvalid <= `InstValid;
              end
              `EXE_ADD: begin    
                wreg_o <= `WriteEnable;  aluop_o <= `EXE_ADD_OP;  alusel_o <=`EXE_RES_ARITHMETIC;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_ADDU: begin    
                wreg_o <= `WriteEnable;  aluop_o <= `EXE_ADDU_OP; alusel_o <=`EXE_RES_ARITHMETIC;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_SUB: begin    
                wreg_o <= `WriteEnable;  aluop_o <= `EXE_SUB_OP;  alusel_o <=`EXE_RES_ARITHMETIC;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_SUBU: begin    
                wreg_o <= `WriteEnable;  aluop_o <= `EXE_SUBU_OP; alusel_o <=`EXE_RES_ARITHMETIC;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_SLT: begin    
                wreg_o <= `WriteEnable;  aluop_o <= `EXE_SLT_OP;  alusel_o <=`EXE_RES_ARITHMETIC;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_SLTU: begin    
                wreg_o <= `WriteEnable;  aluop_o <= `EXE_SLTU_OP; alusel_o <=`EXE_RES_ARITHMETIC;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_MULT: begin    
                wreg_o <= `WriteDisable; aluop_o <= `EXE_MULT_OP; 
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_MULTU: begin    
                wreg_o <= `WriteDisable; aluop_o <= `EXE_MULTU_OP;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_DIV: begin
                wreg_o <= `WriteDisable; aluop_o <= `EXE_DIV_OP;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_DIVU: begin
                wreg_o <= `WriteDisable; aluop_o <= `EXE_DIVU_OP;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_JR: begin
                wreg_o <= `WriteDisable; aluop_o <= `EXE_JR_OP;   alusel_o <=`EXE_RES_JUMP_BRANCH;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b0;     instvalid <= `InstValid; 
                next_inst_in_delayslot_o <= `InDelaySlot;
                branch_flag_o <= `Branch;
                branch_target_address_o <= reg1_o;
              end
              `EXE_JALR: begin
                wreg_o <= `WriteEnable;  aluop_o <= `EXE_JALR_OP; alusel_o <=`EXE_RES_JUMP_BRANCH;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b0;     instvalid <= `InstValid; 
                link_addr_o <= pc_plus_8;
                next_inst_in_delayslot_o <= `InDelaySlot;
                branch_flag_o <= `Branch; 
                branch_target_address_o <= reg1_o;
              end
              `EXE_TEQ: begin
                wreg_o <= `WriteDisable; aluop_o <= `EXE_TEQ_OP;  alusel_o <=`EXE_RES_NOP;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_TGE: begin
                wreg_o <= `WriteDisable; aluop_o <= `EXE_TGE_OP;  alusel_o <=`EXE_RES_NOP;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_TGEU: begin
                wreg_o <= `WriteDisable; aluop_o <= `EXE_TGEU_OP; alusel_o <=`EXE_RES_NOP;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_TLT: begin
                wreg_o <= `WriteDisable; aluop_o <= `EXE_TLT_OP;  alusel_o <=`EXE_RES_NOP;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_TLTU: begin
                wreg_o <= `WriteDisable; aluop_o <= `EXE_TLTU_OP;  alusel_o <=`EXE_RES_NOP;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_TNE: begin
                wreg_o <= `WriteDisable; aluop_o <= `EXE_TNE_OP;  alusel_o <=`EXE_RES_NOP;
                reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
              end
              `EXE_SYSCALL: begin
                wreg_o <= `WriteDisable; aluop_o <= `EXE_SYSCALL_OP;  alusel_o <=`EXE_RES_NOP;
                reg1_read_o <= 1'b0;     reg2_read_o <= 1'b0;         instvalid <= `InstValid;
                excepttype_is_syscall <= 1'b1;
              end
              default: begin            
              end
            endcase 
          end
          default: begin                
          end 
        endcase         
      end
      `EXE_SPECIAL2_INST: begin
        case(op3)
          `EXE_CLZ: begin
            wreg_o <= `WriteEnable;  aluop_o <= `EXE_CLZ_OP;  alusel_o <=`EXE_RES_ARITHMETIC;
            reg1_read_o <= 1'b1;     reg2_read_o <= 1'b0;     instvalid <= `InstValid;
          end
          `EXE_CLO: begin
            wreg_o <= `WriteEnable;  aluop_o <= `EXE_CLO_OP;  alusel_o <=`EXE_RES_ARITHMETIC;
            reg1_read_o <= 1'b1;     reg2_read_o <= 1'b0;     instvalid <= `InstValid;
          end
          `EXE_MUL: begin
            wreg_o <= `WriteEnable;  aluop_o <= `EXE_MUL_OP;  alusel_o <=`EXE_RES_MUL;
            reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
          end
          `EXE_MADD: begin
            wreg_o <= `WriteDisable; aluop_o <= `EXE_MADD_OP; alusel_o <=`EXE_RES_MUL;
            reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
          end
          `EXE_MSUB: begin
            wreg_o <= `WriteDisable; aluop_o <= `EXE_MSUB_OP; alusel_o <=`EXE_RES_MUL;
            reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
          end
          `EXE_MADDU: begin
            wreg_o <= `WriteDisable; aluop_o <= `EXE_MADDU_OP; alusel_o <=`EXE_RES_MUL;
            reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;      instvalid <= `InstValid;
          end
          `EXE_MSUBU: begin
            wreg_o <= `WriteDisable; aluop_o <= `EXE_MSUBU_OP; alusel_o <=`EXE_RES_MUL;
            reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;      instvalid <= `InstValid;
          end
          default: begin
          end
        endcase
      end
      `EXE_ANDI: begin
        wreg_o <= `WriteEnable;     aluop_o <= `EXE_AND_OP;       alusel_o <=`EXE_RES_LOGIC;
        reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          wd_o <= inst_i[20:16];
        instvalid <= `InstValid;    imm <= {16'h0,inst_i[15:0]};
      end
      `EXE_ORI: begin
        wreg_o <= `WriteEnable;     aluop_o <= `EXE_OR_OP;        alusel_o <=`EXE_RES_LOGIC;
        reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          wd_o <= inst_i[20:16];
        instvalid <= `InstValid;    imm <= {16'h0,inst_i[15:0]};
      end
      `EXE_XORI: begin
        wreg_o <= `WriteEnable;     aluop_o <= `EXE_XOR_OP;       alusel_o <=`EXE_RES_LOGIC;
        reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          wd_o <= inst_i[20:16];
        instvalid <= `InstValid;    imm <= {16'h0,inst_i[15:0]};
      end
      `EXE_LUI: begin
        wreg_o <= `WriteEnable;     aluop_o <= `EXE_OR_OP;        alusel_o <=`EXE_RES_LOGIC;
        reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          wd_o <= inst_i[20:16];
        instvalid <= `InstValid;    imm <= {inst_i[15:0],16'h0};
      end
      `EXE_PREF: begin
        wreg_o <= `WriteEnable;     aluop_o <= `EXE_NOP_OP;       alusel_o <=`EXE_RES_NOP;
        reg1_read_o <= 1'b0;        reg2_read_o <= 1'b0;          instvalid <= `InstValid;    
      end
      `EXE_ADDI: begin
        wreg_o <= `WriteEnable;     aluop_o <= `EXE_ADDI_OP;      alusel_o <=`EXE_RES_ARITHMETIC;
        reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          wd_o <= inst_i[20:16];
        instvalid <= `InstValid;    imm <= {{16{inst_i[15]}},inst_i[15:0]};
      end
      `EXE_ADDIU: begin
        wreg_o <= `WriteEnable;     aluop_o <= `EXE_ADDIU_OP;     alusel_o <=`EXE_RES_ARITHMETIC;
        reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          wd_o <= inst_i[20:16];
        instvalid <= `InstValid;    imm <= {{16{inst_i[15]}},inst_i[15:0]};
      end
      `EXE_SLTI: begin
        wreg_o <= `WriteEnable;     aluop_o <= `EXE_SLT_OP;       alusel_o <=`EXE_RES_ARITHMETIC;
        reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          wd_o <= inst_i[20:16];
        instvalid <= `InstValid;    imm <= {{16{inst_i[15]}},inst_i[15:0]};
      end
      `EXE_SLTIU: begin
        wreg_o <= `WriteEnable;     aluop_o <= `EXE_SLTU_OP;      alusel_o <=`EXE_RES_ARITHMETIC;
        reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          wd_o <= inst_i[20:16];
        instvalid <= `InstValid;    imm <= {{16{inst_i[15]}},inst_i[15:0]};
      end
      `EXE_J: begin
        wreg_o <= `WriteDisable;    aluop_o <= `EXE_J_OP;         alusel_o <=`EXE_RES_JUMP_BRANCH;
        reg1_read_o <= 1'b0;        reg2_read_o <= 1'b0;          instvalid <= `InstValid;
        next_inst_in_delayslot_o <= `InDelaySlot; 
        branch_flag_o <= `Branch;      
        branch_target_address_o <= {pc_plus_4[31:28],inst_i[25:0],2'b0};
      end
      `EXE_JAL: begin
        wreg_o <= `WriteEnable;     aluop_o <= `EXE_JAL_OP;       alusel_o <=`EXE_RES_JUMP_BRANCH;
        reg1_read_o <= 1'b0;        reg2_read_o <= 1'b0;          instvalid <= `InstValid;
        wd_o <= 5'b11111; 
        link_addr_o <= pc_plus_8;
        next_inst_in_delayslot_o <= `InDelaySlot;   
        branch_flag_o <= `Branch;    
        branch_target_address_o <= {pc_plus_4[31:28],inst_i[25:0],2'b0};
      end
      `EXE_BEQ: begin
        wreg_o <= `WriteDisable;    aluop_o <= `EXE_BEQ_OP;       alusel_o <=`EXE_RES_JUMP_BRANCH;
        reg1_read_o <= 1'b1;        reg2_read_o <= 1'b1;          instvalid <= `InstValid; 
        if(reg1_o == reg2_o) begin
          next_inst_in_delayslot_o <= `InDelaySlot;
          branch_flag_o <= `Branch;
          branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
        end 
        else ;
      end
      `EXE_BGTZ: begin
        wreg_o <= `WriteDisable;    aluop_o <= `EXE_BGTZ_OP;      alusel_o <=`EXE_RES_JUMP_BRANCH;
        reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          instvalid <= `InstValid; 
        if((reg1_o[31] == 1'b0) && (reg1_o != 32'h0)) begin
          next_inst_in_delayslot_o <= `InDelaySlot;
          branch_flag_o <= `Branch;  
          branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
        end 
        else ;
      end
      `EXE_BLEZ: begin
        wreg_o <= `WriteDisable;    aluop_o <= `EXE_BLEZ_OP;      alusel_o <=`EXE_RES_JUMP_BRANCH;
        reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          instvalid <= `InstValid; 
        if((reg1_o[31] == 1'b1) || (reg1_o == 32'h0)) begin
          next_inst_in_delayslot_o <= `InDelaySlot;
          branch_flag_o <= `Branch;  
          branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
        end 
        else ;
      end
      `EXE_BNE: begin
        wreg_o <= `WriteDisable;    aluop_o <= `EXE_BNE_OP;       alusel_o <=`EXE_RES_JUMP_BRANCH;
        reg1_read_o <= 1'b1;        reg2_read_o <= 1'b1;          instvalid <= `InstValid; 
        if(reg1_o != reg2_o) begin
          next_inst_in_delayslot_o <= `InDelaySlot;
          branch_flag_o <= `Branch;  
          branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
        end 
        else ;
      end
      `EXE_REGIMM_INST: begin
        case(op4)
          `EXE_BLTZ: begin
            wreg_o <= `WriteDisable;    aluop_o <= `EXE_BLTZ_OP;      alusel_o <=`EXE_RES_JUMP_BRANCH;
            reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          instvalid <= `InstValid; 
            if(reg1_o[31] == 1'b1) begin
              next_inst_in_delayslot_o <= `InDelaySlot;
              branch_flag_o <= `Branch;  
              branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
            end 
            else ;
          end
          `EXE_BLTZAL: begin
            wreg_o <= `WriteEnable;     aluop_o <= `EXE_BLTZAL_OP;    alusel_o <=`EXE_RES_JUMP_BRANCH;
            reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          instvalid <= `InstValid; 
            wd_o <= 5'b11111;
            link_addr_o <= pc_plus_8;
            if(reg1_o[31] == 1'b1) begin
              next_inst_in_delayslot_o <= `InDelaySlot;
              branch_flag_o <= `Branch;  
              branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
            end
            else ;
          end
          `EXE_BGEZ: begin
            wreg_o <= `WriteDisable;    aluop_o <= `EXE_BGEZ_OP;      alusel_o <=`EXE_RES_JUMP_BRANCH;
            reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          instvalid <= `InstValid; 
            if(reg1_o[31] == 1'b0) begin
              next_inst_in_delayslot_o <= `InDelaySlot;
              branch_flag_o <= `Branch;  
              branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
            end
            else ;
          end
          `EXE_BGEZAL: begin
            wreg_o <= `WriteEnable;     aluop_o <= `EXE_BGEZAL_OP;    alusel_o <=`EXE_RES_JUMP_BRANCH;
            reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          instvalid <= `InstValid;
            wd_o <= 5'b11111;
            link_addr_o <= pc_plus_8; 
            if(reg1_o[31] == 1'b0) begin
              next_inst_in_delayslot_o <= `InDelaySlot;
              branch_flag_o <= `Branch;  
              branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
            end
            else ;
          end
          `EXE_TEQI: begin
            wreg_o <= `WriteDisable;    aluop_o <= `EXE_TEQI_OP;      alusel_o <=`EXE_RES_NOP;
            reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          instvalid <= `InstValid;    
            imm <= {{16{inst_i[15]}},inst_i[15:0]};
          end
          `EXE_TGEI: begin
            wreg_o <= `WriteDisable;    aluop_o <= `EXE_TGEI_OP;      alusel_o <=`EXE_RES_NOP;
            reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          instvalid <= `InstValid;    
            imm <= {{16{inst_i[15]}},inst_i[15:0]};
          end
          `EXE_TGEIU: begin
            wreg_o <= `WriteDisable;    aluop_o <= `EXE_TGEIU_OP;     alusel_o <=`EXE_RES_NOP;
            reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          instvalid <= `InstValid;    
            imm <= {{16{inst_i[15]}},inst_i[15:0]};
          end
          `EXE_TLTI: begin
            wreg_o <= `WriteDisable;    aluop_o <= `EXE_TLTI_OP;      alusel_o <=`EXE_RES_NOP;
            reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          instvalid <= `InstValid;    
            imm <= {{16{inst_i[15]}},inst_i[15:0]};
          end
          `EXE_TLTIU: begin
            wreg_o <= `WriteDisable;    aluop_o <= `EXE_TLTIU_OP;     alusel_o <=`EXE_RES_NOP;
            reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          instvalid <= `InstValid;    
            imm <= {{16{inst_i[15]}},inst_i[15:0]};
          end
          `EXE_TNEI: begin
            wreg_o <= `WriteDisable;    aluop_o <= `EXE_TNEI_OP;      alusel_o <=`EXE_RES_NOP;
            reg1_read_o <= 1'b1;        reg2_read_o <= 1'b0;          instvalid <= `InstValid;    
            imm <= {{16{inst_i[15]}},inst_i[15:0]};
          end
          default: begin
          end
        endcase
      end
      `EXE_LB: begin
        wreg_o <= `WriteEnable;  aluop_o <= `EXE_LB_OP;   alusel_o <=`EXE_RES_LOAD_STORE;
        reg1_read_o <= 1'b1;     reg2_read_o <= 1'b0;     instvalid <= `InstValid;
        wd_o <= inst_i[20:16];
      end
      `EXE_LBU: begin
        wreg_o <= `WriteEnable;  aluop_o <= `EXE_LBU_OP;  alusel_o <=`EXE_RES_LOAD_STORE;
        reg1_read_o <= 1'b1;     reg2_read_o <= 1'b0;     instvalid <= `InstValid;
        wd_o <= inst_i[20:16];
      end
      `EXE_LH: begin
        wreg_o <= `WriteEnable;  aluop_o <= `EXE_LH_OP;   alusel_o <=`EXE_RES_LOAD_STORE;
        reg1_read_o <= 1'b1;     reg2_read_o <= 1'b0;     instvalid <= `InstValid;
        wd_o <= inst_i[20:16];
      end
      `EXE_LHU: begin
        wreg_o <= `WriteEnable;  aluop_o <= `EXE_LHU_OP;  alusel_o <=`EXE_RES_LOAD_STORE;
        reg1_read_o <= 1'b1;     reg2_read_o <= 1'b0;     instvalid <= `InstValid;
        wd_o <= inst_i[20:16];
      end
      `EXE_LW: begin
        wreg_o <= `WriteEnable;  aluop_o <= `EXE_LW_OP;   alusel_o <=`EXE_RES_LOAD_STORE;
        reg1_read_o <= 1'b1;     reg2_read_o <= 1'b0;     instvalid <= `InstValid;
        wd_o <= inst_i[20:16];
      end
      `EXE_LWL: begin
        wreg_o <= `WriteEnable;  aluop_o <= `EXE_LWL_OP;  alusel_o <=`EXE_RES_LOAD_STORE;
        reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
        wd_o <= inst_i[20:16];
      end
      `EXE_LWR: begin
        wreg_o <= `WriteEnable;  aluop_o <= `EXE_LWR_OP;  alusel_o <=`EXE_RES_LOAD_STORE;
        reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
        wd_o <= inst_i[20:16];
      end
      `EXE_LL: begin
        wreg_o <= `WriteEnable;  aluop_o <= `EXE_LL_OP;   alusel_o <=`EXE_RES_LOAD_STORE;
        reg1_read_o <= 1'b1;     reg2_read_o <= 1'b0;     instvalid <= `InstValid;
        wd_o <= inst_i[20:16];
      end
      `EXE_SB: begin
        wreg_o <= `WriteDisable; aluop_o <= `EXE_SB_OP;   alusel_o <=`EXE_RES_LOAD_STORE;
        reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
      end
      `EXE_SH: begin
        wreg_o <= `WriteDisable; aluop_o <= `EXE_SH_OP;   alusel_o <=`EXE_RES_LOAD_STORE;
        reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
      end
      `EXE_SW: begin
        wreg_o <= `WriteDisable; aluop_o <= `EXE_SW_OP;   alusel_o <=`EXE_RES_LOAD_STORE;
        reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
      end
      `EXE_SWL: begin
        wreg_o <= `WriteDisable; aluop_o <= `EXE_SWL_OP;  alusel_o <=`EXE_RES_LOAD_STORE;
        reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
      end
      `EXE_SWR: begin
        wreg_o <= `WriteDisable; aluop_o <= `EXE_SWR_OP;  alusel_o <=`EXE_RES_LOAD_STORE;
        reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
      end
      `EXE_SC: begin
        wreg_o <= `WriteEnable;  aluop_o <= `EXE_SC_OP;   alusel_o <=`EXE_RES_LOAD_STORE;
        reg1_read_o <= 1'b1;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
        wd_o <= inst_i[20:16];
      end
      `EXE_COP0: begin
        if(inst_i[25:21] == `COP0_MT && inst_i[10:0] == 11'b0) begin
          wreg_o <= `WriteDisable; aluop_o <= `EXE_MTC0_OP; alusel_o <=`EXE_RES_MOVE;
          reg1_read_o <= 1'b0;     reg2_read_o <= 1'b1;     instvalid <= `InstValid;
        end
        else if(inst_i[25:21] == `COP0_MF && inst_i[10:0] == 11'b0) begin
          wreg_o <= `WriteEnable;  aluop_o <= `EXE_MFC0_OP; alusel_o <=`EXE_RES_MOVE;
          reg1_read_o <= 1'b0;     reg2_read_o <= 1'b0;     instvalid <= `InstValid;
          wd_o <= inst_i[20:16];
        end 
        else if(inst_i[5:0] == `COP0_ERET && inst_i[25:6] == 20'h80000) begin
          wreg_o <= `WriteDisable; aluop_o <= `EXE_ERET_OP; alusel_o <=`EXE_RES_NOP;
          reg1_read_o <= 1'b0;     reg2_read_o <= 1'b0;     instvalid <= `InstValid;
          excepttype_is_eret <= 1'b1;
        end
        else ;
      end
      default: begin  
      end 
    endcase                 //case op
    if(inst_i[31:21] == 11'b000_0000_0000) begin
      case(op3)
        `EXE_SLL: begin
          wreg_o <= `WriteEnable;     aluop_o <= `EXE_SLL_OP;     alusel_o <=`EXE_RES_SHIFT;
          reg1_read_o <= 1'b0;        reg2_read_o <= 1'b1;        wd_o <= inst_i[15:11];
          instvalid <= `InstValid;    imm[4:0] <= inst_i[10:6];
        end
        `EXE_SRL: begin
          wreg_o <= `WriteEnable;     aluop_o <= `EXE_SRL_OP;     alusel_o <=`EXE_RES_SHIFT;
          reg1_read_o <= 1'b0;        reg2_read_o <= 1'b1;        wd_o <= inst_i[15:11];
          instvalid <= `InstValid;    imm[4:0] <= inst_i[10:6];
        end
        `EXE_SRA: begin
          wreg_o <= `WriteEnable;     aluop_o <= `EXE_SRA_OP;     alusel_o <=`EXE_RES_SHIFT;
          reg1_read_o <= 1'b0;        reg2_read_o <= 1'b1;        wd_o <= inst_i[15:11];
          instvalid <= `InstValid;    imm[4:0] <= inst_i[10:6];
        end
        default: begin
        end
      endcase
    end
    else begin
    end               //if-else
  end                 //if-else
end

// RAW ------------------------------------------------------------------------------------------ 
always@(*) begin
  if(rst == `RstEnable) begin
    reg1_o <= `ZeroWord;
  end
  else begin
    if((pre_inst_is_load == 1'b1) && (reg1_read_o == 1'b1) && (reg1_addr_o == ex_wd_i)) begin
      stallreq_for_reg1_loadrelate <= `Stop;
    end 
    else begin
      stallreq_for_reg1_loadrelate <= `NoStop;
    end
    if((ex_wreg_i == 1'b1) && (reg1_read_o == 1'b1) && (reg1_addr_o == ex_wd_i)) begin
      reg1_o <= ex_wdata_i;
    end
    else if((mem_wreg_i == 1'b1) && (reg1_read_o == 1'b1) && (reg1_addr_o == mem_wd_i)) begin
      reg1_o <= mem_wdata_i;
    end
    else if(reg1_read_o == 1'b1) begin
      reg1_o <= reg1_data_i;
    end
    else if(reg1_read_o == 1'b0) begin
      reg1_o <= imm;
    end
    else begin
      reg1_o <= `ZeroWord;
    end
  end
end

always@(*) begin
  if(rst == `RstEnable) begin
    reg2_o <= `ZeroWord;
  end
  else begin
    if((pre_inst_is_load == 1'b1) && (reg2_read_o == 1'b1) && (reg2_addr_o == ex_wd_i)) begin
      stallreq_for_reg2_loadrelate <= `Stop;
    end 
    else begin
      stallreq_for_reg2_loadrelate <= `NoStop;
    end
    if((ex_wreg_i == 1'b1) && (reg2_read_o == 1'b1) && (reg2_addr_o == ex_wd_i)) begin
      reg2_o <= ex_wdata_i;
    end
    else if((mem_wreg_i == 1'b1) && (reg2_read_o == 1'b1) && (reg2_addr_o == mem_wd_i)) begin
      reg2_o <= mem_wdata_i;
    end
    else if(reg2_read_o == 1'b1) begin
      reg2_o <= reg2_data_i;
    end
    else if(reg2_read_o == 1'b0) begin
      reg2_o <= imm;
    end
    else begin
      reg2_o <= `ZeroWord;
    end
  end
end
// END ------------------------------------------------------------------------------------------

endmodule

