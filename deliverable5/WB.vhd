--********************************************************************
-- ECSE 425, Group 6
-- Runze ZHANG(260760723)
-- Date: March 15, 2017

-- Description: stage of WB 
-- write the data from memory or alu back to the register



--********************************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity WB is
	PORT( 
              clk: in  std_logic;
              memory_data: in std_logic_vector(31 downto 0);
              alu_result: in std_logic_vector(31 downto 0);
              opcode : in std_logic_vector(5 downto 0);
              writeback_addr: in std_logic_vector(4 downto 0);
	      WB_control_buffer: in std_logic_vector(5 downto 0);
              mem_data_stall: in std_logic;
              -- for ex stage forward
	      WB_control_buffer_out: out std_logic_vector(5 downto 0);
	      -- for id stage
	      writeback_data_out: out std_logic_vector(31 downto 0);
              writeback_addr_out: out std_logic_vector(4 downto 0)
              
	);
end WB;

architecture behaviour of WB is
signal mux: std_logic:= '0';

begin
WB_control_buffer_out <= WB_control_buffer;  
wb_process:process(clk)
begin
   if (clk'event and clk = '1' and mem_data_stall = '0') then 
      if(opcode = "100011") then 
          writeback_data_out <= memory_data;
       else 
         writeback_data_out <= alu_result;
       end if;
      writeback_addr_out <= writeback_addr;
    end if;
end process;
end behaviour;
