#===================================================================
#
# Makefile
# --------
# Makefile for building the md5 core and top simulations.
#
#
# Author: Joachim Strombergson
# Copyright (c) 2014, Secworks Sweden AB
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or
# without modification, are permitted provided that the following
# conditions are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in
#    the documentation and/or other materials provided with the
#    distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
# COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
# INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#===================================================================

MODEL_SRC = ../src/model/md5.c

CORE_SRC=../src/rtl/md5_core.v
TOP_SRC=../src/rtl/md5.v $(CORE_SRC)

TB_CORE_SRC =../src/tb/tb_md5_core.v
TB_TOP_SRC =../src/tb/tb_md5.v

CC = iverilog
CC_FLAGS = -Wall

LINT = verilator
LINT_FLAGS = +1364-2001ext+ --lint-only  -Wall -Wno-fatal -Wno-DECLFILENAME


all: top.sim core.sim md5_model


top.sim: $(TB_TOP_SRC) $(TOP_SRC)
	$(CC) $(CC_FLAGS) -o top.sim $(TB_TOP_SRC) $(TOP_SRC)


core.sim: $(TB_CORE_SRC) $(CORE_SRC)
	$(CC) $(CC_FLAGS) -o core.sim $(TB_CORE_SRC) $(CORE_SRC)


md5_model: $(MODEL_SRC)
	clang -Wall -o md5_model $(MODEL_SRC)


sim-top: top.sim
	./top.sim


sim-core: core.sim
	./core.sim


lint:  $(TOP_SRC)
	$(LINT) $(LINT_FLAGS) $(TOP_SRC)


clean:
	rm -f top.sim
	rm -f core.sim
	rm -f md5_model

help:
	@echo "Build system for simulation of AES Verilog core"
	@echo ""
	@echo "Supported targets:"
	@echo "------------------"
	@echo "all:          Build all simulation targets."
	@echo "top.sim:      Build top level simulation target."
	@echo "core.sim:     Build core level simulation target."
	@echo "sim-top:      Run top level simulation."
	@echo "sim-core:     Run core level simulation."
	@echo "lint:         Lint all rtl source files."
	@echo "clean:        Delete all built files."

#===================================================================
# EOF Makefile
#===================================================================
