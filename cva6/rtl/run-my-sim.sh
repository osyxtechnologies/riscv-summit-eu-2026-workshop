#!/bin/bash

# MUST BE INVOKED FROM ROOT CVA6 DIRECTORY
# Set $RISCV environment variable before running

source verif/sim/setup-env.sh

export NUM_JOBS=12

TRACE=""
# TRACE="DEBUG=1 TRACE_FAST=1"

TARGET="cv64a6_imafdch_sv39"
ELF_PATH="/home/manuale97/sPMP/riscv-hyp-tests/build/cva6/rvh_test.elf"
LOG="spmp_log"

make -C verif/sim veri-testharness \
	path_var=/home/manuale97/sPMP/cva6 \
	verilator=/home/manuale97/sPMP/cva6/tools/verilator/bin/verilator \
	target=${TARGET} \
	elf=${ELF_PATH} \
	issrun_opts="+time_out=40000000 +debug_disable=1 +ntb_random_seed=1" \
	log=${LOG} \
	tool_path=/home/manuale97/sPMP/cva6/tools/spike/bin \
	variant=rv64gch_zba_zbb_zbs_zbc \
	isspostrun_opts=0 \
	${TRACE}