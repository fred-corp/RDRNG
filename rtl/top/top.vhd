---------------------------------------------------------------------------------------------------
-- Microelectronics Project : Radioactive Decay Random Number Generator
-- Author : Frédéric Druppel
-- File content: Top level entity
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity top is
  port (
    clk  : in std_logic; --* Clock input
    rstn : in std_logic; --* Active low reset input

    rng_bits_output : out std_logic_vector(7 downto 0); --* Random number output bits 8 to 1
    -- SPI interface
    spi_sck  : in std_logic; --* SPI clock
    spi_mosi : in std_logic; --* SPI MOSI
    spi_miso : out std_logic; --* SPI MISO
    spi_cs   : in std_logic; --* SPI chip select

    -- Inputs
    pulse_input : in std_logic; --* Pulse input

    -- Outputs
    led_r : out std_logic; --* Red LED
    led_g : out std_logic; --* Green LED
    led_b : out std_logic --* Blue LED
  );
end entity top;

architecture rtl of top is
  -- Reset
  signal reset : std_logic; --* Reset signal

  -- SPI
  signal spi_tx_valid      : std_logic := '0'; --* SPI transmitter valid
  signal spi_tx_ready      : std_logic; --* SPI transmitter ready
  signal spi_tx_data       : std_logic_vector(7 downto 0); --* SPI transmitter data
  signal spi_rx_valid      : std_logic := '0'; --* SPI receiver valid
  signal spi_rx_data       : std_logic_vector(7 downto 0); --* SPI receiver data
  signal spi_resp_valid    : std_logic; --* SPI response valid
  signal spi_resp_sent     : std_logic; --* SPI data sent flag
  signal spi_resp_aborted  : std_logic; --* SPI data aborted flag
  signal spi_resp_cleanend : std_logic; --* SPI response clean end flag

  -- APB
  signal apb_paddr   : std_logic_vector(7 downto 0); --* APB address
  signal apb_psel    : std_logic; --* APB select
  signal apb_penable : std_logic; --* APB enable
  signal apb_pwrite  : std_logic; --* APB write
  signal apb_pwdata  : std_logic_vector(15 downto 0); --* APB write data
  signal apb_prdata  : std_logic_vector(15 downto 0); --* APB read data

  -- LEDs
  signal led_out_r : std_logic := '0'; --* Red LED signal
  signal led_out_g : std_logic := '0'; --* Green LED signal
  signal led_out_b : std_logic := '0'; --* Blue LED signal

  -- config regs signals
  signal cr_mode            : std_logic                     := '0'; --* Mode select (0: decay sampling, 1: LFSR)
  signal cr_seed            : std_logic_vector(15 downto 0) := x"0000"; --* Seed value
  signal cr_custom_seed     : std_logic_vector(15 downto 0) := x"0000"; --* Custom seed value
  signal cr_is_custom_seed  : std_logic                     := '0'; --* Custom seed flag
  signal cr_generate_seed   : std_logic                     := '0'; --* Generate seed flag
  signal cr_generate_number : std_logic                     := '0'; --* Generate number flag

  -- RNG
  constant rng_output_len  : integer                                       := 16; --* Output length in bits
  signal rng_seed          : std_logic_vector(rng_output_len - 1 downto 0) := x"1234"; --* Seed value
  signal rng_output        : std_logic_vector(rng_output_len - 1 downto 0); --* Random number output
  signal rng_gen_new_num   : std_logic                    := '0'; --* Generate new number flag
  signal rng_load_new_seed : std_logic                    := '0'; --* Load new seed flag
  signal rng_polynomial    : std_logic_vector(1 downto 0) := (others => '0'); --* Polynomial selection

  -- Decay sampling
  signal ds_output_valid : std_logic                                     := '0'; --* Output valid signal
  signal ds_output       : std_logic_vector(rng_output_len - 1 downto 0) := (others => '0'); --* Output random number signal
  signal s_ds_output     : std_logic_vector(rng_output_len - 1 downto 0) := (others => '0'); --* Buffered output random number signal

  -- Mapped outputs
  signal random_number : std_logic_vector(rng_output_len - 1 downto 0); --* Random number signal

