-- Modelo simple del ADC0808: EOC baja tras START y sube 100 us despues.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_adc0808 is end entity;

architecture sim of tb_adc0808 is
    constant T : time := 20 ns;
    signal clk, rst, fsclk : std_logic := '0';
    signal adc_clk, adc_start, adc_oe : std_logic;
    signal adc_eoc : std_logic := '1';
    signal adc_d   : std_logic_vector(7 downto 0);
    signal muestra : unsigned(7 downto 0);
    signal valida  : std_logic;
    signal fin : boolean := false;
begin
    clk <= not clk after T/2 when not fin else clk;

    dut : entity work.adc0808_ctrl
        port map (clk, rst, fsclk, adc_clk, adc_start, adc_oe, adc_eoc, adc_d,
                  muestra, valida);

    -- modelo del ADC
    process
    begin
        wait until falling_edge(adc_start);
        wait for 10 us;  adc_eoc <= '0';
        wait for 100 us; adc_eoc <= '1';
    end process;
    adc_d <= x"A5" when adc_oe = '1' else "ZZZZZZZZ";

    process
    begin
        rst <= '1'; wait for 5 * T; rst <= '0'; wait for 10 * T;
        for k in 1 to 2 loop
            wait until rising_edge(clk); fsclk <= '1';
            wait until rising_edge(clk); fsclk <= '0';
            wait until rising_edge(valida) for 400 us;
            assert valida = '1' report "No llego dato valido" severity error;
            wait for T/2;
            assert muestra = x"A5" report "Muestra incorrecta" severity error;
            wait for 200 us;
        end loop;
        report "tb_adc0808 terminado" severity note;
        fin <= true; wait;
    end process;
end architecture;
