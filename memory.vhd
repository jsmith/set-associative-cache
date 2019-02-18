--------------------------------------------------------
-- SSimple Computer Architecture
--
-- memory 256*16
-- 8 bit address; 16 bit data
-- memory.vhd
--------------------------------------------------------

library	ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;   
use work.MP_lib.all;

entity memory is
port ( 	clock	: 	in std_logic;
		rst		: 	in std_logic;
		Mre		:	in std_logic;
		Mwe		:	in std_logic;
		address	:	in std_logic_vector(7 downto 0);
		data_in	:	in std_logic_vector(15 downto 0);
		data_out:	out std_logic_vector(15 downto 0)
);
end memory;

architecture behv of memory	 is			

type ram_type is array (0 to 255) of std_logic_vector(15 downto 0);
signal tmp_ram: ram_type;
begin
	write: process(clock, rst, Mre, address, data_in)
	begin				-- program to generate 10 fabonacci number	 
		if rst='1' then		
			tmp_ram <= (
            	-- Do initial setup.
					
				0 => x"3001",
				1 => x"3132",
				2 => x"32C8",
				3 => x"4312",
				4 => x"2320",
				5 => x"5220",
				6 => x"0433",
				7 => x"6403",
				8 => x"7000",
				9 => x"3196",
				10 => x"32FA",
				11 => x"A410",
				12 => x"A520",
				13 => x"5454",
				14 => x"2140",
				15 => x"5110",
				16 => x"5220",
				17 => x"0332",
				18 => x"630B",
				19 => x"7032",
				20 => x"7033",
				21 => x"703C",
				22 => x"7046",
				23 => x"7050",
				24 => x"F000",
				
				others => x"0000");
		else
			if (clock'event and clock = '1') then
				if (Mwe ='1' and Mre = '0') then
					tmp_ram(conv_integer(address)) <= data_in;
				end if;
			end if;
		end if;
	end process;

    read: process(clock, rst, Mwe, address)
	begin
		if rst='1' then
			data_out <= ZERO;
		else
			if (clock'event and clock = '1') then
				if (Mre ='1' and Mwe ='0') then								 
					data_out <= tmp_ram(conv_integer(address));
				end if;
			end if;
		end if;
	end process;
end behv;