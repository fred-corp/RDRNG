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
    TransWidth_g              : positive             := 32;
    SpiCpol_g                 : natural range 0 to 1 := 0;
    SpiCpha_g                 : natural range 0 to 1 := 0;
    LsbFirst_g                : boolean              := false;
    ConsecutiveTransactions_g : boolean              := false;
    InternalTriState_g        : boolean              := true
  );
  port (
    clk   : in std_logic;
    reset : in std_logic;

    -- SPI interface
    -- RX Data
    Rx_Valid : in std_logic;
    Rx_Data  : in std_logic_vector(TransWidth_g - 1 downto 0);
    -- TX Data
    Tx_Valid : out std_logic := '1';
    Tx_Ready : in std_logic;
    Tx_Data  : out std_logic_vector(TransWidth_g - 1 downto 0) := (others => '0');
    -- Response Interface
    Resp_Valid    : in std_logic;
    Resp_Sent     : in std_logic;
    Resp_Aborted  : in std_logic;
    Resp_CleanEnd : in std_logic;

    -- APB interface
    m_paddr   : out std_logic_vector(7 downto 0);
    m_psel    : out std_logic;
    m_penable : out std_logic;
    m_pwrite  : out std_logic;
    m_pwdata  : out std_logic_vector(15 downto 0);
    m_prdata  : in std_logic_vector(15 downto 0)
  );
end entity spi_protocol;

architecture rtl of spi_protocol is
  type SPI_STATUS is
  (
  WRITE_ADDRESS, WRITE_DATA0, WRITE_DATA1, WRITE_ANSWER_HEADER, WRITE_ANSWER_OK,
  READ_ADDRESS, READ_ANSWER_HEADER, READ_ANSWER_DATA0, READ_ANSWER_DATA1,
  APB_SETUP, APB_EXECUTE, APB_DONE,
  IDLE
  );

  signal state      : SPI_STATUS                    := IDLE;
  signal write_flag : std_logic                     := '0';
  signal apb_data   : std_logic_vector(15 downto 0) := (others => '0');
  signal address    : std_logic_vector(7 downto 0)  := (others => '0');
  signal wr_data    : std_logic_vector(15 downto 0) := (others => '0');
begin

  process (clk)
  begin
    if rising_edge(clk) then
      case state is
        when IDLE =>
          if rx_valid = '1' then
            if rx_data = x"AA" then
              state      <= WRITE_ADDRESS;
              write_flag <= '1';
            elsif rx_data = x"55" then
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
        when WRITE_ANSWER_HEADER =>
          tx_data  <= x"AA";
          tx_valid <= '1';
          if tx_ready = '1' then
            tx_valid <= '0';
            state    <= WRITE_ANSWER_OK;
          end if;
        when WRITE_ANSWER_OK =>
          tx_data  <= x"00";
          tx_valid <= '1';
          if tx_ready = '1' then
            tx_valid <= '0';
            state    <= IDLE;
          end if;

        when READ_ADDRESS =>
          address <= rx_data;
          if rx_valid = '1' then
            state <= APB_SETUP;
          else
            state <= READ_ADDRESS;
          end if;
        when READ_ANSWER_HEADER =>
          tx_data  <= x"55";
          tx_valid <= '1';
          if tx_ready = '1' then
            tx_valid <= '0';
            state    <= READ_ANSWER_DATA0;
          else
            state <= READ_ANSWER_HEADER;
          end if;
        when READ_ANSWER_DATA0 =>
          tx_data  <= x"01";--apb_data(15 downto 8);
          tx_valid <= '1';
          if tx_ready = '1' then
            tx_valid <= '0';
            state    <= READ_ANSWER_DATA1;
          else
            state <= READ_ANSWER_DATA0;
          end if;
        when READ_ANSWER_DATA1 =>
          tx_data  <= x"23";--apb_data(7 downto 0);
          tx_valid <= '1';
          if tx_ready = '1' then
            tx_valid <= '0';
            state    <= IDLE;
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
          apb_data  <= m_prdata;
          state     <= APB_DONE;
        when APB_DONE =>
          m_psel <= '0';
          if write_flag = '1' then
            state <= WRITE_ANSWER_HEADER;
          elsif write_flag = '0' then
            state <= READ_ANSWER_HEADER;
          end if;
        when others =>
          null;
      end case;
      if reset = '1' then
        state <= IDLE;
        m_psel <= '0';
        m_penable <= '0';
        m_pwrite <= '0';
        m_pwdata <= (others => '0');
        m_paddr <= (others => '0');
        tx_valid <= '0';
        tx_data  <= (others => '0');
        apb_data <= (others => '0');
        address  <= (others => '0');
        write_flag <= '0';
        wr_data <= (others => '0');
      end if;
    end if;
  end process;

end rtl;