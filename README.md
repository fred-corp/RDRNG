# Radioactive Decay Random number generator

![OpenLane Workflow](https://github.com/fred-corp/RDRNG/actions/workflows/gds.yaml/badge.svg)

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

### `0xAA` - Write to register

![Read sequence](https://svg.wavedrom.com/github/fred-corp/RDRNG/main/docs/spi-write_wave.json)

Data to be written to the register should always be 2 bytes long.

| Address | Description                                                                       | Example Complete command |
| ------- | --------------------------------------------------------------------------------- | ------------------------ |
| `0x00`  | Set random number generator mode (last bit, `1` for LFSR, `0` for decay sampling) | `0xAA 0x00 0x00 0x01`    |
| `0x01`  | Set manual seed (2 bytes unsigned) for LFSR                                       | `0xAA 0x01 0xBE 0xEF`    |
| `0x02`  | Generate seed from radioactive decay pulses (DNC) for LFSR                        | `0xAA 0x02 0x00 0x00`    |
| `0x03`  | Choose LFSR Polynomial (2 last bits, see [LFSR for info](#lfsr))                  | `0xAA 0x03 0x00 0x02`    |

### `0x55` - Read from register

![Read sequence](https://svg.wavedrom.com/github/fred-corp/RDRNG/main/docs/spi-read_wave.json)

| Address | Description                                                                       | Example Complete command |
| ------- | --------------------------------------------------------------------------------- | ------------------------ |
| `0x00`  | Read generated number (2 bytes, unsigned)                                         | `0x55 0x01 0x00 0x00`    |
| `0x01`  | Read custom seed (2 bytes, unsigned)                                              | `0x55 0x01 0x00 0x00`    |
| `0x02`  | Read generated seed from radioactive decay (2 bytes unsigned)                     | `0x55 0x02 0x00 0x00`    |
| `0x03`  | Read LFSR polynomial (2 last bits)                                                | `0x55 0x03 0x00 0x00`    |

## License & Acknowledgements

Made with ❤️, lots of ☕️, and lack of 🛌  
Published under CreativeCommons BY-SA 4.0

[![Creative Commons License](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)](http://creativecommons.org/licenses/by-sa/4.0/)  
This work is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).
