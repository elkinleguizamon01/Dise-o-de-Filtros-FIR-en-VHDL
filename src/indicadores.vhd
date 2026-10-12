--------------------------------------------------------------------------------
-- indicadores.vhd
-- led_muestreo : conmuta cada DIV_LED conversiones (a 320 Hz, 160 -> parpadeo 1 Hz)
-- led_satura   : '1' si el ultimo codigo es 0 o 255
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity indicadores is
    generic ( DIV_LED : positive := 160 );
    port (
        clk, rst       : in  std_logic;
        muestra_valida : in  std_logic;
        muestra        : in  unsigned(7 downto 0);
        led_muestreo   : out std_logic;
        led_satura     : out std_logic
    );
end entity indicadores;

architecture rtl of indicadores is
    signal cnt : integer range 0 to DIV_LED-1 := 0;
    signal led : std_logic := '0';
begin
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                cnt <= 0;
                led <= '0';
            elsif muestra_valida = '1' then
                if cnt = DIV_LED-1 then
                    cnt <= 0;
                    led <= not led;
                else
                    cnt <= cnt + 1;
                end if;
            end if;
        end if;
    end process;
    led_muestreo <= led;
    led_satura   <= '1' when (muestra = 0 or muestra = 255) else '0';
end architecture rtl;
