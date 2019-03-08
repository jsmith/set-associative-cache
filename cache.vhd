-- 2 bits offset
-- 2 bits set
-- 8 bits tag

library	ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;   
use work.MP_lib.all;

entity cache is
port ( 	
		clock: in std_logic;
		rst: in std_logic;
		cpu_read: in std_logic;
		cpu_write: in std_logic;
		cpu_addr: in std_logic_vector(11 downto 0);
		data_in: in std_logic_vector(15 downto 0);
		data_out: out std_logic_vector(15 downto 0)
);
end cache;

architecture behv of cache	is			

	type ram_type is array (0 to 255) of std_logic_vector(15 downto 0);
	signal tmp_ram: ram_type;
	signal mem_read: std_logic;
	signal mem_write: std_logic;
	signal mem_addr: std_logic_vector(11 downto 0);

begin
	Unit1: m4k_ram port map(
		mem_addr, 
		clock,
		data_in, 
		mem_read, 
		mem_write,
		data_out
	);

	process(cpu_write, cpu_read, cpu_addr)
	begin
		mem_read <= cpu_read;
		mem_write <= cpu_write;
		mem_addr <= cpu_addr;
	end process;
end behv;