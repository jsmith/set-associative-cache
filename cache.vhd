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
	D_block_addr: out std_logic_vector(11 downto 0);
	D_mem_read: out std_logic
);
end cache;

architecture behv of cache	is			

	type cache_type is array (0 to 7) of std_logic_vector(63 downto 0);
	signal tmp_cache: cache_type;
	
	type tag_type is array (0 to 7) of std_logic_vector(7 downto 0);
	signal tmp_tag: tag_type;
	
	signal initialized: std_logic_vector(7 downto 0);
	signal dirty: std_logic_vector(7 downto 0);
	
	signal lru: std_logic_vector(7 downto 0);
	
	type read_states is (StartRead, MissRead, FinishRead, WaitState, Delay);
	signal read_state: read_states;
	signal delay_state: read_states;

	type write_states is (WriteStart);
	signal write_state: write_states;

	signal tag: std_logic_vector(7 downto 0);
	signal set: std_logic_vector(1 downto 0);
	signal word: std_logic_vector(1 downto 0);
	
	signal mem_read: std_logic;
	signal mem_write: std_logic;
	
	signal block_out: std_logic_vector(63 downto 0);
	signal block_in: std_logic_vector(63 downto 0);
	signal block_addr: std_logic_vector(11 downto 0); 

	signal is_hit: std_logic;
	signal write_back: std_logic;
	
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
	variable read_line: integer;
	begin
		tag <= cpu_addr(11 downto 4);
		set <= cpu_addr(3 downto 2);
		word <= cpu_addr(1 downto 0);
		
		block_addr <= cpu_addr(11 downto 2) & "00";
		
		if (rst = '1') then
			tmp_cache <= (others => x"0000000000000000");
			read_state <= StartRead;
			write_state <= WriteState;
			initialized <= x"00";
			dirty <= x"00";
			tmp_tag <= (others => x"00");
			mem_read <= '0';			
		elsif (clock'event and clock='1') then
			-- Cache read
			if (cpu_read = '1' and cpu_read'event and cpu_write = '0') then
				set_int := conv_integer(set) * 2;
				read_state <= StartWrite;

				case read_state is
					when StartRead =>			
						-- Check "Hit"
						-- loop 0 and 1

						is_hit <= '0';
						for i in 0 to 1 loop
							if (tag = tmp_tag(set_int + i) and initialized(set_int + i) = '1') then
								case word is
									when "00" =>
										data_out <= tmp_cache(set_int + i)(63 downto 48);
									when "01" =>
										data_out <= tmp_cache(set_int + i)(47 downto 32);
									when "10" =>
										data_out <= tmp_cache(set_int + i)(31 downto 16);
									when "11" =>
										data_out <= tmp_cache(set_int + i)(15 downto 00);
								end case;
								
								lru(set_int + i) <= '1';
								lru((set_int + i + 1) mod 2) <= '0';
								read_complete <= '1';
								read_state <= FinishRead;
								is_hit <= '1';
								exit;
							end if;
						end loop;

						-- Cache "Miss"
						if (is_hit = '0') then

							-- if set != initialized => replace
							-- elif set + 1 != initialized => replace
							-- elif (set == dirty and set + 1 == dirty) or (set != dirty and set + 1 != dirty) =>
							--     if set == lru => replace set + 1
							-- 	   else replace set
							-- elif set = dirty => replace set + 1
							-- else replace set

							-- overwite line / move to later read_state as mem_read is not set to 1 yet.
							
							write_back <= '0'
							if initialized(set_int) = '0' then
								read_line <= set_int;
							elsif initialized(set_int + 1) = '0' then
								read_line <= set_int + 1;
							elsif dirty(set_int) = dirty(set_int + 1) then
								-- Ok so they are either both dirty or both not dirty
								-- set write_back to one of the dirty values (they will both be the same)
								write_back = dirty(set_int);

								if lru(set_int) = '1' then
									read_line <= set_int + 1;
								else
									read_line <= set_int;
								end if;
							else
								if dirty(set_int) = '1' then
									read_line <= set_int + 1;
								else
									read_line <= set_int;
								end if;
							end if;
							
							if write_back = '1' then
								mem_write = '1';
								block_in <= tmp_cache(read_line);
								read_state <= Write;
							else
								mem_read <= '1';
								read_state <= MissRead;
							end if;
						end if;
					
					when Write =>
						delay_state <= WriteFinish;
						read_state <= Delay;
					
					when WriteFinish =>
						mem_write <= '0';
						mem_read <= '1'
						read_state <= MissRead

					when MissRead =>
						delay_state <= FinishRead;
						read_state <= Delay;
					
					when Delay =>
						read_state <= delay_state;

					when FinishRead =>
						tmp_cache(read_line) <= block_out;
						dirty(read_line) <= '0';
						initialized(read_line) <= '1';
						lru(read_line) <= '0';
						tmp_tags(read_line) <= tag;
						
						case word is
							when "00" =>
								data_out <= block_out(15 downto 00);
							when "01" =>
								data_out <= block_out(31 downto 16);	
							when "10" =>
								data_out <= block_out(47 downto 32);	
							when "11" =>
								data_out <= block_out(63 downto 48);
						end case;
						
						read_complete <= '1';
						mem_read <= '0';
						read_state <= WaitState;
					when WaitState =>
						read_complete <= '1';
				end case;

			-- Write to memory (set in cache and set to dirty)
			elsif cpu_read = '0' and cpu_write = '1' then
				read_state <= StartRead;

				case write_state is
					when StartWrite =>
						z
				end case;
			end if;
			
		end if;
	end process;

	D_mem_read <= mem_read;
	D_block_out <= block_out;
	D_block_addr <= block_addr;
end behv;