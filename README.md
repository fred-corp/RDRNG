# Radioactive Decay Random number generator

[![OpenLane Workflow](https://github.com/fred-corp/RDRNG/actions/workflows/gds.yaml/badge.svg)](https://github.com/fred-corp/RDRNG/actions/workflows/gds.yaml) [![GitHub Release](https://img.shields.io/github/v/release/fred-corp/RDRNG?display_name=release)](https://github.com/fred-corp/RDRNG/releases/latest)

## Summary

* [Summary](#summary)
* [Description](#description)
* [Modes](#modes)
  * [Decay sampling](#decay-sampling)
  * [LFSR](#lfsr)
* [SPI Command Set](#spi-command-set)
* [links, tools and sources](#links-tools-and-sources)
* [License & Acknowledgements](#license--acknowledgements)

## Description

> A project report is available in the [docs](/docs/project_report.pdf) folder.

This project implements a hardware random number generator (RNG) based on the stochastic nature of radioactive decay events. The design is intended for use in applications requiring high-entropy random numbers, such as cryptographic systems or secure communications.

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

![Write sequence](/docs/images/spi-write_wave.png)

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

![Read sequence](/docs/images/spi-read_wave.png)

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

## FPGA Implementation

![FPGA Schematic](/docs/images/fpga_schematic.drawio.png)

The design is implemented in VHDL and synthesized using the Open Logic FPGA Standard library.

## Links, tools and sources

* Random number generation, Wikipedia, https://en.wikipedia.org/wiki/Random_number_generation
* Hardware random number generator, Wikipedia, https://en.wikipedia.org/wiki/Hardware_random_number_generator
* Cover page illustration created with OpenLane2, gds3xtrude, and OpenScad
* Apple Intelligence for syntax and grammar verification
* GitHub Copilot for code debugging
* Open Logic FPGA Standard library, https://github.com/open-logic/open-logic
* WaveDrom to create signal bus diagrams, https://wavedrom.com/
* TerosHDL, Yosys, GHDL to generate netlist diagrams from VHDL sources
* OSS CAD Suite for RTL Synthesis, https://github.com/YosysHQ/oss-cad-suite-build
* TinyVision pico-ice, https://pico-ice.tinyvision.ai/
* R. Zafar et al., « Randomness from Radiation: Evaluation and Analysis of Radiation-Based Random Number Generators », 30 September 2024, arXiv: arXiv:2409.20492. doi : [10.48550/arXiv.2409.20492](http://doi.org/10.48550/arXiv.2409.20492).
* J. L. Anderson et G. W. Spangler, « Serial statistics. Is radioactive decay random », J. Phys. Chem., vol. 77, no. 26, p. 3114–3121, Dec. 1973, doi : [10.1021/j100644a019](http://doi.org/10.1021/j100644a019).
* A. Alkassar, T. Nicolay, et M. Rohe, « Obtaining True-Random Binary Numbers from a Weak Radioactive Source », in Computational Science and Its Applications – ICCSA 2005, Springer, Berlin, Heidelberg, 2005, p. 634–646. doi : [10.1007/11424826_67](http://doi.org/10.1007/11424826_67).

## License & Acknowledgements

Made with ❤️, lots of ☕️, and lack of 🛌  
Published under CreativeCommons BY-SA 4.0

[![Creative Commons License](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)](http://creativecommons.org/licenses/by-sa/4.0/)  
This work is licensed under a [Creative Commons Attribution-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-sa/4.0/).
