SHELL := /bin/bash

workshop_root := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))

CROSS_COMPILE   ?= riscv32-unknown-elf-
WORKSHOP_IMAGE  ?= osyxtechnologies/riscv-summit-workshop:latest

# CVA6 UART console devices (FTDI USB-serial bridges on the Genesys 2).
# UART0 is the primary console; UART1 is opened only when present.
CVA6_UART  ?= /dev/ttyUSB0
CVA6_UART2 ?= /dev/ttyUSB1

.DEFAULT_GOAL := help

# ---------------------------------------------------------------------------
# Container auto-dispatch.
#
# When the make command is invoked on the host, re-run the requested goal
# inside the workshop Docker image so users do not need to `make shell`
# first. Set NO_DOCKER=1 to skip the dispatch (e.g. when the host already
# has the toolchain installed, or for Makefile debugging).
#
# Detection: /.dockerenv exists in every Docker container's root filesystem.
# ---------------------------------------------------------------------------
_host_only_goals  := help build-image pull-image push-image shell
_dispatched_goals := $(filter-out $(_host_only_goals),$(or $(MAKECMDGOALS),help))

ifeq ($(wildcard /.dockerenv),)
ifndef NO_DOCKER
ifneq ($(_dispatched_goals),)
_in_dispatch := 1

# Forward command-line overrides into the in-container make invocation.
_fwd_vars := PLATFORM CONFIG SOLUTIONS CVA6_UART CVA6_UART2 CROSS_COMPILE WORKSHOP_IMAGE
_fwd_args := $(foreach v,$(_fwd_vars),$(if $($(v)),$(v)=$($(v))))

.PHONY: $(_dispatched_goals)

_image_check = \
	docker image inspect $(WORKSHOP_IMAGE) >/dev/null 2>&1 || { \
		echo "workshop image '$(WORKSHOP_IMAGE)' not found."; \
		echo "Run 'make pull-image' to fetch it from Docker Hub, or 'make build-image' to build locally."; \
		exit 1; \
	}

_docker_run = docker run --rm -it \
	-v $(workshop_root):$(workshop_root):rw \
	-v /dev/bus/usb:/dev/bus/usb \
	$(if $(wildcard $(CVA6_UART)),--device $(CVA6_UART)) \
	$(if $(wildcard $(CVA6_UART2)),--device $(CVA6_UART2)) \
	--privileged \
	-w $(workshop_root) \
	$(WORKSHOP_IMAGE)

# Non-run goals: build, clean, build-* -- plain in-container make.
_non_run_goals := $(filter-out run,$(_dispatched_goals))

ifneq ($(_non_run_goals),)
$(_non_run_goals):
	@$(_image_check)
	$(_docker_run) bash -c '\
		git config --global --add safe.directory "*" && \
		make $@ NO_DOCKER=1 $(_fwd_args)'
endif

_launch_error := $(workshop_root)/.launch-error

# Minimum terminal size for the side-by-side console layout. tmux refuses
# to split (and may fail to start) in a window smaller than this, which
# otherwise produces an instant, silent exit.
_run_min_cols  := 100
_run_min_lines := 24

ifneq ($(filter run,$(MAKECMDGOALS)),)
run:
	@$(_image_check)
	@rm -f $(_launch_error)
	$(_docker_run) bash -c '\
		git config --global --add safe.directory "*" && \
		size="$$(stty size 2>/dev/null)"; \
		if [ -n "$$size" ]; then \
			set -- $$size; rows=$$1; cols=$$2; \
			if [ "$$cols" -lt $(_run_min_cols) ] || [ "$$rows" -lt $(_run_min_lines) ]; then \
				printf "\nTerminal window is too small (%sx%s).\nThe workshop opens side-by-side console panes and needs at least %sx%s.\nMaximize or enlarge this terminal window and run the command again.\n\n" \
					"$$cols" "$$rows" "$(_run_min_cols)" "$(_run_min_lines)" >&2; \
				exit 1; \
			fi; \
		fi; \
		tmux -f .tmux.conf new-session "make run NO_DOCKER=1 $(_fwd_args)" ; \
		if [ -s "$(_launch_error)" ]; then \
			echo ""; cat "$(_launch_error)"; \
			rm -f "$(_launch_error)"; \
		fi'
