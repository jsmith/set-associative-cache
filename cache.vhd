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
	D_block_addr: out std_logic_vector(11 downto 0);
	D_mem_read: out std_logic;
	D_write_back: out std_logic;
	D_hit: out std_logic;
	D_initialized: out std_logic_vector(7 downto 0);
	D_dirty: out std_logic_vector(7 downto 0);
	D_lru: out std_logic_vector(7 downto 0)
);
end cache;

architecture behv of cache	is			

	type cache_type is array (0 to 7) of std_logic_vector(63 downto 0);
	signal tmp_cache: cache_type;
	
	type tag_type is array (0 to 7) of std_logic_vector(7 downto 0);
	signal tmp_tags: tag_type;
	
	-- TODO bad naming. Shouldn't be called hit_states and hit_state.
	type hit_states is (ReadHit, WriteHit, ReadMiss, HitWaitState);
	signal hit_state: hit_states;
	signal miss_state: hit_states;
	signal current_hit_state: hit_states;

	signal initialized: std_logic_vector(7 downto 0);
	signal dirty: std_logic_vector(7 downto 0);
	
	signal lru: std_logic_vector(7 downto 0);
	
	type states is (
		StartRead, 
		MissRead, 
		FinishRead, 
		Write, 
		WaitState, 
		Delay, 
		WriteFinish
	);
	signal state: states;
	signal delay_state: states;

	signal tag: std_logic_vector(7 downto 0);
	signal set: std_logic_vector(1 downto 0);
	signal word: std_logic_vector(1 downto 0);
	
	signal mem_read: std_logic;
	signal mem_write: std_logic;

	signal prev_cpu_read: std_logic;
	signal prev_cpu_write: std_logic;
	
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
	variable set_int: integer; -- TODO Rename this
	variable read_line: integer; -- TODO Rename this
	begin
		tag <= cpu_addr(11 downto 4);
		set <= cpu_addr(3 downto 2);
		word <= cpu_addr(1 downto 0);
		
		block_addr <= cpu_addr(11 downto 2) & "00";
		
		if (rst = '1') then
			tmp_cache <= (others => x"0000000000000000");
			state <= WaitState;
			hit_state <= HitWaitState;
			initialized <= x"00";
			dirty <= x"00";
			tmp_tags <= (others => x"00");
			mem_read <= '0';
			read_complete <= '0';
			write_complete <= '0';
			prev_cpu_read <= '0';
			prev_cpu_write <= '0';	
		elsif (clock'event and clock='1') then
			-- Cache read
			set_int := conv_integer(set) * 2;

			-- The following two if statements check for events on the read and write signals
			-- If the signal -> 1, then start the read / write process
			-- else the signal -> 0, meaning we should stop cache execution by putting it in a wait state
			-- This is important since we moved the state machine out of the if statements
			if prev_cpu_read /= cpu_read then
				if cpu_read = '1' and cpu_write = '0' then
					set_int := conv_integer(set) * 2;
					state <= StartRead;
				else
					read_complete <= '0'; -- TODO Is this the right location?
					state <= WaitState;					
				end if;
			end if;

			if prev_cpu_write /= cpu_write then
				if cpu_write = '1' and cpu_read = '0' then
					set_int := conv_integer(set) * 2;
					state <= StartRead;
					hit_state <= WriteHit;
					miss_state <= WriteHit;
				else
					read_complete <= '0'; -- TODO Same thing here. I think there is a better location.
					state <= WaitState;
					hit_state <= ReadHit;
					miss_state <= ReadMiss;			
				end if;
			end if;

			prev_cpu_read <= cpu_read;
			prev_cpu_write <= cpu_write;
			
			case state is
				when StartRead =>
					-- Check "Hit"
					-- loop 0 and 1

					is_hit <= '0';
					for i in 0 to 1 loop
						if tag = tmp_tags(set_int + i) and initialized(set_int + i) = '1' then
							current_hit_state <= hit_state;
							read_line := set_int + i;
							lru(set_int + i) <= '1';
							lru((set_int + i + 1) mod 2) <= '0';
							state <= WaitState;
							is_hit <= '1';
							exit;
						end if;
					end loop;

					-- Cache "Miss"
					if is_hit = '0' then

						-- if set != initialized => replace
						-- elif set + 1 != initialized => replace
						-- elif (set == dirty and set + 1 == dirty) or (set != dirty and set + 1 != dirty) =>
						--     if set == lru => replace set + 1
						-- 	   else replace set
						-- elif set = dirty => replace set + 1
						-- else replace set

						-- overwite line / move to later state as mem_read is not set to 1 yet.
						
						write_back <= '0';
						if initialized(set_int) = '0' then
							read_line := set_int;
						elsif initialized(set_int + 1) = '0' then
							read_line := set_int + 1;
						elsif dirty(set_int) = dirty(set_int + 1) then
							-- Ok so they are either both dirty or both not dirty
							-- set write_back to one of the dirty values (they will both be the same)
							write_back <= dirty(set_int);

							if lru(set_int) = '1' then
								read_line := set_int + 1;
							else
								read_line := set_int;
							end if;
						else
							if dirty(set_int) = '1' then
								read_line := set_int + 1;
							else
								read_line := set_int;
							end if;
						end if;
						
						if write_back = '1' then
							mem_write <= '1';
							block_in <= tmp_cache(read_line);
							state <= Write;
						else
							mem_read <= '1';
							state <= MissRead;
						end if;
					end if;
				
				when Write =>
					delay_state <= WriteFinish;
					state <= Delay;
				
				when WriteFinish =>
					mem_write <= '0';
					mem_read <= '1';
					state <= MissRead;

				when MissRead =>
					delay_state <= FinishRead;
					state <= Delay;
				
				when Delay =>
					state <= delay_state;

				when FinishRead =>
					tmp_cache(read_line) <= block_out;
					dirty(read_line) <= '0';
					initialized(read_line) <= '1';
					lru(read_line) <= '0';
					tmp_tags(read_line) <= tag;

					current_hit_state <= miss_state;
					
					mem_read <= '0';
					state <= WaitState;
				when WaitState =>
			end case;
			
			case hit_state is
				when ReadHit =>
					read_complete <= '1';
					case word is
						when "00" =>
							data_out <= tmp_cache(read_line)(63 downto 48);
						when "01" =>
							data_out <= tmp_cache(read_line)(47 downto 32);
						when "10" =>
							data_out <= tmp_cache(read_line)(31 downto 16);
						when "11" =>
							data_out <= tmp_cache(read_line)(15 downto 00);
					end case;
				when WriteHit =>
					dirty(set_int) <= '1';
					write_complete <= '1';
					-- TODO Order might be whack
					case word is
						when "00" => 
							tmp_cache(read_line)(63 downto 48) <= data_in;
						when "01" => 
							tmp_cache(read_line)(47 downto 32) <= data_in;
						when "10" => 
							tmp_cache(read_line)(31 downto 16) <= data_in;
						when "11" => 
							tmp_cache(read_line)(15 downto 00) <= data_in;
					end case;
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
				when HitWaitState =>
					-- DO Nothing
			end case;

		end if;
	end process;

	D_block_out <= block_out;
	D_block_in <= block_in;
	D_block_addr <= block_addr;
	D_mem_read <= mem_read;
	D_write_back <= write_back;
	D_hit <= is_hit;
	D_initialized <= initialized;
	D_dirty <= dirty;
	D_lru <= lru;
end behv;