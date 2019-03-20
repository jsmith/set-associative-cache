-- Cache size should be 32 words of 16 bits (4 sets of 2 lines with 4 words in each line).
-- 2 lines / set
-- 4 sets
-- 4 words / line
-- 2 bits word
-- 2 bits set
-- 8 bits tag
-- ---------------
-- State Machines
-- So there are two state machines. 
-- 1. The first is used to check hit/miss and handles the reading/writing to and from memory.
-- 2. The second handles the hit/misses. There will be a different response depending on whether we are reading or writing.
-- The second state machine is neccesary to avoid code duplication. It is executed sequentially after the first state machine
-- has complete.

library	ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
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
	D_block_in: out std_logic_vector(63 downto 0);
	D_block_addr: out std_logic_vector(9 downto 0);
	D_mem_read: out std_logic;
	D_write_back: out std_logic;
	D_hit: out std_logic;
	D_initialized: out std_logic_vector(7 downto 0);
	D_dirty: out std_logic_vector(7 downto 0);
	D_lru: out std_logic_vector(7 downto 0);
	D_set_int: out std_logic_vector(2 downto 0);
	D_tag: out std_logic_vector(7 downto 0);
	D_set: out std_logic_vector(1 downto 0);
	D_word: out std_logic_vector(1 downto 0);
	D_out_less_sig: out std_logic_vector(15 downto 0);
	D_most_less_sig: out std_logic_vector(15 downto 0);
	D_temp: out std_logic;
	D_target_line: out std_logic_vector(2 downto 0)
);
end cache;

