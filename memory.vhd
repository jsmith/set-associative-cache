library ieee;
use ieee.std_logic_1164.all;  
use ieee.numeric_std.all;			   
use work.MP_lib.all;

entity memory is
port(
	clock: in std_logic;
	rst: in std_logic;
	mem_read: in std_logic;
	mem_write: in std_logic;
	block_addr: in std_logic_vector(9 downto 0);
	block_in: in std_logic_vector(63 downto 0);
	block_out: out std_logic_vector(63 downto 0);
	read_complete: out std_logic;
	write_complete: out std_logic
);
end memory;

architecture bhv of memory is

constant delay: integer := 11;
signal read_counter: integer := 0;
signal write_counter: integer := 0;
signal m4k_in: std_logic_vector(63 downto 0);
signal m4k_out: std_logic_vector(63 downto 0);

begin
	Unit1: m4k_ram port map(
		block_addr, 
		clock,
		m4k_in, 
		mem_read, 
		mem_write,
		block_out
	);

read: process(clock, rst, mem_read)
begin
	if rst = '1' then
--		block_out <= std_logic_vector(to_unsigned(0,64));
		read_complete <= '0';
		read_counter <= 0;
	else
		if (mem_read = '1' and mem_write = '0') then
			if (clock'event and clock = '1') then
				if (read_counter = delay) then
--					block_out <= m4k_out;
					read_complete <= '1';
				else
					read_counter <= read_counter + 1;
				end if;
			end if;
		else
			read_complete <= '0';
			read_counter <= 0;
		end if;
	end if;
end process;

write: process(clock, rst, mem_write)
begin
	if rst = '1' then
		write_complete <= '0';
		write_counter <= 0;
	else
		if (mem_write = '1' and mem_read = '0') then
			if (clock'event and clock = '1') then
				if (write_counter = delay) then
					m4k_in <= block_in;
					write_complete <= '1';
				else
					write_counter <= write_counter + 1;
				end if;
			end if;
		else
			write_complete <= '0';
			write_counter <= 0;
		end if;
	end if;
end process;

end bhv;