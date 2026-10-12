--------------------------------------------------------------------------------
-- escala_temp.vhd
-- T_decimas = (y_frac * K) >> SH
-- ADC0808: 8 bits, Vfs = 5 V, y_frac con 4 bits fraccionarios
--   factor = 5/255/16 * 110 = 0,134804 ; SH = 14 ; K = round(2^14 * factor) = 2209
-- El valor mostrado se actualiza cada REFRESCO muestras (80 -> 4 Hz).
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity escala_temp is
    generic (
        K        : natural  := 2209;
        SH       : natural  := 14;
        IN_W     : positive := 12;
        REFRESCO : positive := 80
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        y_valid  : in  std_logic;
        y_in     : in  unsigned(IN_W-1 downto 0);
        temp_dec : out unsigned(9 downto 0)      -- decimas de grado
    );
end entity escala_temp;

architecture rtl of escala_temp is
    signal cnt   : integer range 0 to REFRESCO-1 := 0;
    signal temp_r : unsigned(9 downto 0) := (others => '0');
begin
    process (clk)
        variable prod : unsigned(IN_W+11 downto 0);
        variable t    : unsigned(IN_W+11 downto 0);
    begin
        if rising_edge(clk) then
            if rst = '1' then
                cnt    <= 0;
                temp_r <= (others => '0');
            elsif y_valid = '1' then
                prod := y_in * to_unsigned(K, 12);
                t    := shift_right(prod, SH);
                if cnt = REFRESCO-1 then
                    cnt <= 0;
                    if t > 1023 then
                        temp_r <= (others => '1');
                    else
                        temp_r <= t(9 downto 0);
                    end if;
                else
                    cnt <= cnt + 1;
                end if;
            end if;
        end if;
    end process;
    temp_dec <= temp_r;
end architecture rtl;
