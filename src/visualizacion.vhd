--------------------------------------------------------------------------------
-- visualizacion.vhd
-- SW3 = 0 : HEX3 = 'C', HEX2..HEX0 = temperatura en decimas (249 -> 24.9 C)
-- SW3 = 1 : HEX3 = 'd', HEX2..HEX0 = codigo crudo del ADC (0..255)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity visualizacion is
    port (
        sw3      : in  std_logic;
        temp_dec : in  unsigned(9 downto 0);
        crudo    : in  unsigned(7 downto 0);
        hex0, hex1, hex2, hex3 : out std_logic_vector(6 downto 0)
    );
end entity visualizacion;

architecture rtl of visualizacion is
    signal valor : unsigned(9 downto 0);
    signal bcd   : std_logic_vector(11 downto 0);
    signal d3    : std_logic_vector(3 downto 0);
begin
    valor <= temp_dec when sw3 = '0' else resize(crudo, 10);
    d3    <= x"C"     when sw3 = '0' else x"D";

    u_bcd : entity work.bin_a_bcd generic map (BITS => 10)
        port map (bin => valor, bcd => bcd);

    u_h0 : entity work.hex7seg port map (dig => bcd(3 downto 0),  seg => hex0);
    u_h1 : entity work.hex7seg port map (dig => bcd(7 downto 4),  seg => hex1);
    u_h2 : entity work.hex7seg port map (dig => bcd(11 downto 8), seg => hex2);
    u_h3 : entity work.hex7seg port map (dig => d3,               seg => hex3);
end architecture rtl;
