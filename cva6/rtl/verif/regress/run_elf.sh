# Copyright 2021 Thales DIS design services SAS
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
# You may obtain a copy of the License at https://solderpad.org/licenses/
#
# Original Author: El guebo redondo
# Set the NUM_JOBS variable to increase the number of parallel make jobs
export NUM_JOBS=12
TARGET="cv64a6_imafdch_sv39"
VARIANT="rv64imafdch"
ELF_PATH="/home/manuale97/sPMP/bao-spmp-demo/output/fw_payload.o"
PATH_VAR="/home/manuale97/sPMP/cva6"
TOOL_PATH="/home/manuale97/sPMP/cva6/tools/spike/bin"
LOG="logfile"
CV_SW_PREFIX="riscv-none-elf-"
TRACE=""
# TRACE="DEBUG=1 TRACE_FAST=1"
# Not needed but used
ISS_COMP_OPTS=""
ISS_RUN_OPTS="+time_out=40000000 +debug_disable=1"
ISS_POSTRUN_OPTS=""
make -C verif/sim/ veri-testharness target=${TARGET} variant=${VARIANT} elf=${ELF_PATH} path_var=${PATH_VAR}\
    tool_path=${TOOL_PATH} log=${LOG} CV_SW_PREFIX=${CV_SW_PREFIX} issrun_opts="${ISS_RUN_OPTS}" ${TRACE}