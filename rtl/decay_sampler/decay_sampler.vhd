---------------------------------------------------------------------------------------------------
-- Microelectronics Project : Radioactive Decay Random Number Generator
-- Author : Frédéric Druppel
-- File content: Decay Sampler
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity decay_sampler is
  generic (
    clk_freq      : integer := 12000000; --* Clock frequency in Hz
    counter_slice : integer := 2; --* Clock scaler for the decay signal
    output_width  : integer := 16 --* Output width in bits
  );
  port (
    clk   : in std_logic; --* Clock signal
    reset : in std_logic; --* Reset signal

    -- Inputs
    pulse : in std_logic; --* Pulses from the radioactive decay sensor
    -- Outputs
    output_valid : out std_logic; --* Output valid signal
    output       : out std_logic_vector(output_width - 1 downto 0) --* Output random number
  );
end entity;

architecture rtl of decay_sampler is
  constant counter_width : integer                                     := integer(ceil(log2(real(clk_freq)))); --* Counter width in bits
  signal counter         : unsigned(counter_width downto 0)            := (others => '0'); --* Counter for clock cycles
  signal s_output        : std_logic_vector(output_width - 1 downto 0) := (others => '0'); --* Output random number signal
  signal s_pulse         : std_logic                                   := '0'; --* Pulse signal
  signal s_pulse_prev    : std_logic                                   := '0'; --* Previous pulse signal

begin

  -- Clock and reset
  process (clk)
  begin
    if rising_edge(clk) then
      s_pulse_prev <= s_pulse;
      s_pulse      <= pulse;

      counter <= counter + 1;

      -- Check for rising edge of the pulse
      if (s_pulse = '1' and s_pulse_prev = '0') then
        -- Generate random number
        s_output     <= std_logic_vector(counter(output_width + counter_slice - 2 downto counter_slice - 1));
        output_valid <= '1';
        counter      <= (others => '0'); -- Reset counter after pulse
      else
        output_valid <= '0';
      end if;

      if reset = '1' then
        counter      <= (others => '0');
        s_output     <= (others => '0');
        s_pulse      <= '0';
        s_pulse_prev <= '0';
      end if;
    end if;
  end process;

  -- assign output
  output <= s_output;

end architecture;