endif

endif # _dispatched_goals non-empty
endif # NO_DOCKER
endif # not in container

ifndef _in_dispatch
# ===========================================================================
# Inside-container (or NO_DOCKER=1) path: the real recipes.
# ===========================================================================

# Targets that work without PLATFORM / CONFIG.
_standalone_goals := help build-image pull-image push-image shell flash clean-all

# Enable full build-mode when at least one non-standalone goal is requested.
ifneq ($(filter-out $(_standalone_goals), $(or $(MAKECMDGOALS),help)),)
_build_mode := 1
endif

# ---------------------------------------------------------------------------
# Everything below here requires PLATFORM and CONFIG.
# ---------------------------------------------------------------------------
ifdef _build_mode

ifndef PLATFORM
$(error PLATFORM is not set. Use PLATFORM=qemu or PLATFORM=cva6)
endif

ifeq ($(filter qemu cva6,$(PLATFORM)),)
$(error PLATFORM=$(PLATFORM) is not valid. Supported values: qemu, cva6)
endif

ifndef CONFIG
$(error CONFIG is not set. Use CONFIG=milestone0, milestone1 or milestone2)
endif

ifeq ($(filter milestone0 milestone1 milestone2,$(CONFIG)),)
$(error CONFIG=$(CONFIG) is not valid. Supported values: milestone0, milestone1, milestone2)
endif

config_dir := $(workshop_root)/$(if $(SOLUTIONS),solutions,exercises)/$(PLATFORM)
config := $(config_dir)/$(CONFIG)

ifeq ($(wildcard $(config)),)
$(error CONFIG=$(CONFIG): no such config directory $(config))
endif

# Submodule roots
bao_dir     := $(workshop_root)/bao-hypervisor
opensbi_dir := $(workshop_root)/opensbi
zephyr_dir  := $(workshop_root)/guests/zephyr
zephyr_src  := $(zephyr_dir)/zephyr

# Per-config build paths
build_dir     := $(workshop_root)/build/$(PLATFORM)/$(CONFIG)
zephyr_build  := $(build_dir)/zephyr
bao_bin       := $(build_dir)/bao/bao.bin
opensbi_build := $(build_dir)/opensbi

# ---------------------------------------------------------------------------
# Scenario settings -- what gets built, regardless of platform.
# ---------------------------------------------------------------------------

ifeq ($(CONFIG),milestone0)

BAREMETAL_APP  := $(workshop_root)/guests/baremetal
baremetal_bin  := $(build_dir)/baremetal/baremetal.bin
# Place the baremetal guest where the Zephyr image normally lives so the same
# single-VM physical layout works across milestones. The actual UART address /
# IRQ for UART0 is set in the platform block below (differs by platform).
PLAT_MEM_BASE  := 0x84200000
_qemu_extra_serials :=
_qemu_guest_loaders  = \
    -device loader,file=$(baremetal_bin),addr=0x84200000

else ifeq ($(CONFIG),milestone1)

ZEPHYR_APP     ?= $(workshop_root)/guests/zephyr/apps/dual-task
ZEPHYR_OVERLAY ?=
_qemu_extra_serials :=
_qemu_guest_loaders  = \
    -device loader,file=$(zephyr_build)/zephyr/zephyr.bin,addr=0x84200000

else ifeq ($(CONFIG),milestone2)

ZEPHYR_APP     ?= $(workshop_root)/guests/zephyr/apps/console
ZEPHYR_OVERLAY ?= $(ZEPHYR_APP)/app.overlay
BAREMETAL_APP  := $(workshop_root)/guests/baremetal
baremetal_bin  := $(build_dir)/baremetal/baremetal.bin
SHMEM_BASE     := 0x8A000000
SHMEM_SIZE     := 0x00004000
_qemu_extra_serials := -serial pty
_qemu_guest_loaders  = \
    -device loader,file=$(zephyr_build)/zephyr/zephyr.bin,addr=0x84200000 \
    -device loader,file=$(baremetal_bin),addr=0x88200000

