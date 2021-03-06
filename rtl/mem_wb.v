`include "define.v"
module mem_wb(
              //input
              clk,
              rst,
              mem_wreg,
              mem_wd,
              mem_wdata,
              mem_whilo,
              mem_hi,
              mem_lo,
              stall,
              mem_LLbit_we,
              mem_LLbit_value,
              mem_cp0_reg_data,
              mem_cp0_reg_write_addr,
              mem_cp0_reg_we,
              flush,
              //output
              wb_wreg,
              wb_wd,
              wb_wdata,
              wb_whilo,
              wb_hi,
              wb_lo,
              wb_LLbit_we,
              wb_LLbit_value,
              wb_cp0_reg_data,
              wb_cp0_reg_write_addr,
              wb_cp0_reg_we
             );
             
input clk;
input rst;
input mem_wreg;
input [`RegAddrBus] mem_wd;
input [`RegBus] mem_wdata;
input mem_whilo;
input [`RegBus] mem_hi;
input [`RegBus] mem_lo;
input [5:0] stall;
input mem_LLbit_we;
input mem_LLbit_value;
input [`RegBus] mem_cp0_reg_data;
input [4:0] mem_cp0_reg_write_addr;
input mem_cp0_reg_we;
input flush;

output reg wb_wreg;
output reg [`RegAddrBus] wb_wd;
output reg [`RegBus] wb_wdata;
output reg wb_whilo;
output reg [`RegBus] wb_hi;
output reg [`RegBus] wb_lo;
output reg wb_LLbit_we;
output reg wb_LLbit_value;
output reg [`RegBus] wb_cp0_reg_data;
output reg [4:0] wb_cp0_reg_write_addr;
output reg wb_cp0_reg_we;

always@(posedge clk) begin
  if(rst == `RstEnable) begin
    wb_wreg  <= `WriteDisable;
    wb_wd    <= `NOPRegAddr;
    wb_wdata <= `ZeroWord;
    wb_whilo <= `WriteDisable;
    wb_hi <= `ZeroWord;
    wb_lo <= `ZeroWord;
    wb_LLbit_we <= `WriteDisable;
    wb_LLbit_value <= 1'b0;
    wb_cp0_reg_data <= `ZeroWord;
    wb_cp0_reg_write_addr <= 5'b00000;
    wb_cp0_reg_we <= `WriteDisable;
  end
  else if(flush == 1'b1) begin
    wb_wreg  <= `WriteDisable;
    wb_wd    <= `NOPRegAddr;
    wb_wdata <= `ZeroWord;
    wb_whilo <= `WriteDisable;
    wb_hi <= `ZeroWord;
    wb_lo <= `ZeroWord;
    wb_LLbit_we <= `WriteDisable;
    wb_LLbit_value <= 1'b0;
    wb_cp0_reg_data <= `ZeroWord;
    wb_cp0_reg_write_addr <= 5'b00000;
    wb_cp0_reg_we <= `WriteDisable;
  end
  else if(stall[4] == `Stop && stall[5] == `NoStop) begin
    wb_wreg  <= `WriteDisable;
    wb_wd    <= `NOPRegAddr;
    wb_wdata <= `ZeroWord;
    wb_whilo <= `WriteDisable;
    wb_hi <= `ZeroWord;
    wb_lo <= `ZeroWord;
    wb_LLbit_we <= `WriteDisable;
    wb_LLbit_value <= 1'b0;
    wb_cp0_reg_data <= `ZeroWord;
    wb_cp0_reg_write_addr <= 5'b00000;
    wb_cp0_reg_we <= `WriteDisable;
  end
  else if(stall[4] == `NoStop) begin
    wb_wreg  <= mem_wreg;
    wb_wd    <= mem_wd;
    wb_wdata <= mem_wdata;
    wb_whilo <= mem_whilo;
    wb_hi <= mem_hi;
    wb_lo <= mem_lo;
    wb_LLbit_we <= mem_LLbit_we;
    wb_LLbit_value <= mem_LLbit_value;
    wb_cp0_reg_data <= mem_cp0_reg_data;
    wb_cp0_reg_write_addr <= mem_cp0_reg_write_addr;
    wb_cp0_reg_we <= mem_cp0_reg_we;
  end
  else ;    // keep
end

endmodule
