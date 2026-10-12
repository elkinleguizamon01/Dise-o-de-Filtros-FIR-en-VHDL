--------------------------------------------------------------------------------
-- top.vhd   Nivel superior, S = 64 (Fs = 320 Hz, Fpass = 30 Hz)
-- Solo instancias + inversion de KEY[0] + multiplexor de derivacion SW[2].
-- Pines GPIO_0 (segun el cableado del montaje):
--   0 pert | 1 latido | 2 ADC_CLK | 3 ALE | 4 START | 5 OE | 6 EOC
--   14..7 ADC_D0..D7 | 15 libre | 23..16 DAC R-2R (bit 0 .. bit 7)
--   ADD A,B,C del ADC0808 a GND en la protoboard.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lab2_top is
    generic (
        DIV_FS : positive := 156250     -- 50 MHz / 320 Hz
    );
    port (
        CLOCK_50 : in    std_logic;
        KEY      : in    std_logic_vector(0 downto 0);
        SW       : in    std_logic_vector(3 downto 0);
        GPIO_0   : inout std_logic_vector(23 downto 0);
        HEX0, HEX1, HEX2, HEX3 : out std_logic_vector(6 downto 0);
        LEDR     : out   std_logic_vector(9 downto 0)
    );
end entity lab2_top;

architecture rtl of lab2_top is
    signal rst        : std_logic;
    signal fsclk, latido, pert : std_logic;
    signal adc_clk, adc_start, adc_oe, adc_eoc : std_logic;
    signal adc_d      : std_logic_vector(7 downto 0);
    signal muestra    : unsigned(7 downto 0);
    signal m_valida   : std_logic;
    signal y_valid    : std_logic;
    signal y_out      : unsigned(7 downto 0);
    signal y_frac     : unsigned(11 downto 0);
    signal temp_dec   : unsigned(9 downto 0);
    signal dac_code   : unsigned(7 downto 0);
begin
    rst <= not KEY(0);                                   -- KEY activo en bajo

    u_gen : entity work.gen_muestreo generic map (DIV_FS => DIV_FS)
        port map (clk => CLOCK_50, rst => rst, sel => SW(1 downto 0),
                  fsclk => fsclk, latido => latido, pert => pert);

    u_adc : entity work.adc0808_ctrl
        port map (clk => CLOCK_50, rst => rst, fsclk => fsclk,
                  adc_clk => adc_clk, adc_start => adc_start, adc_oe => adc_oe,
                  adc_eoc => adc_eoc, adc_d => adc_d,
                  muestra => muestra, muestra_valida => m_valida);

    u_fir : entity work.fir_filter
        port map (clk => CLOCK_50, rst => rst, x_valid => m_valida, x_in => muestra,
                  y_valid => y_valid, y_out => y_out, y_frac => y_frac);

    u_esc : entity work.escala_temp
        port map (clk => CLOCK_50, rst => rst, y_valid => y_valid,
                  y_in => y_frac, temp_dec => temp_dec);

    u_vis : entity work.visualizacion
        port map (sw3 => SW(3), temp_dec => temp_dec, crudo => muestra,
                  hex0 => HEX0, hex1 => HEX1, hex2 => HEX2, hex3 => HEX3);

    u_ind : entity work.indicadores
        port map (clk => CLOCK_50, rst => rst, muestra_valida => m_valida,
                  muestra => muestra, led_muestreo => LEDR(0), led_satura => LEDR(9));

    -- derivacion del filtro: SW2 = 0 cruda, SW2 = 1 filtrada
    dac_code <= y_out when SW(2) = '1' else muestra;

    -- asignacion de pines GPIO_0 (coincide con el cableado del montaje)
    GPIO_0(0)            <= pert;
    GPIO_0(1)            <= latido;
    GPIO_0(2)            <= adc_clk;
    GPIO_0(3)            <= adc_start;        -- ALE
    GPIO_0(4)            <= adc_start;        -- START (misma senal que ALE)
    GPIO_0(5)            <= adc_oe;
    GPIO_0(6)            <= 'Z';              -- EOC (entrada)
    adc_eoc              <= GPIO_0(6);
    GPIO_0(14 downto 7)  <= (others => 'Z');  -- D0..D7 (entradas)
    adc_d                <= GPIO_0(14 downto 7);
    GPIO_0(15)           <= 'Z';              -- libre
    GPIO_0(23 downto 16) <= std_logic_vector(dac_code);

    LEDR(8 downto 1) <= (others => '0');
end architecture rtl;