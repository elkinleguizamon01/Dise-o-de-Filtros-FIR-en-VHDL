--------------------------------------------------------------------------------
-- fir_filter.vhd   FIR serie (un multiplicador), S = 64
--   Blackman, Fs = 320 Hz, Fc = 55 Hz, N = 33 coeficientes, suma = 32768
--   Ciclos por muestra: N + 2 = 35
--   y_frac : salida con FRAC_BITS bits fraccionarios (12 bits = 8 + 4)
--   y_out  : salida entera de 8 bits (para el DAC R-2R)
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fir_filter is
    generic (
        FILTER_TAPS : positive := 33;
        COEFF_WIDTH : positive := 16;
        DATA_WIDTH  : positive := 8;
        FRAC_BITS   : natural  := 4;
        COEFF_SHIFT : natural  := 15          -- suma de coeficientes = 2^15
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        x_valid : in  std_logic;
        x_in    : in  unsigned(DATA_WIDTH-1 downto 0);
        y_valid : out std_logic;
        y_out   : out unsigned(DATA_WIDTH-1 downto 0);
        y_frac  : out unsigned(DATA_WIDTH+FRAC_BITS-1 downto 0)
    );
end entity fir_filter;

architecture rtl of fir_filter is

    constant ACC_W : positive := 32;
    constant OUT_W : positive := DATA_WIDTH + FRAC_BITS;

    type coefficients is array (0 to FILTER_TAPS-1) of signed(COEFF_WIDTH-1 downto 0);
    constant COEFF : coefficients := (
        x"0000", x"FFFF", x"0006", x"001C", x"0016", x"FFBD", x"FF50",
        x"FFAC", x"0139", x"0279", x"00BC", x"FBCC", x"F8B8", x"FED9",
        x"0FE6", x"235F", x"2C00", x"235F", x"0FE6", x"FED9", x"F8B8",
        x"FBCC", x"00BC", x"0279", x"0139", x"FFAC", x"FF50", x"FFBD",
        x"0016", x"001C", x"0006", x"FFFF", x"0000");

    type buffer_t is array (0 to FILTER_TAPS-1) of signed(DATA_WIDTH downto 0);
    signal buf : buffer_t := (others => (others => '0'));

    type estado_t is (REPOSO, MAC, FIN);
    signal estado : estado_t := REPOSO;

    signal idx      : integer range 0 to FILTER_TAPS-1 := 0;
    signal acc      : signed(ACC_W-1 downto 0) := (others => '0');
    signal yf_r     : unsigned(OUT_W-1 downto 0) := (others => '0');
    signal valid_r  : std_logic := '0';

begin

    process (clk)
        variable desplazado : signed(ACC_W-1 downto 0);
    begin
        if rising_edge(clk) then
            valid_r <= '0';

            if rst = '1' then
                estado <= REPOSO;
                idx    <= 0;
                acc    <= (others => '0');
                yf_r   <= (others => '0');
                buf    <= (others => (others => '0'));
            else
                case estado is

                    when REPOSO =>
                        if x_valid = '1' then
                            buf(0) <= signed('0' & x_in);        -- entrada sin signo
                            for i in 1 to FILTER_TAPS-1 loop
                                buf(i) <= buf(i-1);
                            end loop;
                            idx    <= 0;
                            acc    <= (others => '0');
                            estado <= MAC;
                        end if;

                    when MAC =>
                        acc <= acc + resize(COEFF(idx) * buf(idx), ACC_W);
                        if idx = FILTER_TAPS-1 then
                            estado <= FIN;
                        else
                            idx <= idx + 1;
                        end if;

                    when FIN =>
                        desplazado := shift_right(acc, COEFF_SHIFT - FRAC_BITS);
                        if desplazado < 0 then
                            yf_r <= (others => '0');
                        elsif desplazado > to_signed(2**OUT_W - 1, ACC_W) then
                            yf_r <= (others => '1');
                        else
                            yf_r <= unsigned(desplazado(OUT_W-1 downto 0));
                        end if;
                        valid_r <= '1';
                        estado  <= REPOSO;

                end case;
            end if;
        end if;
    end process;

    y_frac  <= yf_r;
    y_out   <= yf_r(OUT_W-1 downto FRAC_BITS);
    y_valid <= valid_r;

end architecture rtl;
