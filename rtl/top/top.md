
# Entity: top

- **File**: top.vhd

## Diagram

![Diagram](top.svg "Diagram")

## Ports

| Port name       | Direction | Type                         | Description                      |
| --------------- | --------- | ---------------------------- | -------------------------------- |
| clk             | in        | std_logic                    | Clock input                      |
| rstn            | in        | std_logic                    | Active low reset input           |
| rng_bits_output | out       | std_logic_vector(7 downto 0) | Random number output bits 8 to 1 |
| spi_sck         | in        | std_logic                    | SPI clock                        |
| spi_mosi        | in        | std_logic                    | SPI MOSI                         |
| spi_miso        | out       | std_logic                    | SPI MISO                         |
| spi_cs          | in        | std_logic                    | SPI chip select                  |
| pulse_input     | in        | std_logic                    | Pulse input                      |
| led_r           | out       | std_logic                    | Red LED                          |
| led_g           | out       | std_logic                    | Green LED                        |
| led_b           | out       | std_logic                    | Blue LED                         |

## Signals

| Name               | Type                                          | Description                              |
| ------------------ | --------------------------------------------- | ---------------------------------------- |
| reset              | std_logic                                     | Reset signal                             |
| spi_tx_valid       | std_logic                                     | SPI transmitter valid                    |
| spi_tx_ready       | std_logic                                     | SPI transmitter ready                    |
| spi_tx_data        | std_logic_vector(7 downto 0)                  | SPI transmitter data                     |
| spi_rx_valid       | std_logic                                     | SPI receiver valid                       |
| spi_rx_data        | std_logic_vector(7 downto 0)                  | SPI receiver data                        |
| spi_resp_valid     | std_logic                                     | SPI response valid                       |
| spi_resp_sent      | std_logic                                     | SPI data sent flag                       |
| spi_resp_aborted   | std_logic                                     | SPI data aborted flag                    |
| spi_resp_cleanend  | std_logic                                     | SPI response clean end flag              |
| apb_paddr          | std_logic_vector(7 downto 0)                  | APB address                              |
| apb_psel           | std_logic                                     | APB select                               |
| apb_penable        | std_logic                                     | APB enable                               |
| apb_pwrite         | std_logic                                     | APB write                                |
| apb_pwdata         | std_logic_vector(15 downto 0)                 | APB write data                           |
| apb_prdata         | std_logic_vector(15 downto 0)                 | APB read data                            |
| led_out_r          | std_logic                                     | Red LED signal                           |
| led_out_g          | std_logic                                     | Green LED signal                         |
| led_out_b          | std_logic                                     | Blue LED signal                          |
| cr_mode            | std_logic                                     | Mode select (0: decay sampling, 1: LFSR) |
| cr_seed            | std_logic_vector(15 downto 0)                 | Seed value                               |
| cr_custom_seed     | std_logic_vector(15 downto 0)                 | Custom seed value                        |
| cr_is_custom_seed  | std_logic                                     | Custom seed flag                         |
| cr_generate_seed   | std_logic                                     | Generate seed flag                       |
| cr_generate_number | std_logic                                     | Generate number flag                     |
| rng_seed           | std_logic_vector(rng_output_len - 1 downto 0) | Seed value                               |
| rng_output         | std_logic_vector(rng_output_len - 1 downto 0) | Random number output                     |
| rng_gen_new_num    | std_logic                                     | Generate new number flag                 |
| rng_load_new_seed  | std_logic                                     | Load new seed flag                       |
| rng_polynomial     | std_logic_vector(1 downto 0)                  | Polynomial selection                     |
| ds_output_valid    | std_logic                                     | Output valid signal                      |
| ds_output          | std_logic_vector(rng_output_len - 1 downto 0) | Output random number signal              |
| s_ds_output        | std_logic_vector(rng_output_len - 1 downto 0) | Buffered output random number signal     |
| random_number      | std_logic_vector(rng_output_len - 1 downto 0) |                                          |

## Constants

| Name           | Type    | Value | Description           |
| -------------- | ------- | ----- | --------------------- |
| rng_output_len | integer | 16    | Output length in bits |

## Processes

- main: ( clk )

## Instantiations

- reset_gen_inst: work.olo_base_reset_gen
- spi_slave_inst: work.olo_intf_spi_slave
- spi_inst: work.spi_protocol
- config_regs_inst: work.config_regs
- rng_inst: work.rand_gen
- decay_sampler_inst: work.decay_sampler
