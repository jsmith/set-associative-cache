library ieee;
use ieee.std_logic_1164.all;

entity seven_seg is
port(
    data_in: in std_logic_vector(3 downto 0); -- Desired Output value
    hex_out: out std_logic_vector(0 to 6) -- Output values for hex display
); 
end seven_seg;

architecture seven_seg_rtl of seven_seg is

begin
    process (data_in)
    begin
			
			-- Set leds of hex based on input value
			case data_in is
				 when X"0" => hex_out <= NOT "1111110";
				 when X"1" => hex_out <= NOT "0110000";
				 when X"2" => hex_out <= NOT "1101101";
				 when X"3" => hex_out <= NOT "1111001";
				 when X"4" => hex_out <= NOT "0110011";
				 when X"5" => hex_out <= NOT "1011011";
				 when X"6" => hex_out <= NOT "1011111";
				 when X"7" => hex_out <= NOT "1110000";
				 when X"8" => hex_out <= NOT "1111111";
				 when X"9" => hex_out <= NOT "1111011";
				 when X"A" => hex_out <= NOT "1110111";
				 when X"B" => hex_out <= NOT "0011111";
				 when X"C" => hex_out <= NOT "0001101";
				 when X"D" => hex_out <= NOT "0111101";
				 when X"E" => hex_out <= NOT "1001111";
				 when X"F" => hex_out <= NOT "1000111";
				 when others => hex_out <= NOT "0000000"; -- Hex off
			end case;
    end process;
end seven_seg_rtl;
