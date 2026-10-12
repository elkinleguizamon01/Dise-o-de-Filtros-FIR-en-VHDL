--------------------------------------------------------------------------------
-- bin_a_bcd.vhd   Doble-dabble combinacional, 3 digitos BCD
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bin_a_bcd is
    generic ( BITS : positive := 10 );
    port (
        bin : in  unsigned(BITS-1 downto 0);
        bcd : out std_logic_vector(11 downto 0)   -- centenas, decenas, unidades
    );
end entity bin_a_bcd;

architecture rtl of bin_a_bcd is
begin
    process (bin)
        variable sh : unsigned(BITS+11 downto 0);
    begin
        sh := (others => '0');
        sh(BITS-1 downto 0) := bin;
        for i in 0 to BITS-1 loop
            for d in 0 to 2 loop
                if sh(BITS+4*d+3 downto BITS+4*d) > 4 then
                    sh(BITS+4*d+3 downto BITS+4*d) :=
                        sh(BITS+4*d+3 downto BITS+4*d) + 3;
                end if;
            end loop;
            sh := shift_left(sh, 1);
        end loop;
        bcd <= std_logic_vector(sh(BITS+11 downto BITS));
    end process;
end architecture rtl;
