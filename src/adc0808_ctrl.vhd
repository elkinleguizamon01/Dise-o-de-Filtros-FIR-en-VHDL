--------------------------------------------------------------------------------
-- adc0808_ctrl.vhd
-- Controlador del ADC0808 (8 bits, canal IN0: ADDR A,B,C a GND en el montaje).
--   * Genera el reloj del ADC (500 kHz) dividiendo CLOCK_50.
--   * La conversion la dispara SIEMPRE fsclk (START y ALE unidos).
--   * Secuencia: START -> espera EOC bajo -> espera EOC alto -> OE -> lectura.
--   * Entrega la muestra y un pulso de dato valido de un ciclo.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adc0808_ctrl is
    generic (
        ADC_CLK_DIV     : positive := 100;    -- 50 MHz / 100 = 500 kHz (debe ser par)
        START_CICLOS    : positive := 50;     -- ancho de START/ALE = 1 us
        ESPERA_EOC_BAJO : positive := 1250;   -- 25 us: EOC ya bajo (max ~ 2us + 8 clk ADC)
        ESPERA_OE       : positive := 25;     -- 500 ns: tiempo de acceso de salida (OE)
        TIMEOUT         : positive := 20000   -- 400 us: aborta si EOC nunca sube
    );
    port (
        clk            : in  std_logic;
        rst            : in  std_logic;
        fsclk          : in  std_logic;
        -- hacia el ADC0808
        adc_clk        : out std_logic;
        adc_start      : out std_logic;       -- START y ALE unidos
        adc_oe         : out std_logic;
        adc_eoc        : in  std_logic;
        adc_d          : in  std_logic_vector(7 downto 0);
        -- hacia el sistema
        muestra        : out unsigned(7 downto 0);
        muestra_valida : out std_logic
    );
end entity adc0808_ctrl;

architecture rtl of adc0808_ctrl is

    type estado_t is (REPOSO, PULSO_START, ESPERA_BAJO, ESPERA_ALTO, LEE_OE);
    signal estado : estado_t := REPOSO;

    signal clk_cnt   : integer range 0 to ADC_CLK_DIV/2 - 1 := 0;
    signal adc_clk_r : std_logic := '0';

    signal cnt       : integer range 0 to 131071 := 0;
    signal start_r   : std_logic := '0';
    signal oe_r      : std_logic := '0';
    signal valida_r  : std_logic := '0';
    signal muestra_r : unsigned(7 downto 0) := (others => '0');

    signal eoc_s1, eoc_s2 : std_logic := '0';   -- sincronizador de EOC
    signal d_q            : std_logic_vector(7 downto 0) := (others => '0');

begin

    -- Reloj del ADC: salida REGISTRADA (no se usa como reloj interno)
    process (clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                clk_cnt   <= 0;
                adc_clk_r <= '0';
            elsif clk_cnt = ADC_CLK_DIV/2 - 1 then
                clk_cnt   <= 0;
                adc_clk_r <= not adc_clk_r;
            else
                clk_cnt <= clk_cnt + 1;
            end if;
        end if;
    end process;

    -- Maquina de estados de la conversion
    process (clk)
    begin
        if rising_edge(clk) then
            eoc_s1   <= adc_eoc;
            eoc_s2   <= eoc_s1;
            d_q      <= adc_d;
            valida_r <= '0';                     -- por defecto

            if rst = '1' then
                estado  <= REPOSO;
                cnt     <= 0;
                start_r <= '0';
                oe_r    <= '0';
            else
                case estado is

                    when REPOSO =>
                        start_r <= '0';
                        oe_r    <= '0';
                        if fsclk = '1' then
                            start_r <= '1';
                            cnt     <= 0;
                            estado  <= PULSO_START;
                        end if;

                    when PULSO_START =>
                        if cnt = START_CICLOS - 1 then
                            start_r <= '0';      -- la conversion arranca al bajar START
                            cnt     <= 0;
                            estado  <= ESPERA_BAJO;
                        else
                            cnt <= cnt + 1;
                        end if;

                    when ESPERA_BAJO =>
                        if cnt = ESPERA_EOC_BAJO - 1 then
                            cnt    <= 0;
                            estado <= ESPERA_ALTO;
                        else
                            cnt <= cnt + 1;
                        end if;

                    when ESPERA_ALTO =>
                        if eoc_s2 = '1' then     -- conversion terminada
                            oe_r   <= '1';
                            cnt    <= 0;
                            estado <= LEE_OE;
                        elsif cnt = TIMEOUT - 1 then
                            estado <= REPOSO;    -- aborta: conserva la muestra anterior
                        else
                            cnt <= cnt + 1;
                        end if;

                    when LEE_OE =>
                        if cnt = ESPERA_OE - 1 then
                            muestra_r <= unsigned(d_q);
                            valida_r  <= '1';
                            oe_r      <= '0';
                            estado    <= REPOSO;
                        else
                            cnt <= cnt + 1;
                        end if;

                end case;
            end if;
        end if;
    end process;

    adc_clk        <= adc_clk_r;
    adc_start      <= start_r;
    adc_oe         <= oe_r;
    muestra        <= muestra_r;
    muestra_valida <= valida_r;

end architecture rtl;
