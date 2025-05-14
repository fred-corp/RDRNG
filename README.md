# Radioactive Decay Random number generator

![OpenLane Workflow](https://github.com/fred-corp/RDRNG/actions/workflows/gds.yaml/badge.svg)

## Summary

## Description

## Modes

### Decay sampling

### LFSR

## SPI Command Set

### `0xAA` - Write to register

Data to be written to the register should always be 2 bytes long.

| Address | Description                                                                       | Example Complete command |
| ------- | --------------------------------------------------------------------------------- | ------------------------ |
| `0x00`  | Set random number generator mode (last bit, `1` for LFSR, `0` for decay sampling) | `0xAA 0x00 0x00 0x01`    |
| `0x01`  | Set manual seed (2 bytes unsigned)                                                | `0xAA 0x01 0xBE 0xEF`    |
| `0x02`  | Generate seed from radioactive decay pulses (DNC)                                 | `0xAA 0x02 0x00 0x00`    |
| `0x03`  | Choose LFSR Polynomial (2 last bits, see [LFSR for info](#lfsr))                  | `0xAA 0x03 0x00 0x02`    |

### `0x55` - Read from register

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
