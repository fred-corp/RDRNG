# Radioactive Decay Random number generator

[![OpenLane Workflow](https://github.com/fred-corp/RDRNG/actions/workflows/gds.yaml/badge.svg)](https://github.com/fred-corp/RDRNG/actions/workflows/gds.yaml) [![GitHub Release](https://img.shields.io/github/v/release/fred-corp/RDRNG?display_name=release)](https://github.com/fred-corp/RDRNG/releases/latest)

## Summary

## Description

## Modes

### Decay sampling

In this mode, randomness is derived directly from the stochastic nature of radioactive decay events. The system samples the timestamps of two successive decay pulses and computes the time interval between them. This interval is then converted to a 16-bit value, providing a true random number based on quantum processes.
This method yields lower throughput compared to the LFSR mode but provides high-entropy outputs, making it suitable for cryptographic seeding or applications where unpredictability is paramount.

### LFSR

LFSR-Based Generation
A 16-bit Linear Feedback Shift Register (LFSR) is implemented to generate pseudo-random numbers. The design supports four selectable LFSR feedback polynomials, allowing for flexibility in sequence characteristics and period length. The user can manually select the desired polynomial through configuration inputs.

![LFSR](/rtl/rand_gen/rand_gen_schematic.svg)

*LFSR with taps on bit 10, 12, 13 and 15.*

The seed value for the LFSR can be:

* Manually configured, providing repeatable sequences for testing purposes.
* Automatically sampled from radioactive decay pulses (see Seed Generation section), introducing true entropy into the pseudo-random sequence and enabling initialization with unpredictable values.

This mode allows high-speed random number generation suitable for scenarios where throughput is critical and statistical randomness is sufficient.

## SPI Command Set

### Write to register

![Write sequence](https://svg.wavedrom.com/github/fred-corp/RDRNG/main/docs/spi-write_wave.json)

Transaction is 32 bits long, divided into 4 bytes :

* First byte : MSB indicates wether the transaction is a write (`0`) operation
* Second byte : register address
* Third byte : register value MSB
* Fourth byte : register value LSB

| Address | Description                                                                       | Example Complete command |
| ------- | --------------------------------------------------------------------------------- | ------------------------ |
| `0x00`  | Set random number generator mode (last bit, `1` for LFSR, `0` for decay sampling) | `0x00000001`             |
| `0x01`  | Set manual seed (2 bytes unsigned) for LFSR                                       | `0x0001BEEF`             |
| `0x02`  | Generate seed from radioactive decay pulses (DNC) for LFSR                        | `0x00020000`             |
| `0x03`  | Choose LFSR Polynomial (2 last bits, see [LFSR for info](#lfsr))                  | `0x00030002`             |

### Read from register

![Read sequence](https://svg.wavedrom.com/github/fred-corp/RDRNG/main/docs/spi-read_wave.json)

Transaction is 32 bits long, divided into 2 MOSI bytes followed by 2 MISO bytes :

* MOSI bytes :
  * First byte : MSB indicates wether the transaction is a read (`1`) operation
  * Second byte : register address
* MISO bytes :
  * Third byte : register value MSB
  * Fourth byte : register value LSB

| Address | Description                                                                       | Example Complete command |
| ------- | --------------------------------------------------------------------------------- | ------------------------ |
| `0x00`  | Read generated number (2 bytes, unsigned)                                         | `0x80000000`             |
| `0x01`  | Read custom seed (2 bytes, unsigned)                                              | `0x80010000`             |
| `0x02`  | Read generated seed from radioactive decay (2 bytes unsigned)                     | `0x80020000`             |
| `0x03`  | Read LFSR polynomial (2 last bits)                                                | `0x80030000`             |

## License & Acknowledgements

Made with ❤️, lots of ☕️, and lack of 🛌  
Published under CreativeCommons BY-SA 4.0

[![Creative Commons License](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)](http://creativecommons.org/licenses/by-sa/4.0/)  
This work is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).