endif

# ---------------------------------------------------------------------------
# Platform settings -- toolchain, board IDs, QEMU command.
# ---------------------------------------------------------------------------

ifeq ($(PLATFORM),qemu)

BAO_PLATFORM  ?= qemu-riscv32-virt-spmp
ZEPHYR_BOARD  ?= baovm_qemu-virt-spmp
OPENSBI_PLAT  ?= generic
QEMU          ?= qemu-system-riscv32-spmp

# Milestone 0 wires the baremetal guest to UART0 (instead of UART1) on QEMU.
ifeq ($(CONFIG),milestone0)
PLAT_UART_ADDR := 0x10000000
UART_IRQ_ID    := 10
endif

QEMU_CPU    := rv32,priv_spec=v1.13.0,sstc=true,spmp=true,sspmpsw=true,sshspmp=true,ssvspmp=true,sshspmpsw=true
# Bare QEMU argv wrapped by scripts/qemu-pty.sh for tmux PTY handling.
QEMU_CMD     = $(QEMU) \
               -M virt,aia=aplic-imsic,aia-guests=2 \
               -cpu $(QEMU_CPU) \
               -smp 1 -m 4G -nographic \
               -bios $(opensbi_payload) \
               -serial mon:stdio $(_qemu_extra_serials) \
               $(_qemu_guest_loaders)
# qemu-pty.sh splits a tmux pane per QEMU-created PTY.
QEMU_INVOKE  = $(workshop_root)/scripts/qemu-pty.sh $(QEMU_CMD)

else ifeq ($(PLATFORM),cva6)

BAO_PLATFORM  ?= cva6-spmp
ZEPHYR_BOARD  ?= baovm_cva6-spmp
OPENSBI_PLAT  ?= fpga/ariane

# Milestone 0 wires the baremetal guest to UART0 (instead of UART1) on CVA6.
ifeq ($(CONFIG),milestone0)
PLAT_UART_ADDR := 0x10000000
UART_IRQ_ID    := 1
endif

endif

# QEMU loads the raw binary; CVA6 is flashed via JTAG/OpenOCD from the ELF.
ifeq ($(PLATFORM),qemu)
opensbi_payload := $(opensbi_build)/platform/$(OPENSBI_PLAT)/firmware/fw_payload.bin
else
opensbi_payload := $(opensbi_build)/platform/$(OPENSBI_PLAT)/firmware/fw_payload.elf
endif

bao_cfg_repo  := $(config_dir)
zephyr_prefix := $(shell which $(CROSS_COMPILE)gcc | sed 's/.\{3\}$$//')
zephyr_env    := \
	ZEPHYR_TOOLCHAIN_VARIANT=cross-compile \
	CROSS_COMPILE=$(zephyr_prefix)

endif # _build_mode

# ---------------------------------------------------------------------------

NPROC := $(shell nproc)

.PHONY: help build run clean clean-all flash \
        build-zephyr build-bao build-opensbi build-baremetal \
        build-image pull-image push-image shell

