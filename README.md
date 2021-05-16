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


## Implementation details.
The core is implemented in Verilog.


## FuseSoC
This core is supported by the
[FuseSoC](https://github.com/olofk/fusesoc) core package manager and
build system. Some quick  FuseSoC instructions:

install FuseSoC
~~~
pip install fusesoc
~~~

Create and enter a new workspace
~~~
mkdir workspace && cd workspace
~~~

Register aes as a library in the workspace
~~~
fusesoc library add aes /path/to/aes
~~~

...if repo is available locally or...
...to get the upstream repo
~~~
fusesoc library add aes https://github.com/secworks/aes
~~~

To run lint
~~~
fusesoc run --target=lint secworks:crypto:aes
~~~

Run tb_aes testbench
~~~
fusesoc run --target=tb_aes secworks:crypto:aes
~~~

Run with modelsim instead of default tool (icarus)
~~~
fusesoc run --target=tb_aes --tool=modelsim secworks:crypto:aes
~~~

List all targets
~~~
fusesoc core show secworks:crypto:aes
~~~


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
