library ieee;
use ieee.std_logic_1164.all;  
use ieee.numeric_std.all;			   
use work.MP_lib.all;

entity memory is
port(
	clock: in std_logic;
	reset: in std_logic;
	rden: in std_logic;
	wren: in std_logic;
	address: in std_logic_vector(11 downto 0);
	data_in: in std_logic_vector(15 downto 0);
	data_out: out std_logic_vector(15 downto 0);
	read_done: out std_logic;
	write_done: out std_logic
);
end memory;

architecture bhv of memory is

constant delay: integer := 11;
signal read_counter: integer := 0;
signal write_counter: integer := 0;
signal m4k_in: std_logic_vector(15 downto 0);
signal m4k_out: std_logic_vector(15 downto 0);

begin
Unit0: m4k_ram port map(
	address,
	clock,
	m4k_in,
	rden,
	wren,
	data_out
);

read: process(clock, reset, rden)
begin
	if reset = '1' then
		-- data_out <= std_logic_vector(to_unsigned(0,16));
		read_done <= '0';
		read_counter <= 0;
	else
		if (rden = '1' and wren = '0') then
			if (clock'event and clock = '1') then
				if (read_counter = delay) then
					-- data_out <= m4k_out;
					read_done <= '1';
				else
					read_counter <= read_counter + 1;
				end if;
			end if;
		else
			read_done <= '0';
			read_counter <= 0;
		end if;
	end if;
end process;

write: process(clock, reset, wren)
begin
	if reset = '1' then
		write_done <= '0';
		write_counter <= 0;
	else
		if (wren = '1' and rden = '0') then
			if (clock'event and clock = '1') then
				if (write_counter = delay) then
					m4k_in <= data_in;
					write_done <= '1';
				else
					write_counter <= write_counter + 1;
				end if;
			end if;
		else
			write_done <= '0';
			write_counter <= 0;
		end if;
	end if;
end process;

end bhv;
