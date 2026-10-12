-- Prueba del FIR: (1) entrada constante 100 -> salida 100 (ganancia DC = 1)
--                 (2) impulso -> la salida reproduce los coeficientes
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_fir is end entity;

architecture sim of tb_fir is
    constant T : time := 20 ns;
    signal clk, rst, x_valid : std_logic := '0';
    signal x_in   : unsigned(7 downto 0) := (others => '0');
    signal y_valid : std_logic;
    signal y_out  : unsigned(7 downto 0);
    signal y_frac : unsigned(11 downto 0);
    signal fin : boolean := false;

    procedure muestrear (signal xv : out std_logic; signal xi : out unsigned(7 downto 0);
                         v : in natural) is
    begin
        wait until rising_edge(clk);
        xi <= to_unsigned(v, 8); xv <= '1';
        wait until rising_edge(clk);
        xv <= '0';
        wait for 50 * T;                       -- >= N+2 = 35 ciclos
    end procedure;
begin
    clk <= not clk after T/2 when not fin else clk;
    dut : entity work.fir_filter port map (clk, rst, x_valid, x_in, y_valid, y_out, y_frac);

    process
    begin
        rst <= '1'; wait for 5 * T; rst <= '0';
        -- (1) escalon de 100
        for i in 1 to 40 loop muestrear(x_valid, x_in, 100); end loop;
        assert y_out = 100 and y_frac = 1600
            report "Ganancia DC distinta de 1: y_out=" & integer'image(to_integer(y_out))
            severity error;
        -- (2) impulso de 160 (reset del buffer con ceros)
        for i in 1 to 40 loop muestrear(x_valid, x_in, 0); end loop;
        muestrear(x_valid, x_in, 160);
        -- h[0] = 0 ; tras 16 muestras mas aparece el maximo h[16] = 0x2C00/32768
        for i in 1 to 16 loop muestrear(x_valid, x_in, 0); end loop;
        -- 160 * 11264/32768 = 55 (con 4 bits fraccionarios -> 880)
        assert y_frac = 880 report "Pico del impulso incorrecto: " &
            integer'image(to_integer(y_frac)) severity error;
        report "tb_fir terminado" severity note;
        fin <= true; wait;
    end process;
end architecture;
