`include "define.v"
module id_ex( 
             //input
             clk,
             rst,
             id_aluop,
             id_alusel,
             id_reg1,
             id_reg2,
             id_wreg,
             id_wd,
             stall,
             id_is_in_delayslot,
             id_link_address,
             next_inst_in_delayslot_i,
             id_inst,
             flush,
             id_excepttype,
             id_current_inst_addr,
             //output
             ex_aluop,
             ex_alusel,
             ex_reg1,
             ex_reg2,
             ex_wreg,
             ex_wd,
             ex_is_in_delayslot,
             ex_link_address,
             is_in_delayslot_o,
             ex_inst,
             ex_excepttype,
             ex_current_inst_addr
            );
            
input clk;
input rst;
input [`AluOpBus] id_aluop;
input [`AluSelBus] id_alusel;
input [`RegBus] id_reg1;
input [`RegBus] id_reg2;
input id_wreg;
input [`RegAddrBus] id_wd;
input [5:0] stall;
// jump && branch
input id_is_in_delayslot;
input [`RegBus] id_link_address;
input next_inst_in_delayslot_i;
// 
input [`RegBus] id_inst;
// excepttype
input flush;
input [31:0] id_excepttype;
input [`RegBus] id_current_inst_addr;


output reg [`AluOpBus] ex_aluop;
output reg [`AluSelBus] ex_alusel;
output reg [`RegBus] ex_reg1;
output reg [`RegBus] ex_reg2;
output reg ex_wreg;
output reg [`RegAddrBus] ex_wd;
// jump && branch
output reg ex_is_in_delayslot;
output reg [`RegBus] ex_link_address;
output reg is_in_delayslot_o;
//
output reg [`RegBus] ex_inst;
// excepttype
output reg [31:0] ex_excepttype;
output reg [`RegBus] ex_current_inst_addr;

always@(posedge clk) begin
  if(rst == `RstEnable) begin
    ex_aluop  <= `EXE_NOP_OP;
    ex_alusel <= `EXE_RES_NOP;
    ex_reg1   <= `ZeroWord;
    ex_reg2   <= `ZeroWord;
    ex_wreg   <= `WriteDisable;
    ex_wd     <= `NOPRegAddr;
    ex_is_in_delayslot <= `NotInDelaySlot;
    ex_link_address <= `ZeroWord;
    is_in_delayslot_o <= `NotInDelaySlot;
    ex_inst <= `ZeroWord;
    ex_excepttype <= `ZeroWord;
    ex_current_inst_addr <= `ZeroWord;
  end
  else if(flush == 1'b1) begin
    ex_aluop  <= `EXE_NOP_OP;
    ex_alusel <= `EXE_RES_NOP;
    ex_reg1   <= `ZeroWord;
    ex_reg2   <= `ZeroWord;
    ex_wreg   <= `WriteDisable;
    ex_wd     <= `NOPRegAddr;
    ex_is_in_delayslot <= `NotInDelaySlot;
    ex_link_address <= `ZeroWord;
    is_in_delayslot_o <= `NotInDelaySlot;
    ex_inst <= `ZeroWord;
    ex_excepttype <= `ZeroWord;
    ex_current_inst_addr <= `ZeroWord;
  end
  else if(stall[2] == `Stop && stall[3] == `NoStop) begin
    ex_aluop  <= `EXE_NOP_OP;
    ex_alusel <= `EXE_RES_NOP;
    ex_reg1   <= `ZeroWord;
    ex_reg2   <= `ZeroWord;
    ex_wreg   <= `WriteDisable;
    ex_wd     <= `NOPRegAddr;
    ex_is_in_delayslot <= `NotInDelaySlot;
    ex_link_address <= `ZeroWord;
    // stall request for id will not lead to delayslot
    is_in_delayslot_o <= `NotInDelaySlot; 
    //
    ex_inst   <= `ZeroWord;
    ex_excepttype <= `ZeroWord;
    ex_current_inst_addr <= `ZeroWord;    
  end
  else if(stall[2] == `NoStop) begin
    ex_aluop  <= id_aluop;
    ex_alusel <= id_alusel;
    ex_reg1   <= id_reg1;
    ex_reg2   <= id_reg2;
    ex_wreg   <= id_wreg; 
    ex_wd     <= id_wd;
    ex_is_in_delayslot <= id_is_in_delayslot;
    ex_link_address <= id_link_address;
    is_in_delayslot_o <= next_inst_in_delayslot_i;
    //
    ex_inst   <= id_inst;
    ex_excepttype <= id_excepttype;
    ex_current_inst_addr <= id_current_inst_addr;
  end 
  else ;    // (stall[2] == 1 && stall[3] == 1) <=> keep
end 

endmodule
