------------------------------------------------------------------
-- Simple Computer Architecture
--
-- System composed of
-- 	CPU, memory_clock and output buffer
--    Sinals with the prefix "D_" are set for Debugging purpose only
-- SimpleCompArch.vhd
-------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;  
use ieee.numeric_std.all;			   
use work.MP_lib.all;

entity SimpleCompArch is
port( sys_clk								:	in std_logic;
		  sys_rst							:	in std_logic;
		  sys_output						:	out std_logic_vector(15 downto 0);
		
		-- Debug signals from CPU: output for simulation purpose only	
		D_rfout_bus											: out std_logic_vector(15 downto 0);  
		D_RFwa, D_RFr1a, D_RFr2a				: out std_logic_vector(3 downto 0);
		D_RFwe, D_RFr1e, D_RFr2e				: out std_logic;
		D_ALUs										: out std_logic_vector(3 downto 0);
		D_RFs										: out std_logic_vector(1 downto 0);
		D_PCld, D_jpz										: out std_logic;
		-- end debug variables	

		-- Debug signals from Memory: output for simulation purpose only	
		D_mdout_bus,D_mdin_bus					: out std_logic_vector(15 downto 0); 
		D_mem_addr									: out std_logic_vector(11 downto 0); 
		D_Mre,D_Mwe									: out std_logic; 
		D_read_done, D_write_done: out std_logic

		-- end debug variables	
);
end SimpleCompArch;

architecture rtl of SimpleCompArch is
--Memory local variables												  							        	(ORIGIN	-> DEST)
	signal pll_out_clock				: STD_LOGIC  ; -- Not currently used
	signal mdout_bus					: std_logic_vector(15 downto 0);  -- Mem data output 		(MEM  	-> CTLU)
	signal mdin_bus					: std_logic_vector(15 downto 0);  -- Mem data bus input 	(CTRLER	-> Mem)
	signal mem_addr					: std_logic_vector(11 downto 0);   -- Const. operand addr.(CTRLER	-> MEM)
	signal Mre							: std_logic;							 -- Mem. read enable  	(CTRLER	-> Mem) 
	signal Mwe							: std_logic;							 -- Mem. write enable 	(CTRLER	-> Mem)
	signal read_done: std_logic;
	signal write_done: std_logic;

	--System local variables
	signal oe							: std_logic;	
begin

Unit0: CPU port map (
    sys_clk,
    sys_rst,
    mdout_bus,
    mdin_bus,
    mem_addr,
    cpu_read,
    cpu_write,
    oe,
    read_done,
	 write_done,	
	 
	 D_rfout_bus,
    D_RFwa,
    D_RFr1a, 
    D_RFr2a,
	 D_RFwe, 		 				
    
    --Degug signals
    D_RFr1e,
    D_RFr2e,
    D_ALUs,
    D_RFs,
    D_PCld, 
    D_jpz
    --Degug signals
);	 				
																				
Unit1: memory port map(
	sys_clk,
	sys_rst,	
	Mre, 
	Mwe,
	mem_addr, 
	mdin_bus, 
	mdout_bus,
	read_done,
	write_done
);

-- Debug signals: output to upper level for simulation purpose only
	D_mdout_bus <= mdout_bus;	
	D_mdin_bus <= mdin_bus;
	D_mem_addr <= mem_addr; 
	D_Mre <= Mre;
	D_Mwe <= Mwe;
	D_read_done <= read_done;
	D_write_done <= write_done;

-- end debug variables		
		
end rtl;