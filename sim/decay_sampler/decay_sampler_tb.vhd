library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;
context vunit_lib.com_context;
context vunit_lib.vc_context;

entity decay_sampler_tb is
  generic (runner_cfg : string);
end entity;

architecture rtl of decay_sampler_tb is
  signal clk          : std_logic := '0';
  signal rstn        : std_logic := '1';
  signal pulse        : std_logic := '0';
  signal output_valid : std_logic;
  signal output       : std_logic_vector(15 downto 0) := (others => '0');

begin

  decay_sampler_inst : entity work.decay_sampler
    generic map(
      clk_freq      => 12000000,
      counter_slice => 1,
      output_width  => 16
    )
    port map
    (
      clk          => clk,
      reset        => rstn,
      pulse        => pulse,
      output_valid => output_valid,
      output       => output
    );

  ------------------------------------------------------------------------
  -- Clock Generation
  ------------------------------------------------------------------------
  clk <= not clk after (83.333/2.0) * 1 ns;

  ------------------------------------------------------------------------
  -- Reset Process
  ------------------------------------------------------------------------
  rstn <= '1', '0' after 500 ns;

  ------------------------------------------------------------------------
  -- Main Test Process
  ------------------------------------------------------------------------
  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    wait until rstn = '0';
    wait for 50 us;

    pulse <= '1';
    wait for 100 us;
    pulse <= '0';
    wait for 1047 us;
    pulse <= '1';
    wait for 100 us;
    pulse <= '0';
    wait for 12 ms;
    pulse <= '1';
    wait for 100 us;
    pulse <= '0';
    wait for 5762 us;
    pulse <= '1';
    wait for 100 us;
    pulse <= '0';

    test_runner_cleanup(runner);
    wait;
  end process;
end architecture;