help:
	@echo "Workshop targets (PLATFORM= and CONFIG= required):"
	@echo "  make build PLATFORM=<p> CONFIG=<c>"
	@echo "       Cross-compile every guest applicable to <c>, then Bao + OpenSBI."
	@echo "  make run   PLATFORM=<p> CONFIG=<c>"
	@echo "       Build (if needed) and boot the scenario."
	@echo "       - PLATFORM=qemu : runs in QEMU (auto-opens PTY panes in tmux)."
	@echo "       - PLATFORM=cva6 : OpenOCD + GDB load the images over JTAG."
	@echo "  make clean PLATFORM=<p> CONFIG=<c>"
	@echo "       Wipe the build/<p>/<c>/ tree and subrepo artifacts for that config."
	@echo "  make clean-all"
	@echo "       Wipe build/ entirely and all subrepo artifacts (no PLATFORM/CONFIG needed)."
	@echo ""
	@echo "Component targets (PLATFORM= and CONFIG= required):"
	@echo "  make build-zephyr / build-bao / build-opensbi / build-baremetal"
	@echo ""
	@echo "FPGA target (CVA6 / Genesys 2 only):"
	@echo "  make flash CONFIG=<c>"
	@echo "       Program the Genesys 2 SPI flash with the pre-built .mcs bitstream"
	@echo "       for <c> via openFPGALoader (runs inside the workshop container)."
	@echo ""
	@echo "Utility targets (no PLATFORM/CONFIG needed):"
	@echo "  make pull-image    Fetch the pre-built image from Docker Hub (recommended)."
	@echo "  make build-image   Build the workshop Docker image locally (one-time, ~15 min)."
	@echo "  make push-image    Push the locally-built image to Docker Hub (maintainers only)."
	@echo "  make shell    Open a tmux session inside the workshop Docker image."
	@echo ""
	@echo "PLATFORM values:   qemu  cva6"
	@echo "CONFIG values:     milestone0  milestone1  milestone2"
	@echo "SOLUTIONS=1        Use solutions/ configs instead of exercises/ (default)"
	@echo "NO_DOCKER=1        Run targets on the host instead of inside the container"
	@echo ""
	@echo "Examples:"
	@echo "  make pull-image"
	@echo "  make flash CONFIG=milestone0"
	@echo "  make build PLATFORM=qemu CONFIG=milestone1"
	@echo "  make run   PLATFORM=qemu CONFIG=milestone2 SOLUTIONS=1"
	@echo "  make run   PLATFORM=cva6 CONFIG=milestone1"

# Program the Genesys 2 SPI flash with the pre-built .mcs bitstream for CONFIG.
# Runs on the host (not inside Docker) using openFPGALoader.
flash:
	@[ -n "$(CONFIG)" ] || { \
		echo "ERROR: CONFIG is required."; \
		echo "  Usage: make flash CONFIG=milestone0|milestone1|milestone2"; \
		exit 1; \
	}
	@case "$(CONFIG)" in \
	    milestone0|milestone1|milestone2) ;; \
	    *) echo "ERROR: CONFIG=$(CONFIG) is not valid. Use milestone0, milestone1, or milestone2"; exit 1;; \
	esac
	@command -v openFPGALoader >/dev/null 2>&1 || { \
		echo "ERROR: openFPGALoader not found. Rebuild the workshop image: make build-image"; \
		exit 1; \
	}
	@echo "[flash] Programming Genesys 2 SPI flash with $(CONFIG) bitstream (~2 min)..."
	openFPGALoader -b genesys2 $(workshop_root)/cva6/bitstreams/$(CONFIG)/ariane_xilinx.mcs
	@echo "[flash] Done. Power-cycle the board or press the PROG button to boot from flash."

# Build every guest applicable to the active CONFIG, then Bao + OpenSBI.
build: $(if $(ZEPHYR_APP),build-zephyr) $(if $(BAREMETAL_APP),build-baremetal) build-opensbi

# `make run` boots on the selected platform; it does NOT build first --
# build and run are independent steps. Run `make build` separately when
# guest sources change.
ifdef _build_mode
ifeq ($(PLATFORM),qemu)
run:
	$(QEMU_INVOKE)
else ifeq ($(PLATFORM),cva6)
# launch.sh defaults CVA6_UART/CVA6_UART2 to /dev/ttyUSB0 and /dev/ttyUSB1
# respectively, and skips the second minicom pane gracefully if UART1 is
# not present. Override on the command line to retarget either device.
run:
	CVA6_UART=$(CVA6_UART) CVA6_UART2=$(CVA6_UART2) \
		$(workshop_root)/cva6/launch.sh $(workshop_root)/cva6/$(CONFIG).gdb
endif
endif

build-zephyr:
	$(zephyr_env) cmake -GNinja \
		-DCMAKE_PREFIX_PATH=$(zephyr_src)/share/zephyr-package \
		-B$(zephyr_build) \
		-DBOARD_ROOT=$(zephyr_dir) \
		-DBOARD=$(ZEPHYR_BOARD) \
		$(if $(strip $(ZEPHYR_OVERLAY)),-DDTC_OVERLAY_FILE=$(ZEPHYR_OVERLAY)) \
		-DZEPHYR_MODULES=$(workshop_root) \
		$(ZEPHYR_APP)
	$(zephyr_env) ninja -C $(zephyr_build)

