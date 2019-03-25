--------------------------------------------------------
-- Simple Microprocessor Design 
--
-- Microprocessor composed of
-- Ctrl_Unit and Datapath
-- structural modeling
-- CPU.vhd
--------------------------------------------------------

library	ieee;
use ieee.std_logic_1164.all;  
use ieee.numeric_std.all;			   
use work.MP_lib.all;

entity CPU is
port( cpu_clk					: in std_logic;
		cpu_rst					: in std_logic;
		mdout_bus				: in std_logic_vector(15 downto 0); 
		mdin_bus				: out std_logic_vector(15 downto 0);
		mem_addr				: out std_logic_vector(11 downto 0);
		Mre_s					: out std_logic;
		Mwe_s					: out std_logic;
		oe_s					: out std_logic;
		
		-- Cache Signals
		cache_read_complete : in std_logic;
		cache_write_complete : in std_logic;
		
		-- Board Button Signal
		next_value: in std_logic;
		
		-- Debug signals: output to upper level for simulation purpose only
		D_rfout_bus: out std_logic_vector(15 downto 0);  
		D_RFwa_s, D_RFr1a_s, D_RFr2a_s: out std_logic_vector(3 downto 0);
		D_RFwe_s, D_RFr1e_s, D_RFr2e_s: out std_logic;
		D_ALUs_s: out std_logic_vector(3 downto 0);
		D_RFs_s: out std_logic_vector(1 downto 0);
		D_PCld_s, D_jpz_s: out std_logic;
		D_hex_clock: out std_logic
		-- end debug variables		
		
		);
end CPU;

architecture structure of CPU is --(ORIGIN -> DEST)
signal addr_bus					: std_logic_vector(15 downto 0); -- Mem addr. bus (BMUX -> MEM)
signal immd_bus					: std_logic_vector(15 downto 0); -- Data constant from inst. (BMUX -> MEM)
signal rfout_bus				: std_logic_vector(15 downto 0); -- Reg. File output (CTRLER -> BMUX)
signal RFwa_s					: std_logic_vector(3 downto 0); -- Reg. File write addr. (CTRLER -> RF)
signal RFr1a_s					: std_logic_vector(3 downto 0); -- Reg. File read addr. p1 (CTRLER -> RF)
signal RFr2a_s					: std_logic_vector(3 downto 0); -- Reg. File read addr. p2 (CTRLER -> RF)
signal RFwe_s					: std_logic; -- Reg. File write enable (CTRLER -> RF)
signal RFr1e_s					: std_logic; -- Reg. File read enable p1 (CTRLER -> RF)
signal RFr2e_s					: std_logic; -- Reg. File read enable p2 (CTRLER -> RF)
signal RFs_s					: std_logic_vector(1 downto 0); -- Reg. File select (CTRLER -> SMUX)
signal ALUs_s					: std_logic_vector(3 downto 0); -- ALU select (CTRLER 	-> ALU)
signal PCld_s					: std_logic; -- Program Counter select (CTRLER -> SMUX)
signal jpz_s					: std_logic; -- Jump check flag (CTRLER -> ALU)

signal hex_clk:	std_logic;
signal output_enabled:	std_logic;

begin
	mem_addr <= addr_bus(11 downto 0); 
	Unit0: ctrl_unit port map(	
		hex_clk,
		cpu_rst,
		PCld_s,
		mdout_bus,
		rfout_bus,
		addr_bus,
		immd_bus,
		RFs_s,
		RFwa_s,
		RFr1a_s,
		RFr2a_s,
		RFwe_s,
		RFr1e_s,
		RFr2e_s,
		jpz_s,
		ALUs_s,
		Mre_s,
		Mwe_s,
		output_enabled,
		
		-- Cache Signals
		cache_read_complete,
		cache_write_complete
	);

	Unit1: datapath port map(hex_clk,cpu_rst,immd_bus,mdout_bus, RFs_s,RFwa_s,RFr1a_s,
								RFr2a_s,RFwe_s,RFr1e_s,RFr2e_s,jpz_s,ALUs_s,PCld_s,rfout_bus, mdin_bus);
	
-- Sets output signal.
	oe_s <= output_enabled;
	
-- Assignment of debug variables	
	D_rfout_bus<= rfout_bus;
	D_RFwa_s<= RFwa_s;
	D_RFr1a_s<= RFr1a_s;
	D_RFr2a_s<= RFr2a_s;
	D_RFwe_s<= RFwe_s;
	D_RFr1e_s<= RFr1e_s;
	D_RFr2e_s<= RFr2e_s;
	D_RFs_s<= RFs_s;
	D_ALUs_s<= ALUs_s;
	D_PCld_s<= PCld_s;
	D_jpz_s<= jpz_s;
	D_hex_clock<=hex_clk;
	
process(cpu_clk, cpu_rst)

variable to_zero: std_logic;

type states is (
	state_wait, 
	state_btn_press, 
	state_btn_release, 
	state_oe_low
);
variable state: states;

begin

	hex_clk <= cpu_clk;
	
	if (cpu_rst = '1') then
		state := state_wait;
		hex_clk <= cpu_clk;
		
	elsif (cpu_clk'event and cpu_clk = '1') then
		
		case state is
		when state_wait =>
			if (output_enabled = '1') then
				state := state_btn_press;
			end if;
			
			hex_clk <= cpu_clk;
			to_zero := '0';
		
		when state_btn_press =>
			if (next_value = '0') then
				state := state_btn_release;
			end if;
			
			to_zero := '1';
--			hex_clk <= cpu_clk;
		
		when state_btn_release =>
			if (next_value = '1') then
				state := state_oe_low;
			end if;
			
			to_zero := '1';
--			hex_clk <= cpu_clk;
		
		when state_oe_low =>
			if (output_enabled = '0') then
				state := state_wait;
			end if;
			hex_clk <= cpu_clk;
			to_zero := '0';
			
		when others =>
			state := state_wait;
			to_zero := '0';
			
		end case;
	end if;
	
	if (to_zero = '1') then
		hex_clk <= '0';
	end if;
end process;	
end structure;