begin
  -- *** Reset resynchronization ***
  reset_gen_inst : entity work.olo_base_reset_gen
    generic map(
      RstInPolarity_g => '0'
    )
    port map
    (
      Clk    => Clk,
      RstOut => reset,
      RstIn  => rstn
    );

  -- *** SPI slave interface ***
  spi_slave_inst : entity work.olo_intf_spi_slave
    generic map(
      TransWidth_g              => positive(8),
      ConsecutiveTransactions_g => true --* Consecutive transactions
    )
    port map
    (
      Clk      => clk,
      Rst      => reset,
      Spi_Sclk => spi_sck,
      Spi_Mosi => spi_mosi,
      Spi_Miso => spi_miso,
      Spi_Cs_N => spi_cs,

      Rx_Valid      => spi_rx_valid,
      Rx_Data       => spi_rx_data,
      Tx_Valid      => spi_tx_valid,
      Tx_Ready      => spi_tx_ready,
      Tx_Data       => spi_tx_data,
      Resp_Valid    => spi_resp_valid,
      Resp_Sent     => spi_resp_sent,
      Resp_Aborted  => spi_resp_aborted,
      Resp_CleanEnd => spi_resp_cleanend
    );

  -- *** SPI protocol ***
  spi_inst : entity work.spi_protocol
    generic map(
      TransWidth_g => positive(8)
    )
    port map
    (
      clk   => clk,
      reset => reset,
      -- SPI interface
      Rx_Valid => spi_rx_valid,
      Rx_Data  => spi_rx_data,
      Tx_Valid => spi_tx_valid,
      Tx_Ready => spi_tx_ready,
      Tx_Data  => spi_tx_data,
      -- Response Interface
      Resp_Valid    => spi_resp_valid,
      Resp_Sent     => spi_resp_sent,
      Resp_Aborted  => spi_resp_aborted,
      Resp_CleanEnd => spi_resp_cleanend,
      -- APB interface
      m_paddr   => apb_paddr,
      m_psel    => apb_psel,
      m_penable => apb_penable,
      m_pwrite  => apb_pwrite,
      m_pwdata  => apb_pwdata,
      m_prdata  => apb_prdata
    );

  -- *** Config registers ***
  config_regs_inst : entity work.config_regs
    port map
    (
      clk   => clk,
      reset => reset,
      -- APB interface
      s_paddr   => apb_paddr,
      s_psel    => apb_psel,
      s_penable => apb_penable,
      s_pwrite  => apb_pwrite,
      s_pwdata  => apb_pwdata,
      s_prdata  => apb_prdata,
      -- Inputs
      generated_number => random_number,
      generated_seed   => cr_seed,
      -- Outputs
      mode              => cr_mode,
      custom_seed       => cr_custom_seed,
      is_custom_seed    => cr_is_custom_seed,
      generate_seed     => cr_generate_seed,
      choose_polynomial => rng_polynomial,
      generate_number   => rng_gen_new_num,
      -- LEDs
      led_r => led_out_r,
      led_g => led_out_g,
      led_b => led_out_b
    );

  --- *** RNG instance ***
  rng_inst : entity work.rand_gen
    generic map(
      LEN => rng_output_len
    )
    port map
    (
      clk        => clk,
      rst        => reset,
      enable     => rng_gen_new_num,
      load_seed  => rng_load_new_seed,
      seed_in    => rng_seed,
      polynomial => rng_polynomial,
      rand_slv   => rng_output
    );

  -- *** Decay sampling instance ***
  decay_sampler_inst : entity work.decay_sampler
    generic map(
      clk_freq      => 12000000, --* Clock frequency in Hz
      counter_slice => 2, --* Clock scaler for the decay signal
      output_width  => rng_output_len --* Output width in bits
    )
    port map
    (
      clk          => clk,
      reset        => reset,
      pulse        => pulse_input, --* Pulses from the radioactive decay sensor
      output_valid => ds_output_valid, --* Output valid signal
      output       => ds_output --* Output random number
    );

  main : process (clk)
  begin
    if rising_edge(clk) then
      -- check mode
      if cr_mode = '1' then
        -- LFSR
        if cr_generate_seed = '1' then
          if cr_is_custom_seed = '1' then
            rng_load_new_seed <= '1';
            rng_seed          <= cr_custom_seed;
          else
            rng_load_new_seed <= '1';
            rng_seed          <= s_ds_output;
          end if;
        else
          rng_load_new_seed <= '0';
        end if;

        random_number <= rng_output;
        cr_seed       <= rng_seed;
      else
        -- Decay sampling
        random_number <= s_ds_output;
        cr_seed       <= s_ds_output;
      end if;

      if ds_output_valid = '1' then
        s_ds_output <= ds_output;
      end if;

      -- Reset handling
      if reset = '1' then
        -- Mapped outputs
        random_number <= (others => '0');
      end if;
    end if;
  end process main;
  ----------------------------------------

  -- *** Mapped outputs ***
  rng_bits_output <= random_number(7 downto 0); -- Random number output bits 8 to 1

  -- *** LED drivers ***
  led_r <= '0' when led_out_r = '1' else
    '1';
  led_g <= '0' when led_out_g = '1' else
    '1';
  led_b <= '0' when led_out_b = '1' else
    '1';

end architecture rtl;
