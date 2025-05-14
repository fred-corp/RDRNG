---------------------------------------------------------------------------------------------------
-- Microelectronics Project : Radioactive Decay Random Number Generator
-- Author : Frédéric Druppel
-- File content: LFSR Random Number Generator
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rand_gen is
  generic (
    LEN : integer := 16 --* Length of the output vector
  );
  port (
    clk : in std_logic; --* Clock signal
    rst : in std_logic; --* Reset signal

    enable     : in std_logic; --* Enable signal
    load_seed  : in std_logic; --* Load seed signal
    seed_in    : in std_logic_vector(15 downto 0);
    polynomial : in std_logic_vector(1 downto 0); --* Polynomial selection for LFSR
    rand_slv   : out std_logic_vector(LEN - 1 downto 0) --* Random number output vector
  );
end entity;

architecture rtl of rand_gen is
  signal lfsr      : std_logic_vector(15 downto 0);
  signal prng_bits : std_logic_vector(LEN - 1 downto 0);

begin

  main : process (clk)
  begin
    if rising_edge(clk) then

      if load_seed = '1' then
        lfsr <= seed_in;
      elsif enable = '1' then
        -- lfsr <= lfsr(14 downto 0) &
        --   (lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10));
        if polynomial = "00" then
          -- Update LFSR with taps: x^16 + x^14 + x^13 + x^11 + 1
          lfsr <= lfsr(14 downto 0) &
            (lfsr(15) xor lfsr(13) xor lfsr(12) xor lfsr(10));
        elsif polynomial = "01" then
          -- Update LFSR with taps: x^16 + x^15 + x^13 + x^4 + 1
          lfsr <= lfsr(14 downto 0) &
            (lfsr(15) xor lfsr(14) xor lfsr(12) xor lfsr(3));
        elsif polynomial = "10" then
          -- Update LFSR with taps: x^16 + x^4 + x^3 + x^2 + 1
          lfsr <= lfsr(14 downto 0) &
            (lfsr(15) xor lfsr(4) xor lfsr(2) xor lfsr(1));
        elsif polynomial = "11" then
          -- Update LFSR with taps: x^16 + x^12 + x^3 + x^1 + 1
          lfsr <= lfsr(14 downto 0) &
            (lfsr(15) xor lfsr(11) xor lfsr(2) xor lfsr(0));
        end if;
      end if;
      if rst = '1' then
        lfsr <= (others => '0'); -- Reset to all 0s (or you can choose a default)
      end if;
    end if;
  end process main;

  -- Generate output from current LFSR state
  update_output : process (lfsr)
  begin
    -- for i in 0 to LEN - 1 loop
    --   prng_bits(i) <= lfsr(i mod 16);
    -- end loop;
    prng_bits <= lfsr(LEN - 1 downto 0);
  end process update_output;

  rand_slv <= prng_bits;

end architecture;