-- Cache size should be 32 words of 16 bits (4 sets of 2 lines with 4 words in each line).
-- 2 lines / set
-- 4 sets
-- 4 words / line
-- 2 bits word
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
		data_out: out std_logic_vector(15 downto 0);
		read_complete: out std_logic;
		write_complete: out std_logic;
		
		-- Debug Signals
		D_block_out: out std_logic_vector(63 downto 0);
		D_block_addr: out std_logic_vector(11 downto 0)
);
end cache;

architecture behv of cache	is			

	type cache_type is array (0 to 7) of std_logic_vector(63 downto 0);
	signal tmp_cache: cache_type;
	
	type tag_type is array (0 to 7) of std_logic_vector(7 downto 0);
	signal tmp_tag: tag_type;
	
	signal tmp_init: std_logic_vector(7 downto 0);
	
	signal lru: std_logic_vector(7 downto 0);
	
	
	type state_type is (S0, S1, S2);
	signal state: state_type;
	
	signal tag: std_logic_vector(7 downto 0);
	signal set: std_logic_vector(1 downto 0);
	signal word: std_logic_vector(1 downto 0);
	
	signal mem_read: std_logic;
	signal mem_write: std_logic;
	
	signal block_out: std_logic_vector(63 downto 0);
	signal block_in: std_logic_vector(63 downto 0);
	signal block_addr: std_logic_vector(11 downto 0); 

	
	
begin
	Unit1: m4k_ram port map(
		block_addr, 
		clock,
		block_in, 
		mem_read, 
		mem_write,
		block_out
	);

	process(cpu_write, cpu_read, cpu_addr)
	variable set_int: integer;
	begin
		tag <= cpu_addr(11 downto 4);
		set <= cpu_addr(3 downto 2);
		word <= cpu_addr(1 downto 0);
		
		block_addr <= cpu_addr(11 downto 2) & "00";
		
		-- Debug Signal
		D_block_addr <= block_addr;
		
		if (rst = '1') then
			-- TODO the reset stuff
			tmp_cache <= (others => x"0000000000000000");
			state <= S0;
			
		elsif (clock'event and clock='1') then
			-- Cache read
			if (cpu_read = '1' and cpu_write = '0') then
				set_int := conv_integer(set) * 2;
				
				case state is
					when S0 =>			
							-- Check "Hit"
							if (tag = tmp_tag(set_int) and tmp_init(set_int) = '1') then
								case word is
									when "00" =>
										data_out <= tmp_cache(set_int)(63 downto 48);
									when "01" =>
										data_out <= tmp_cache(set_int)(47 downto 32);
									when "10" =>
										data_out <= tmp_cache(set_int)(31 downto 16);
									when "11" =>
										data_out <= tmp_cache(set_int)(15 downto 00);
								end case;
								
								lru(set_int) <= '1';
								lru(set_int + 1) <= '1';
								read_complete <= '1';
								state <= S2;
								
							elsif (tag = tmp_tag(set_int + 1) and tmp_init(set_int + 1) = '1') then
								case word is
									when "00" =>
										data_out <= tmp_cache(set_int+1)(63 downto 48);
									when "01" =>
										data_out <= tmp_cache(set_int+1)(47 downto 32);
									when "10" =>
										data_out <= tmp_cache(set_int+1)(31 downto 16);
									when "11" =>
										data_out <= tmp_cache(set_int+1)(15 downto 00);
								end case;
								
								lru(set_int) <= '1';
								lru(set_int + 1) <= '1';
								read_complete <= '1';
								state <= S2;
								
							-- Cache "Miss"
							else
								mem_read <= '1';
								state <= S1;
							end if;
					when S1 =>
						-- Debugging
						D_block_out <= block_out;
						
						tmp_cache(set_int) <= block_out;
						
						-- Need to set the tmp_tags
						
						case word is
							when "00" =>
								data_out <= block_out(63 downto 48);
							when "01" =>
								data_out <= block_out(47 downto 32);
							when "10" =>
								data_out <= block_out(31 downto 16);
							when "11" =>
								data_out <= block_out(15 downto 00);
						end case;
						
						mem_read <= '0';
						state <= S2;
					when S2 =>
						read_complete <= '1';
					when others =>
				end case;
			end if;
			
		end if;
	end process;
end behv;