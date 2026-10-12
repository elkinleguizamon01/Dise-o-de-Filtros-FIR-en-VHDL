-- Verifica: periodo exacto de fsclk, desfase de medio periodo de pert y
-- las cuatro secuencias del selector (DIV reducido para simular rapido).
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_gen_muestreo is end entity;

architecture sim of tb_gen_muestreo is
    constant DIV : positive := 20;
    constant T   : time := 20 ns;
    signal clk, rst : std_logic := '0';
    signal sel : std_logic_vector(1 downto 0) := "00";
    signal fsclk, latido, pert : std_logic;
    signal esperado : integer := 2;      -- muestras por semiciclo (r/2)
    signal fin : boolean := false;
begin
    clk <= not clk after T/2 when not fin else clk;

    dut : entity work.gen_muestreo generic map (DIV_FS => DIV)
        port map (clk, rst, sel, fsclk, latido, pert);

    -- 1) periodo exacto de fsclk
    process
        variable t_prev : time := 0 ns;
    begin
        wait until rising_edge(fsclk);
        if t_prev > 0 ns then
            assert (now - t_prev) = DIV * T
                report "Periodo de fsclk incorrecto" severity error;
        end if;
        t_prev := now;
    end process;

    -- 2) cada flanco de pert ocurre DIV/2 ciclos antes de un fsclk
    process
        variable t_pert : time;
    begin
        wait on pert;
        if now > 6 * T then                  -- ignora la inicializacion
            t_pert := now;
            wait until rising_edge(fsclk);
            assert (now - t_pert) = (DIV/2) * T
                report "Desfase de medio periodo incorrecto" severity error;
        end if;
    end process;

    -- 3) duracion del semiciclo = esperado muestras
    process
        variable t_prev : time := 0 ns;
        variable valido : boolean := false;
    begin
        wait on pert, sel;
        if sel'event or now < 6 * T then
            valido := false;
        elsif pert'event then
            if valido then
                assert (now - t_prev) = esperado * DIV * T
                    report "Semiciclo incorrecto para sel=" &
                           integer'image(to_integer(unsigned(sel))) severity error;
            end if;
            t_prev := now;
            valido := true;
        end if;
    end process;

    process
    begin
        rst <= '1'; wait for 5 * T; rst <= '0';
        for i in 0 to 3 loop
            -- cambio de posicion en un instante CUALQUIERA (peor caso)
            wait for 7 * T + (i * 3) * T;
            sel      <= std_logic_vector(to_unsigned(i, 2));
            esperado <= 2 * 2**i;
            wait for 12 * esperado * DIV * T;
        end loop;
        -- vuelta de 11 a 00 en pleno conteo
        wait for 3 * T;
        sel <= "00"; esperado <= 2;
        wait for 12 * 2 * DIV * T;
        report "tb_gen_muestreo terminado" severity note;
        fin <= true;
        wait;
    end process;
end architecture;
