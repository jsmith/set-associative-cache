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
		D_cpu_read,D_cpu_write					: out std_logic;
		D_block_out: out std_logic_vector(63 downto 0);
		D_block_in: out std_logic_vector(63 downto 0);
		D_block_addr: out std_logic_vector(9 downto 0);
		D_mem_read: out std_logic;
		D_write_back: out std_logic;
		D_hit: out std_logic;
		D_initialized: out std_logic_vector(7 downto 0);
		D_dirty: out std_logic_vector(7 downto 0);
		D_lru: out std_logic_vector(7 downto 0);
		D_read_complete: out std_logic;
		D_write_complete: out std_logic;
		D_set_int: out std_logic_vector(2 downto 0);
		D_tag: out std_logic_vector(7 downto 0);
		D_set: out std_logic_vector(1 downto 0);
		D_word: out std_logic_vector(1 downto 0);
		D_out_less_sig: out std_logic_vector(15 downto 0);
		D_most_less_sig: out std_logic_vector(15 downto 0);
		D_temp: out std_logic
		
		-- end debug variables	
);
end SimpleCompArch;

architecture rtl of SimpleCompArch is
--Memory local variables												  							        	(ORIGIN	-> DEST)
	signal mdout_bus: std_logic_vector(15 downto 0);  -- Mem data output 		(MEM  	-> CTLU)
	signal mdin_bus: std_logic_vector(15 downto 0);  -- Mem data bus input 	(CTRLER	-> Mem)
	signal mem_addr: std_logic_vector(11 downto 0);   -- Const. operand addr.(CTRLER	-> MEM)
	signal cpu_read: std_logic;							 -- Mem. read enable  	(CTRLER	-> Mem) 
	signal cpu_write: std_logic;							 -- Mem. write enable 	(CTRLER	-> Mem)
	signal mem_read: std_logic;							 -- Mem. read enable  	(CTRLER	-> Mem) 
	signal mem_write: std_logic;							 -- Mem. write enable 	(CTRLER	-> Mem)
	signal read_complete: std_logic;
	signal write_complete: std_logic;
	
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
	 
	 --Cache signals
	 read_complete,
	 
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

Unit1: obuf port map(oe, mdout_bus, sys_output);

Unit2: cache port map(
	sys_clk,
	sys_rst,
	cpu_read,
	cpu_write,
	mem_addr,
	mdin_bus,
	mdout_bus,
	read_complete,
	write_complete,
	
	D_block_out,
	D_block_in,
	D_block_addr,
	D_mem_read,
	D_write_back,
	D_hit,
	D_initialized,
	D_dirty,
	D_lru,
	D_set_int,
	D_tag,
	D_set,
	D_word,
	D_out_less_sig,
	D_most_less_sig,
	D_temp
);

-- Debug signals: output to upper level for simulation purpose only
	D_mdout_bus <= mdout_bus;	
	D_mdin_bus <= mdin_bus;
	D_mem_addr <= mem_addr; 
	D_cpu_read <= cpu_read;
	D_cpu_write <= cpu_write;
	D_read_complete <= read_complete;
	D_write_complete <= write_complete;
-- end debug variables		
		
end rtl;