build-bao:
	$(MAKE) -C $(bao_dir) \
		PLATFORM=$(BAO_PLATFORM) \
		CONFIG_REPO=$(bao_cfg_repo) \
		CONFIG=$(CONFIG) \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		-j$(NPROC)
	mkdir -p $(dir $(bao_bin))
	cp $(bao_dir)/bin/$(BAO_PLATFORM)/$(CONFIG)/bao.bin $(bao_bin)

build-opensbi: build-bao
	$(MAKE) -C $(opensbi_dir) \
		O=$(opensbi_build) \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		PLATFORM=$(OPENSBI_PLAT) \
		PLATFORM_RISCV_XLEN=32 \
		FW_PAYLOAD=y \
		FW_PAYLOAD_PATH=$(bao_bin) \
		$(if $(filter cva6,$(PLATFORM)),FW_FDT_PATH=$(opensbi_dir)/platform/fpga/ariane/ariane.dtb) \
		-j$(NPROC)

build-baremetal:
	$(MAKE) -C $(BAREMETAL_APP) \
		PLATFORM=$(BAO_PLATFORM) \
		BUILD_DIR=$(build_dir)/baremetal \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		$(if $(SHMEM_BASE),SHMEM_BASE=$(SHMEM_BASE) SHMEM_SIZE=$(SHMEM_SIZE)) \
		$(if $(PLAT_MEM_BASE),PLAT_MEM_BASE=$(PLAT_MEM_BASE)) \
		$(if $(PLAT_UART_ADDR),PLAT_UART_ADDR=$(PLAT_UART_ADDR)) \
		$(if $(UART_IRQ_ID),UART_IRQ_ID=$(UART_IRQ_ID)) \
		-j$(NPROC)

# Helper used by the host-side terminal dispatch to obtain the fully
# expanded QEMU argv (depends on PLATFORM, CONFIG, and several scenario
# variables that live inside the _build_mode block above).
.PHONY: _print-qemu-cmd
_print-qemu-cmd:
	@printf '%s' "$(QEMU_CMD)"

clean:
	-$(MAKE) -C $(bao_dir) clean \
		PLATFORM=$(BAO_PLATFORM) \
		CONFIG_REPO=$(bao_cfg_repo) \
		CONFIG=$(CONFIG)
	-rm -rf $(opensbi_dir)/build
	-rm -rf $(if $(BAREMETAL_APP),$(BAREMETAL_APP)/build)
	rm -rf $(workshop_root)/build

clean-all:
	-rm -rf $(workshop_root)/bao-hypervisor/bin
	-rm -rf $(workshop_root)/bao-hypervisor/build
	-rm -rf $(workshop_root)/opensbi/build
	-rm -rf $(workshop_root)/guests/baremetal/build
	rm -rf $(workshop_root)/build

build-image:
	docker build -t $(WORKSHOP_IMAGE) $(workshop_root)

pull-image:
	docker pull $(WORKSHOP_IMAGE)

push-image:
	docker push $(WORKSHOP_IMAGE)

# Interactive shell in the workshop image. The host's workshop tree is
# bind-mounted in at the same path so build artefacts under build/ are
# usable from either the host or another shell. Run `make pull-image` first if
# the image doesn't exist yet.
shell:
	@docker image inspect $(WORKSHOP_IMAGE) >/dev/null 2>&1 || { \
		echo "workshop image '$(WORKSHOP_IMAGE)' not found."; \
		echo "Run 'make pull-image' to fetch it from Docker Hub, or 'make build-image' to build locally."; \
		exit 1; \
	}
	-docker run --rm -it \
		-v $(workshop_root):$(workshop_root):rw \
		-v /dev/bus/usb:/dev/bus/usb \
		--privileged \
		-w $(workshop_root) \
		$(WORKSHOP_IMAGE) bash -c '\
			git config --global --add safe.directory "*" && \
			exec tmux -f .tmux.conf new-session -s workshop'

endif # _in_dispatch
