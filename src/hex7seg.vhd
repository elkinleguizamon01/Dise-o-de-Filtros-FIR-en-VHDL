--------------------------------------------------------------------------------
-- hex7seg.vhd   Decodificador a siete segmentos, DE1: activo en BAJO
-- seg(0)=a ... seg(6)=g.   0xC se ve como 'C' y 0xD como 'd'
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity hex7seg is
    port (
        dig : in  std_logic_vector(3 downto 0);
        seg : out std_logic_vector(6 downto 0)    -- g f e d c b a
    );
end entity hex7seg;

architecture rtl of hex7seg is
begin
    with dig select
        seg <= "1000000" when x"0",
               "1111001" when x"1",
               "0100100" when x"2",
               "0110000" when x"3",
               "0011001" when x"4",
               "0010010" when x"5",
               "0000010" when x"6",
               "1111000" when x"7",
               "0000000" when x"8",
               "0010000" when x"9",
               "0001000" when x"A",
               "0000011" when x"B",
               "1000110" when x"C",
               "0100001" when x"D",
               "0000110" when x"E",
               "0001110" when others;
end architecture rtl;
