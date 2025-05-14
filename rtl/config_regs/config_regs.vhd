---------------------------------------------------------------------------------------------------
-- Microelectronics Project : Radioactive Decay Random Number Generator
-- Author : Frédéric Druppel
-- File content: Configuration registers
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity config_regs is
  port (
    clk   : in std_logic;
    reset : in std_logic;

    -- APB interface
    s_paddr   : in std_logic_vector(7 downto 0); --* APB address
    s_psel    : in std_logic; --* APB select
    s_penable : in std_logic; --* APB enable
    s_pwrite  : in std_logic; --* APB write
    s_pwdata  : in std_logic_vector(15 downto 0); --* APB write data
    s_prdata  : out std_logic_vector(15 downto 0); --* APB read data

    -- Inputs
    -- Random number generator
    generated_number : in std_logic_vector(15 downto 0); --* Generated random number
    generated_seed   : in std_logic_vector(15 downto 0); --* Generated seed from RNG

    -- Outputs
    -- General
    mode : out std_logic; --* Mode for RNG
    -- Random number generator
    custom_seed       : out std_logic_vector(15 downto 0); --* Custom seed for RNG
    generate_seed     : out std_logic; --* Generate new seed from radiactive decay signal
    is_custom_seed    : out std_logic; --* Custom seed flag
    choose_polynomial : out std_logic_vector(1 downto 0); --* Polynomial selection for LFSR
    generate_number   : out std_logic; --* Generate new random number

    -- LEDs
    led_r : out std_logic;
    led_g : out std_logic;
    led_b : out std_logic
  );
end entity config_regs;

architecture rtl of config_regs is
  signal s_mode              : std_logic                     := '0'; --* Mode for RNG
  signal s_custom_seed       : std_logic_vector(15 downto 0) := x"0000"; --* Custom seed for RNG
  signal s_generate_seed     : std_logic                     := '0'; --* Generate new seed from radioactive decay signal
  signal s_is_custom_seed    : std_logic                     := '0'; --* Custom seed flag
  signal s_generate_number   : std_logic                     := '0'; --* Generate new random number
  signal s_choose_polynomial : std_logic_vector(1 downto 0)  := (others => '0'); --* Polynomial selection for LFSR

  signal s_led_r : std_logic := '0';
  signal s_led_g : std_logic := '0';
  signal s_led_b : std_logic := '0';

begin
  main : process (clk)
  begin
    if rising_edge(clk) then

      if s_generate_seed = '1' then
        s_generate_seed <= '0';
      end if;

      if s_generate_number = '1' then
        s_generate_number <= '0';
      end if;

      if s_psel = '1' then
        if s_pwrite = '1' then
          if s_penable = '1' then
            -- Write registers
            -- Set mode for RNG
            if s_paddr = x"00" then
              s_mode <= s_pwdata(0);
              -- Set seed manually
            elsif s_paddr = x"01" then
              s_custom_seed <= s_pwdata;
              s_is_custom_seed <= '1';
              -- Set seed from Radioactive Decay Pulses
            elsif s_paddr = x"02" then
              s_generate_seed <= '1';
              s_is_custom_seed <= '0';
              -- Set polynomial for LFSR
            elsif s_paddr = x"03" then
              s_choose_polynomial <= s_pwdata(1 downto 0);
              -- LED registers
            elsif s_paddr = x"10" then
              s_led_r <= s_pwdata(0);
            elsif s_paddr = x"12" then
              s_led_g <= s_pwdata(0);
            elsif s_paddr = x"14" then
              s_led_b <= s_pwdata(0);
            end if;
          end if;
        else
          if s_penable = '0' then
            -- Read registers
            -- Read generated number
            if s_paddr = x"00" then
              s_generate_number <= '1';
              s_prdata          <= generated_number;
              -- Read custom seed
            elsif s_paddr = x"01" then
              s_prdata <= s_custom_seed;
              -- Read generated seed
            elsif s_paddr = x"02" then
              s_prdata <= generated_seed;
              -- Read polynomial
            elsif s_paddr = x"03" then
              s_prdata             <= (others => '0');
              s_prdata(1 downto 0) <= s_choose_polynomial;
              -- Read LED registers
            elsif s_paddr = x"10" then
              s_prdata    <= (others => '0');
              s_prdata(0) <= s_led_r;
            elsif s_paddr = x"12" then
              s_prdata    <= (others => '0');
              s_prdata(0) <= s_led_g;
            elsif s_paddr = x"14" then
              s_prdata    <= (others => '0');
              s_prdata(0) <= s_led_b;
              -- Read default value
            else
              s_prdata <= x"0123";
            end if;
          end if;
        end if;
      end if;
      if reset = '1' then
        s_mode              <= '0';
        s_custom_seed       <= x"0000";
        s_generate_seed     <= '0';
        s_generate_number   <= '0';
        s_choose_polynomial <= (others => '0');
        s_led_r            <= '0';
        s_led_g            <= '0';
        s_led_b            <= '0';
        s_prdata           <= (others => '0');
      end if;
    end if;
  end process main;

  -- Assign outputs
  mode              <= s_mode;
  custom_seed       <= s_custom_seed;
  is_custom_seed    <= s_is_custom_seed;
  generate_seed     <= s_generate_seed;
  generate_number   <= s_generate_number;
  choose_polynomial <= s_choose_polynomial;

  led_r <= s_led_r;
  led_g <= s_led_g;
  led_b <= s_led_b;

end architecture;