architecture behv of cache	is			

	type cache_type is array (0 to 7) of std_logic_vector(63 downto 0);
	signal cache_mem: cache_type;
	
	type tag_type is array (0 to 7) of std_logic_vector(7 downto 0);
	signal tmp_tags: tag_type;
	
	signal initialized: std_logic_vector(7 downto 0);
	signal dirty: std_logic_vector(7 downto 0);
	signal lru: std_logic_vector(7 downto 0);

	signal tag: std_logic_vector(7 downto 0);
	signal set: std_logic_vector(1 downto 0);
	signal word: std_logic_vector(1 downto 0);
	
	signal mem_read: std_logic;
	signal mem_write: std_logic;

	signal prev_cpu_read: std_logic;
	signal prev_cpu_write: std_logic;
	
	signal block_out: std_logic_vector(63 downto 0);
	signal block_in: std_logic_vector(63 downto 0);
	signal block_addr: std_logic_vector(9 downto 0); 
	
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
	variable target_line: integer;
	variable is_hit: std_logic;
	variable set_int: integer;
	variable write_back: std_logic;

	type states is (
		StartRead, 
		MissRead, 
		FinishRead, 
		Write, 
		WaitState, 
		Delay, 
		WriteFinish
	);
	variable state: states;
	variable delay_state: states;
	
	type response_states is (ReadHit, WriteHit, ReadMiss, HitWaitState);
	variable response_state: response_states;
	variable hit_state: response_states;
	variable miss_state: response_states;
	begin
		-- Initialize signals for operations
		tag <= cpu_addr(11 downto 4);
		set <= cpu_addr(3 downto 2);
		word <= cpu_addr(1 downto 0);
		block_addr <= cpu_addr(11 downto 2);
		
		if (rst = '1') then
			cache_mem <= (others => x"0000000000000000");
			state := WaitState;
			response_state := HitWaitState;
			miss_state := HitWaitState;
			hit_state := HitWaitState;
			initialized <= x"00";
			dirty <= x"00";
			lru <= x"00";
			tmp_tags <= (others => x"00");
			mem_read <= '0';
			mem_write <= '0';
			block_in <= x"0000000000000000";
			read_complete <= '0';
			write_complete <= '0';
			prev_cpu_read <= '0';
			prev_cpu_write <= '0';
			D_temp <= '0';
		elsif (clock'event and clock='1') then
			-- Cache read
			set_int := conv_integer(set) * 2;
			D_set_int <= std_logic_vector(to_unsigned(set_int, 3));
			
			-- The following two if statements check for events on the read and write signals
			-- If the signal -> 1, then start the read / write process
			-- else the signal -> 0, meaning we should stop cache execution by putting it in a wait state
			-- This is important since we moved the state machine out of the if statements
			if prev_cpu_read /= cpu_read then
				if cpu_read = '1' and cpu_write = '0' then
					state := StartRead;
					hit_state := ReadHit;
					miss_state := ReadMiss;
				else
					read_complete <= '0';
					state := WaitState;					
				end if;
			end if;

			if prev_cpu_write /= cpu_write then
				if cpu_write = '1' and cpu_read = '0' then
					state := StartRead;
					hit_state := WriteHit;
					miss_state := WriteHit;
				else
					read_complete <= '0';
					state := WaitState;			
				end if;
			end if;

			prev_cpu_read <= cpu_read;
			prev_cpu_write <= cpu_write;
			
			case state is
				when StartRead =>
					-- Check "Hit"
					-- We loop 0 to 1 because we there are two cache lines
					is_hit := '0';
					for i in 0 to 1 loop
						if tag = tmp_tags(set_int + i) and initialized(set_int + i) = '1' then
							response_state := hit_state;
							target_line := set_int + i;
							state := WaitState;
							is_hit := '1';
							exit;
						end if;
					end loop;
					
					-- Cache "Miss"
					if is_hit = '0' then
						
						-- The following commentes describe the line replacement algorithm
						-- if set != initialized => replace
						-- elif set + 1 != initialized => replace
						-- elif (set == dirty and set + 1 == dirty) or (set != dirty and set + 1 != dirty) =>
						--     if set == lru => replace set + 1
						-- 	   else replace set
						-- elif set = dirty => replace set + 1
						-- else replace set

						-- overwite line / move to later state as mem_read is not set to 1 yet.
						
						write_back := '0';
						if initialized(set_int) = '0' then
							target_line := set_int;
						elsif initialized(set_int + 1) = '0' then
							target_line := set_int + 1;
						elsif dirty(set_int) = dirty(set_int + 1) then
							-- Ok so they are either both dirty or both not dirty
							-- set write_back to one of the dirty values (they will both be the same)
							write_back := dirty(set_int);

							if lru(set_int) = '1' then
								target_line := set_int + 1;
							else
								target_line := set_int;
							end if;
						else
							if dirty(set_int) = '1' then
								target_line := set_int + 1;
							else
								target_line := set_int;
							end if;
						end if;
						
						D_write_back <= write_back;
						
						if write_back = '1' then
							mem_write <= '1';
							block_in <= cache_mem(target_line);
							state := Write;
						else
							mem_read <= '1';
							state := MissRead;
						end if;
					end if;
					
					-- This will update the LRU whether there is a hit or miss
					lru(target_line) <= '1';

					-- A little trick to set the other line in the set to 0
					-- For example, if target_line = 0, set lru(1) <= '0'
					-- And if target_line = 1, set lru(0) <= '0'
					if target_line mod 2 = 0 then
						lru(target_line + 1) <= '0';
					else
						lru(target_line - 1) <= '0';
					end if;
					
					-- Output the debug signals here because we are using variables
					D_target_line <= std_logic_vector(to_unsigned(target_line, D_target_line'length));
					D_hit <= is_hit;
				
				when Write =>
					delay_state := WriteFinish;
					state := Delay;
				
				when WriteFinish =>
					mem_write <= '0';
					mem_read <= '1';
					state := MissRead;

				when MissRead =>
					delay_state := FinishRead;
					state := Delay;
				
				when Delay =>
					state := delay_state;

				when FinishRead =>
					cache_mem(target_line) <= block_out;
					dirty(target_line) <= '0';
					initialized(target_line) <= '1';
					tmp_tags(target_line) <= tag;

					response_state := miss_state;
					
					mem_read <= '0';
					state := WaitState;
				when WaitState =>
			end case;
			
			case response_state is
				when ReadHit =>
					read_complete <= '1';
					D_temp <= '1';
					case word is
						when "00" =>
							data_out <= cache_mem(target_line)(15 downto 00);
						when "01" =>
							data_out <= cache_mem(target_line)(31 downto 16);
						when "10" =>
							data_out <= cache_mem(target_line)(47 downto 32);
						when "11" =>
							data_out <= cache_mem(target_line)(63 downto 48);
					end case;
					response_state := HitWaitState;
				when WriteHit =>
					dirty(set_int) <= '1';
					write_complete <= '1';
					-- TODO Order might be whack
					case word is
						when "00" => 
							cache_mem(target_line)(15 downto 00) <= data_in;
						when "01" => 
							cache_mem(target_line)(31 downto 16) <= data_in;
						when "10" => 
							cache_mem(target_line)(47 downto 32) <= data_in;
						when "11" => 
							cache_mem(target_line)(63 downto 48) <= data_in;
					 end case;
					 response_state := HitWaitState;
				when ReadMiss =>
					read_complete <= '1';
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
					 response_state := HitWaitState;
				when HitWaitState =>
					-- DO Nothing
			end case;

		end if;
	end process;

	D_block_out <= block_out;
	D_block_in <= block_in;
	D_block_addr <= block_addr;
	D_mem_read <= mem_read;
--	D_hit <= is_hit;
	D_initialized <= initialized;
	D_dirty <= dirty;
	D_lru <= lru;
--	D_set_int <= std_logic_vector(to_unsigned(set_int, 3));
	D_tag <= tag;
	D_set <= set;
	D_word <= word;
end behv;