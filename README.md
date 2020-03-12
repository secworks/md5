# md5
Hardware implementation of the md5 hash function.

## Status
Completed. Does Work. **Do. Not. Use.** (Unless you know what you do.)


## Introduction
The [hash function md5](https://en.wikipedia.org/wiki/MD5) is a broken
hash function that shouldn't be used. But sometimes one needs the
implementation of a broken hash function anyway...

Do use this to for example break things like password hashes. Do NOT use
it to protect anything - password hashes for example.


## Implementation
The core is implemented in Verilog.


### Implementation Results

## Altera FPGAs
* Tool:   Intel Quartus Prime 19.1
* Device: Cyclone V - 5CGXFC7C6U19C7
* ALMs:   673
* Regs:   1385
* Fmax:   85 MHz


## Xilinx FPGAs
* Tool:   Xilinx Vivado
* Device: Artix-7 - xc7a200tsbv484-2
* LUT:    786
* Regs:   1295
* Fmax:   119 MHz
