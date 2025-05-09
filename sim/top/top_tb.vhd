library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
context vunit_lib.vc_context;

entity top_tb is
  generic (runner_cfg : string);
end entity;

architecture tb of top_tb is
  signal clk : std_logic := '0';
  signal rstn : std_logic := '0';
  signal spi_sck : std_logic := '0';
  signal spi_mosi : std_logic := '0';
  signal spi_miso : std_logic := '0';
  signal spi_cs : std_logic := '1';  -- Idle high
  signal rng_bits_output : std_logic_vector(7 downto 0);
  signal led_r : std_logic;
  signal led_g : std_logic;
  signal led_b : std_logic;
  signal debug : std_logic;



  ------------------------------------------------------------------------
  -- SPI Master Procedure
  ------------------------------------------------------------------------
  procedure spi_write(
    signal sck     : out std_logic;
    signal mosi    : out std_logic;
    signal cs      : out std_logic;
    constant data  : std_logic_vector(7 downto 0);
    constant sck_period : time := 10 us
  ) is
  begin
    cs <= '0';
    wait for sck_period / 2;

    for i in 7 downto 0 loop
      mosi <= data(i);
      wait for sck_period / 2;
      sck <= '1';
      wait for sck_period / 2;
      sck <= '0';
    end loop;

    cs <= '1';
    wait for sck_period;
  end procedure;


begin

  ------------------------------------------------------------------------
  -- Device Under Test (DUT)
  ------------------------------------------------------------------------
  top_inst : entity work.top
    port map (
      clk           => clk,
      rstn          => rstn,
      spi_sck       => spi_sck,
      spi_mosi      => spi_mosi,
      spi_miso      => spi_miso,
      spi_cs        => spi_cs,
      rng_bits_output => rng_bits_output,
      led_r         => led_r,
      led_g         => led_g,
      led_b         => led_b
    );

  ------------------------------------------------------------------------
  -- Clock Generation
  ------------------------------------------------------------------------
  clk <= not clk after (83.333/2.0)* 1 ns;

  ------------------------------------------------------------------------
  -- Reset Process
  ------------------------------------------------------------------------
  rstn <= '0', '1' after 500 ns;

  ------------------------------------------------------------------------
  -- Main Test Process
  ------------------------------------------------------------------------
  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    wait until rstn = '1';
    wait for 50 us;

    spi_write(spi_sck, spi_mosi, spi_cs, x"AA");
    wait for 100 us;
    spi_write(spi_sck, spi_mosi, spi_cs, x"10");
    wait for 100 us;
    spi_write(spi_sck, spi_mosi, spi_cs, x"00");
    wait for 100 us;
    spi_write(spi_sck, spi_mosi, spi_cs, x"01");
    wait for 400 us;

    -- Example assertion (replace with meaningful test logic)
    check_equal(led_r, '0', "Expected LED R to be '0' after SPI command [xAA, x10, x00, X11]");

    test_runner_cleanup(runner);
    wait;
  end process;

end architecture;