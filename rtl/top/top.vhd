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
    clk  : in std_logic;
    rstn : in std_logic;

    rng_bits_output : out std_logic_vector(7 downto 0);
    -- SPI interface
    spi_sck  : in std_logic;
    spi_mosi : in std_logic;
    spi_miso : out std_logic;
    spi_cs   : in std_logic;

    led_r : out std_logic;
    led_g : out std_logic;
    led_b : out std_logic
  );
end entity top;

architecture rtl of top is
  -- Reset
  signal reset : std_logic;

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
  signal apb_paddr   : std_logic_vector(7 downto 0);
  signal apb_psel    : std_logic;
  signal apb_penable : std_logic;
  signal apb_pwrite  : std_logic;
  signal apb_pwdata  : std_logic_vector(15 downto 0);
  signal apb_prdata  : std_logic_vector(15 downto 0);

  -- LEDs
  signal led_out_r : std_logic := '0';
  signal led_out_g : std_logic := '0';
  signal led_out_b : std_logic := '0';

  signal counter : unsigned(23 downto 0) := (others => '0');

  -- config regs signals
  signal cr_seed            : std_logic_vector(15 downto 0) := x"0000";
  signal cr_generate_seed   : std_logic                     := '0';
  signal cr_generate_number : std_logic                     := '0';

  -- RNG
  signal rng_output_len    : integer                                       := 16;
  signal rng_seed          : std_logic_vector(rng_output_len - 1 downto 0) := x"1234";
  signal rng_output        : std_logic_vector(rng_output_len - 1 downto 0);
  signal rng_gen_new_num   : std_logic                    := '0';
  signal rng_load_new_seed : std_logic                    := '0';
  signal rng_polynomial    : std_logic_vector(1 downto 0) := (others => '0');

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
      TransWidth_g => positive(8)
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
      generated_number => rng_output,
      generated_seed   => rng_seed,
      -- Outputs
      custom_seed       => cr_seed,
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

  process (clk)
  begin
    if rising_edge(clk) then
      counter <= counter + 1;
      if reset = '1' then
        counter   <= (others => '0');
      else
        -- Execute architecture
      end if;
    end if;
  end process;
  ----------------------------------------

  -- *** LED drivers ***
  led_r <= '0' when led_out_r = '1' else
    'Z';
  led_g <= '0' when led_out_g = '1' else
    'Z';
  led_b <= '0' when led_out_b = '1' else
    'Z';

end architecture rtl;
