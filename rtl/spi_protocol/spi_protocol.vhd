---------------------------------------------------------------------------------------------------
-- Microelectronics Project : Radioactive Decay Random Number Generator
-- Author : Frédéric Druppel
-- File content: SPI protocol
---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity spi_protocol is
  generic (
    TransWidth_g              : positive             := 8; --* SPI transaction width
    SpiCpol_g                 : natural range 0 to 1 := 0; --* SPI clock polarity
    SpiCpha_g                 : natural range 0 to 1 := 0; --* SPI clock phase
    LsbFirst_g                : boolean              := false; --* LSB first
    ConsecutiveTransactions_g : boolean              := false; --* Consecutive transactions
    InternalTriState_g        : boolean              := true --* Internal tri-state
  );
  port (
    clk   : in std_logic; --* Clock input
    reset : in std_logic; --* Reset input

    -- SPI interface
    -- RX Data
    Rx_Valid : in std_logic; --* RX data valid
    Rx_Data  : in std_logic_vector(TransWidth_g - 1 downto 0); --* RX data
    -- TX Data
    Tx_Valid : out std_logic := '1'; --* TX data valid
    Tx_Ready : in std_logic; --* TX data ready
    Tx_Data  : out std_logic_vector(TransWidth_g - 1 downto 0) := (others => '0'); --* TX data
    -- Response Interface
    Resp_Valid    : in std_logic; --* Response valid
    Resp_Sent     : in std_logic; --* Response sent
    Resp_Aborted  : in std_logic; --* Response aborted
    Resp_CleanEnd : in std_logic; --* Response clean end

    -- APB interface
    m_paddr   : out std_logic_vector(7 downto 0); --* APB address
    m_psel    : out std_logic; --* APB select
    m_penable : out std_logic; --* APB enable
    m_pwrite  : out std_logic; --* APB write
    m_pwdata  : out std_logic_vector(15 downto 0); --* APB write data
    m_prdata  : in std_logic_vector(15 downto 0)--* APB read data
  );
end entity spi_protocol;

architecture rtl of spi_protocol is
  type SPI_STATUS is
  (
  WRITE_ADDRESS, -- Write address select
  WRITE_DATA0, -- Write data, bit 16 to 9
  WRITE_DATA1, -- Write data, bit 8 to 1
  READ_ADDRESS, -- Read address select
  READ_ANSWER_DATA0, -- Read answer data, bit 16 to 9
  READ_WAIT, -- Wait for SPI module to send first byte
  READ_ANSWER_DATA1, -- Read answer data, bit 8 to 1
  APB_SETUP, -- APB setup
  APB_EXECUTE, -- APB execute
  APB_DONE, -- APB done
  IDLE -- Idle state
  );

  signal state      : SPI_STATUS                    := IDLE; --* State machine state
  signal write_flag : std_logic                     := '0'; --* Write flag
  signal apb_data   : std_logic_vector(15 downto 0) := (others => '0'); --* APB data
  signal address    : std_logic_vector(7 downto 0)  := (others => '0'); --* Address
  signal wr_data    : std_logic_vector(15 downto 0) := (others => '0'); --* Write data
  signal tx_valid_i : std_logic                     := '0'; --* Transmitter valid signal

begin

  main : process (clk)
  begin
    if rising_edge(clk) then
      if Resp_CleanEnd = '1' then
        state <= IDLE;
        -- m_psel     <= '0';
        -- m_penable  <= '0';
        -- m_pwrite   <= '0';
        -- m_pwdata   <= (others => '0');
        -- m_paddr    <= (others => '0');
        -- tx_valid_i <= '0';
        -- tx_data    <= (others => '0');
        -- apb_data   <= (others => '0');
        -- address    <= (others => '0');
        -- write_flag <= '0';
        -- wr_data    <= (others => '0');
      end if;
      case state is
        when IDLE =>
          tx_valid_i <= '0';
          if rx_valid = '1' then
            if (rx_data or "01111111") = "01111111" then
              state      <= WRITE_ADDRESS;
              write_flag <= '1';
            elsif (rx_data and "10000000") = "10000000" then
              state      <= READ_ADDRESS;
              write_flag <= '0';
            else
              state <= IDLE;
            end if;
          end if;

        when WRITE_ADDRESS =>
          address <= rx_data;
          if rx_valid = '1' then
            state <= WRITE_DATA0;
          end if;
        when WRITE_DATA0 =>
          wr_data(15 downto 8) <= rx_data;
          if rx_valid = '1' then
            state <= WRITE_DATA1;
          end if;
        when WRITE_DATA1 =>
          wr_data(7 downto 0) <= rx_data;
          if rx_valid = '1' then
            state <= APB_SETUP;
          end if;

        when READ_ADDRESS =>
          address <= rx_data;
          if rx_valid = '1' then
            state <= APB_SETUP;
          else
            state <= READ_ADDRESS;
          end if;
        when READ_ANSWER_DATA0 =>
          tx_data <= apb_data(15 downto 8);
          if rx_valid = '0' and tx_ready = '1' then
            tx_valid_i <= '1';
            state      <= READ_WAIT;
          else
            state <= READ_ANSWER_DATA0;
          end if;
        when READ_WAIT =>
          tx_valid_i <= '0';
          if Resp_Sent = '1' then
            state <= READ_ANSWER_DATA1;
          else
            state <= READ_WAIT;
          end if;
        when READ_ANSWER_DATA1 =>
          tx_data    <= apb_data(7 downto 0);
          tx_valid_i <= '0';
          if rx_valid = '0' and tx_ready = '1' then
            tx_valid_i <= '1';
            state      <= IDLE;
          else
            state <= READ_ANSWER_DATA1;
          end if;

        when APB_SETUP =>
          m_psel    <= '1';
          m_paddr   <= address;
          m_pwrite  <= write_flag;
          m_pwdata  <= wr_data;
          m_penable <= '0';
          state     <= APB_EXECUTE;
        when APB_EXECUTE =>
          m_penable <= '1';
          state     <= APB_DONE;
        when APB_DONE =>
          m_psel   <= '0';
          apb_data <= m_prdata;
          if write_flag = '1' then
            state <= IDLE;
            -- state <= WRITE_ANSWER_HEADER;
          elsif write_flag = '0' then
            state <= READ_ANSWER_DATA0;
          end if;
        when others =>
          null;
      end case;
      if reset = '1' then
        state      <= IDLE;
        m_psel     <= '0';
        m_penable  <= '0';
        m_pwrite   <= '0';
        m_pwdata   <= (others => '0');
        m_paddr    <= (others => '0');
        tx_valid_i <= '0';
        tx_data    <= (others => '0');
        apb_data   <= (others => '0');
        address    <= (others => '0');
        write_flag <= '0';
        wr_data    <= (others => '0');
      end if;
    end if;
  end process main;

  -- Assign outputs
  tx_valid <= tx_valid_i;

end rtl;