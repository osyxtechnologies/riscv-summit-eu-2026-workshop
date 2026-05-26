# HW/SW Co-Design of a Multi-Guest Virtualized System with Bao and CVA6

**RISC-V Summit Europe 2026 - Developer Workshop**
*Hosted by [OSYX Technologies](https://osyx.tech) and [Infineon Technologies AG](https://www.infineon.com)*

This repository contains the materials for the hands-on workshop *"HW/SW
Co-Design of a Multi-Guest Virtualized System with Bao and CVA6 in
Automotive"*. By the end of the session, participants will have extended a
pre-configured single-guest Zephyr setup into a fully virtualized
multi-guest system running on a Genesys 2 Kintex-7 FPGA with the CVA6
SPMP-for-Hypervisor RISC-V core.

The same flow is replicated under QEMU so participants can practise, prepare,
and continue exploring after the session even without the FPGA board.

---

## What you will build

```
┌─────────────────────────────┬──────────────────────────────┐
│                             │                              │
│                           shared                           │
│       Zephyr RTOS       ◄─memory─►     Baremetal guest     │
│      (UART console)      channel    (LED + UART console)   │
│                             │                              │
├─────────────────────────────┴──────────────────────────────┤
│                       Bao Hypervisor                       │
├────────────────────────────────────────────────────────────┤
│                          OpenSBI                           │
├────────────────────────────────────────────────────────────┤
│    CVA6  +  SPMP-for-Hypervisor  +  AIA (APLIC + IMSIC)    │
│            UART0  •  UART1  •  AXI GPIO (LEDs)             │
└────────────────────────────────────────────────────────────┘
```

Two isolated guests share the CPU, each owns its own UART, and exchange
messages through a shared memory region. The baremetal guest drives an
on-board LED on command from the Zephyr guest.

---

## Workshop agenda (Jun 8, 17:00 – 18:15)

| Time          | Slot                                                        |
|---------------|-------------------------------------------------------------|
| 17:00 – 17:10 | Introduction to virtualization on RISC-V                   |
| 17:10 – 17:15 | Workshop goals and outline                                  |
| 17:15 – 17:30 | **Bootstrap** - boot the baseline single-guest system       |
| 17:30 – 17:45 | **Milestone 1** - swap the baremetal guest for a Zephyr RTOS guest |
| 17:45 – 18:00 | **Milestone 2** - add the baremetal guest back + inter-VM IPC + LED |
| 18:00 – 18:15 | Wrap-up and Q&A                                             |

---

## Before you arrive

### 1. Clone this repository

```bash
git clone https://github.com/osyxtechnologies/riscv-summit-eu-2026-workshop.git
cd riscv-summit-eu-2026-workshop
```

### 2. Install Docker (Ubuntu / Debian)

If Docker is not already installed, run:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) \
    signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
```

Add your user to the `docker` group so you can run `docker` without `sudo`:

```bash
sudo usermod -aG docker $USER
newgrp docker
```

Verify the installation:

```bash
docker run --rm hello-world
```

You should see a `Hello from Docker!` message. If you do, Docker is ready.

> For Debian, replace `ubuntu` with `debian` in the repository URL above.
> Full instructions: https://docs.docker.com/engine/install/ubuntu/

### 3. Fetch the workshop image

Fetch the pre-built workshop Docker image from Docker Hub (fastest):

```bash
make pull-image
```

Alternatively, build it from source (≈ 15–20 min):

```bash
make build-image
```

---

## At the workshop

A limited number of Genesys 2 Kintex-7 boards will be available - shared
between groups of participants - pre-flashed with the correct CVA6 bitstream
and a USB-attached JTAG / UART adapter. Assistants will sweep the room at
the start of the session to confirm each laptop's container can reach the
board it has been assigned to.

> **No board in your slot?** Every milestone runs identically under QEMU
> on your own laptop - you can follow the entire workshop without touching
> the hardware.

> **Board buttons - quick reference:**
> - **Power-on / after `make flash`:** press the **PROG** button (bottom-left of the board) to load the CVA6 bitstream from SPI flash into the FPGA.
> - **Between `make run` invocations:** press the **RESET** button to put the CVA6 core back in a clean reset state before GDB loads the next image over JTAG.

---

## Prerequisites

### Hardware (for CVA6 on-board runs)

If you plan to run on the **Genesys 2 FPGA board** rather than QEMU, bring the
following to the workshop:

| Item | Notes |
|------|-------|
| Linux laptop - **Ubuntu 22.04 / 24.04 recommended** | macOS and Windows are not tested; USB passthrough into Docker works reliably on Linux |
| [Genesys 2 Kintex-7](https://digilent.com/reference/programmable-logic/genesys-2/reference-manual) board + power supply | - |
| 2× Micro-USB cable | One for the on-board FT2232H (JTAG + UART0), one for the board's USB port |
| USB-to-TTL serial adapter (**FTDI FT232R / CP2102, 3.3 V**) | For the baremetal guest's UART console (milestone 2 onward) |
| 3× male-to-male jumper wires | Connects the adapter to the board's PMOD JD header |
| USB hub (optional) | If your laptop has fewer than 3 free USB-A ports |

> **No hardware?** Every milestone runs identically under QEMU - you can complete the
> full workshop without a board.

#### Connecting the FTDI adapter to PMOD JD

The CVA6 bitstream routes a second UART (`uart2`) to the **PMOD JD** connector.
Milestone 2 uses this port for the baremetal guest's console.

Make three connections between the FTDI adapter and PMOD JD
([Genesys 2 reference manual](https://digilent.com/reference/programmable-logic/genesys-2/reference-manual)):

| FTDI adapter pin | PMOD JD pin | Direction | Signal |
|-----------------|-------------|-----------|--------|
| **RX** | **Pin 1** | board → FTDI | `uart2_tx` (Kintex-7 V27) |
| **TX** | **Pin 2** | FTDI → board | `uart2_rx` (Kintex-7 Y30) |
| **GND** | **Pin 5** | - | Ground |

> TX↔RX are cross-connected: the board's transmit (Pin 1) goes to the adapter's
> receive, and the adapter's transmit goes to the board's receive (Pin 2). GND
> must be shared.

PMOD JD pin layout for reference - **Pin 1 is the upper-right pin**:

```
  ┌──────┬──────┬──────┬──────┬──────┬──────┐
  │  6   │  5   │  4   │  3   │  2   │  1   │
  │ VCC  │ GND◄─┤      │      │←FTDI │←FTDI │
  │      │  ●   │      │      │  TX  │  RX  │
  ├──────┼──────┼──────┼──────┼──────┼──────┤
  │  12  │  11  │  10  │  9   │  8   │  7   │
  │ VCC  │ GND  │      │      │      │      │
  └──────┴──────┴──────┴──────┴──────┴──────┘
  left ◄────────────────────────────── right
  (board-side labels: Pin 1 = uart2_tx, Pin 2 = uart2_rx)
```

The host enumerates the adapter as `/dev/ttyUSB1` (the on-board FT2232H takes
`/dev/ttyUSB0`). Override with `CVA6_UART2=/dev/ttyUSBx` if your system assigns
a different node.

---

## Repository layout

```
.
├── bao-hypervisor/        # Bao submodule (static-partitioning hypervisor)
├── opensbi/               # OpenSBI submodule (M-mode SEE)
├── guests/
│   ├── zephyr/
│   │   ├── zephyr/        # Zephyr RTOS submodule
│   │   ├── apps/          # workshop applications
│   │   │   ├── dual-task/ # two periodic tasks + UART RX handler
│   │   │   ├── console/   # console + shared-mem command channel
│   │   │   └── uart-hello/
│   │   └── boards/        # baovm_qemu-virt-spmp / baovm_cva6-spmp
│   └── baremetal/         # Bao baremetal guest (LED + UART)
├── exercises/             # SKELETON Bao configs - fill these in
│   ├── qemu/{milestone0,milestone1,milestone2}/
│   └── cva6/{milestone0,milestone1,milestone2}/
├── solutions/             # REFERENCE Bao configs - peek when stuck
│   ├── qemu/{milestone0,milestone1,milestone2}/
│   └── cva6/{milestone0,milestone1,milestone2}/
├── cva6/                  # OpenOCD config + GDB scripts + FPGA bitstreams
│   ├── ariane.cfg         # OpenOCD config for the on-board FT2232H JTAG
│   ├── launch.sh          # bring up OpenOCD + attach GDB + open UART panes
│   ├── milestone0.gdb / milestone1.gdb / milestone2.gdb
│   └── bitstreams/{milestone0,milestone1,milestone2}/   # .bit / .mcs + reports
├── scripts/
│   └── qemu-pty.sh        # auto-opens minicom panes for QEMU -serial pty
├── Dockerfile             # workshop image (toolchain, QEMU, OpenOCD, ...)
├── Makefile               # build / run entry point (auto-dispatches into Docker)
└── .tmux.conf             # mouse-on + minicom-kill binding for the tmux session
```

### Build artefacts

All builds land under `build/<platform>/<config>/`. A typical milestone-2
build produces:

```
build/<platform>/milestone2/
├── bao/bao.bin                                # hypervisor + embedded VM configs (linked into fw_payload)
├── baremetal/baremetal.{bin,elf}              # baremetal guest image
├── zephyr/zephyr/zephyr.{bin,elf}             # Zephyr guest image
└── opensbi/platform/<plat>/firmware/
    └── fw_payload.{bin,elf}                   # OpenSBI carrying bao.bin as FW_PAYLOAD
```

The two platforms consume different artefacts of the same build:

- **QEMU** boots `fw_payload.bin` via `-bios` and drops the guest
  images into RAM at fixed addresses with `-device loader,file=*.bin`.
- **CVA6** loads `fw_payload.elf`, `zephyr.elf`, and `baremetal.elf`
  over JTAG from the milestone's `.gdb` script - using ELF lets GDB
  place each section at the right address and keep symbols for
  stepping.

---

## The three milestones

| Milestone | `CONFIG=`     | Guests                                   | New concept                 |
|-----------|---------------|------------------------------------------|-----------------------------|
| 0         | `milestone0`  | 1× baremetal (UART0)                     | minimal single-guest baseline |
| 1         | `milestone1`  | 1× Zephyr (UART0)                        | swap baremetal → RTOS guest |
| 2         | `milestone2`  | 1× Zephyr + 1× baremetal (UART0 + UART1) | device passthrough + inter-VM IPC + LED |

### Exercises vs. solutions

By default the build pulls configuration files from `exercises/<platform>/<config>/config.c`
- these are **skeletons with `/* TODO */` placeholders** that participants
fill in. The reference answers live in `solutions/<platform>/<config>/config.c`.
Append `SOLUTIONS=1` to any make command to build against the reference
config instead:

```bash
make build PLATFORM=qemu CONFIG=milestone1                 # exercises/  (default)
make build PLATFORM=qemu CONFIG=milestone1 SOLUTIONS=1     # solutions/  (reference)
```

---

## FPGA bitstream programming (Genesys 2 / CVA6)

Each milestone uses a dedicated CVA6 SPMP bitstream. The pre-built `.bit`
and `.mcs` files are checked into `cva6/bitstreams/<milestone>/`.

> **At the workshop:** boards arrive pre-flashed with **milestone 0**. You
> only need to reflash when advancing to a new milestone.

### Option A - `make flash` (recommended)

openFPGALoader is included in the workshop Docker image, so no host
installation is needed. Program the SPI flash for the desired milestone
(≈ 2 min):

```bash
make flash CONFIG=milestone0
make flash CONFIG=milestone1
make flash CONFIG=milestone2
```

openFPGALoader writes the `.mcs` image to the Genesys 2's on-board SPI
flash. After programming, **power-cycle the board** (or press the **PROG**
button) to boot the new bitstream. Confirm the green **DONE** LED on the
board is lit - that signals the FPGA has successfully configured from
flash; if it stays off, the bitstream did not load.

> If the FTDI adapter is not found, make sure no other process (e.g. OpenOCD
> from a previous `make run`) is holding the USB device open.

---

### Option B - Vivado Hardware Manager (GUI)

1. Open **Vivado → Hardware Manager → Open Target → Auto Connect**.
   The Genesys 2 should appear as `xc7k325t_0`.

2. Right-click the device → **Add Configuration Memory Device**.
   Search for and select:
   ```
   s25fl256sxxxxxx0-spi-x1_x2_x4
   ```
   Click **OK** and confirm when asked to program it now.

3. In the **Program Configuration Memory Device** dialog:
   - **Configuration file**: select
     `cva6/bitstreams/<milestone>/ariane_xilinx.mcs`
   - Leave all other fields at their defaults.
   - Click **OK**.

   Programming takes ≈ 2 minutes.

4. When Vivado reports success, **power-cycle the board** or press the
   on-board **PROG** button to load the new bitstream from flash.

---

## Quick start

All `make` commands automatically dispatch into the workshop Docker container -
there is no need to open a container shell manually. Just run the commands below
from your host terminal.

### Pick your target once

Most participants stick with a single platform for the whole session. Export it
once at the start of your shell so you do not need to repeat `PLATFORM=...` on
every command:

```bash
export PLATFORM=qemu     # or:  export PLATFORM=cva6
```

(`make` picks `PLATFORM` and `CONFIG` up from the environment as well as from
the command line. The examples below assume you have exported `PLATFORM`; if
you have not, just append `PLATFORM=qemu` / `PLATFORM=cva6` to each command.)

### The basic workflow

`build` and `run` are **independent** steps. The typical loop is:

```bash
make build CONFIG=<c>   # compile guests + Bao + OpenSBI
make run   CONFIG=<c>   # boot the freshly built images
```

Re-run `make build` every time you change anything that needs recompiling
(config files under `exercises/` or `solutions/`, guest source code, Bao,
OpenSBI, etc.). `make run` only boots what is already in `build/$PLATFORM/<c>/`
and will refuse to start if those artefacts are missing.

### Build & run under QEMU

```bash
# Milestone 0  (single baremetal guest on UART0)
make build CONFIG=milestone0
make run   CONFIG=milestone0

# Milestone 1  (single Zephyr guest on UART0)
make build CONFIG=milestone1
make run   CONFIG=milestone1

# Milestone 2  (Zephyr + baremetal + shmem + LED)
make build CONFIG=milestone2
make run   CONFIG=milestone2
```

To exit QEMU type **`Ctrl-A x`** in the main console.

### Build & run on CVA6 (Genesys 2)

> **Before each run:** press the board's **RESET** button to put the CVA6 core in a clean state.
> After flashing a new bitstream (or on power-on), press **PROG** first to load it from SPI flash.

```bash
make build CONFIG=milestone1   # compile guests + Bao + OpenSBI
make run   CONFIG=milestone1   # starts OpenOCD, attaches GDB, loads & runs
```

When `PLATFORM=cva6`, `make run` invokes `cva6/launch.sh cva6/<CONFIG>.gdb`, which:

1. Spawns `openocd` against the FTDI JTAG (config: `cva6/ariane.cfg`).
2. Waits for OpenOCD to be ready.
3. Opens a `minicom` console on `/dev/ttyUSB0` for the CVA6 primary UART.
4. Launches `riscv32-unknown-elf-gdb` with the milestone's `.gdb` script,
   which uses `restore` to flash the raw `.bin` images at their guest
   load addresses and then `continue`.

Override the UART tty with `CVA6_UART=/dev/ttyUSBx` if your host
enumerates the FTDI differently.

---

## CVA6 platform reference

These are the platform constants you will need when filling in the Bao VM
configs under `exercises/cva6/`. They come from the CVA6 SoC package
[`ariane_soc_pkg.sv`](https://github.com/malejo97/cva6/blob/cf796a6a07615e767e8064caf7da9fb59fe394cd/corev_apu/tb/ariane_soc_pkg.sv);
only the entries relevant to the workshop are listed below.

### Memory map

| Region   | Base address    | Size                  | Notes                                          |
|----------|-----------------|-----------------------|------------------------------------------------|
| APLIC    | `0x0C00_0000`   | `0x3FF_FFFF`          | Advanced PLIC (wired interrupts)               |
| UART0    | `0x1000_0000`   | `0x1000`              | On-board FT2232H (peripheral `uart`)           |
| UART1    | `0x1000_2000`   | `0x1000`              | Routed to PMOD JD (peripheral `uart2`)         |
| IMSIC    | `0x2400_0000`   | `0x800_0000`          | MSI controller (per-hart files)                |
| GPIO     | `0x4000_0000`   | `0x1000`              | AXI GPIO (drives the on-board LEDs)            |
| DRAM     | `0x8000_0000`   | `0x4000_0000` (1 GiB) | OpenSBI + Bao + guest images live here         |

### Interrupt sources (APLIC)

| Device   | APLIC source |
|----------|--------------|
| UART0    | 1            |
| UART1    | 8            |

### Workshop DRAM layout

The Makefile and the GDB scripts place every binary at these fixed
addresses; the VM configs you write must match them.

| Region                 | Base address    | Used by                                  |
|------------------------|-----------------|------------------------------------------|
| OpenSBI + Bao          | `0x8000_0000`   | starts at DRAMBase, always present       |
| Guest #0 image         | `0x8420_0000`   | baremetal (m0) / Zephyr (m1, m2)         |
| Guest #1 image         | `0x8820_0000`   | baremetal (m2 only)                      |
| Inter-VM shared memory | `0x8A00_0000`   | 16 KiB, m2 only                          |

---

## QEMU platform reference

For `PLATFORM=qemu` the workshop runs on the `virt` machine with the AIA
interrupt controller enabled:

```
qemu-system-riscv32-spmp -M virt,aia=aplic-imsic,aia-guests=2 -m 4G
```

Only the entries the workshop uses are listed below; see QEMU's
`hw/riscv/virt.c` for the full virt-machine layout.

### Memory map

| Region   | Base address    | Notes                                            |
|----------|-----------------|--------------------------------------------------|
| UART1    | `0x0600_0000`   | Extra NS16550 added by `-serial pty`             |
| APLIC    | `0x0D00_0000`   | S-mode Advanced PLIC (the controller Bao uses)   |
| UART0    | `0x1000_0000`   | Default NS16550, bound to `-serial mon:stdio`    |
| IMSIC    | `0x2800_0000`   | S-mode MSI controller (per-hart files)           |
| DRAM     | `0x8000_0000`   | 4 GiB (`-m 4G`)                                  |

### Interrupt sources (APLIC)

| Device   | APLIC source |
|----------|--------------|
| UART0    | 10           |
| UART1    | 12           |

### Workshop DRAM layout

Identical to CVA6 - the Makefile uses the same fixed addresses on both
platforms:

| Region                 | Base address    | Used by                                  |
|------------------------|-----------------|------------------------------------------|
| OpenSBI + Bao          | `0x8000_0000`   | starts at DRAMBase, always present       |
| Guest #0 image         | `0x8420_0000`   | baremetal (m0) / Zephyr (m1, m2)         |
| Guest #1 image         | `0x8820_0000`   | baremetal (m2 only)                      |
| Inter-VM shared memory | `0x8A00_0000`   | 16 KiB, m2 only                          |

---

## Step-by-step walkthrough

The guided workshop path below uses the CVA6 FPGA board. If you are following
under QEMU instead, export `PLATFORM=qemu` and edit the matching skeletons under
`exercises/qemu/`; the build and run commands are otherwise the same.

### 0. Bootstrap (17:15 – 17:30)

> *Goal: get a working single-guest system (a Bao-hosted baremetal
> guest) on the bench and understand what is already there.*

1. Make sure you have the workshop container image (`make pull-image`).
   For CVA6, also confirm the FPGA board is connected (you should see
   `/dev/ttyUSB0` on the host), the milestone-0 bitstream is loaded, and
   the board has been reset.
2. Build and run **milestone 0** (the baremetal baseline) against the
   reference solution so you can see a working system end to end:
   ```bash
   export PLATFORM=cva6
   make build CONFIG=milestone0 SOLUTIONS=1
   make run   CONFIG=milestone0 SOLUTIONS=1
   ```
   For QEMU, use:
   ```bash
   export PLATFORM=qemu
   make build CONFIG=milestone0 SOLUTIONS=1
   make run   CONFIG=milestone0 SOLUTIONS=1
   ```
3. You should see the baremetal guest booting on the CVA6 UART0
   console and printing a `[heartbeat]` line every second. Under QEMU,
   the same output appears on the main QEMU console.
   Checkpoint: one baremetal guest is running on UART0. Under QEMU, exit
   with **Ctrl-A x** in the main console when you are done observing it.
4. Walk through the source files the speaker highlights:
   - CVA6 Bao config: `solutions/cva6/milestone0/config.c`
   - CVA6 baremetal platform: `guests/baremetal/src/platform/cva6-spmp/cva6.c`
   - QEMU Bao config: `solutions/qemu/milestone0/config.c`
   - QEMU baremetal platform: `guests/baremetal/src/platform/qemu-riscv32-virt-spmp/virt.c`

### 1. Milestone 1 - swap the baremetal for a Zephyr RTOS guest (17:30 – 17:45)

> *Goal: write a new Bao VM config from scratch that replaces the
> baremetal guest with a Zephyr RTOS image. Same physical layout
> (one guest, UART0), but the guest is now a full RTOS.*

1. Open the milestone-1 skeleton:
   ```bash
   $EDITOR exercises/cva6/milestone1/config.c
   ```
   If you are using QEMU, open `exercises/qemu/milestone1/config.c`
   instead. The commands below assume `PLATFORM=cva6` is still exported;
   keep `PLATFORM=qemu` exported for the QEMU path.
   Reference addresses are listed at the top of the file. You must
   describe a single `vm_config` entry for the Zephyr guest:
   - image load address + entry point
   - memory region
   - UART0 device passthrough
   - AIA base addresses
2. For CVA6, flash the matching bitstream if the board is not already
   programmed:
   ```bash
   make flash CONFIG=milestone1
   ```
   This takes about 2 minutes; skip it if an assistant has already flashed
   the board. Press **PROG** after flashing and press **RESET** before
   `make run`.

   Build and run:
   ```bash
   make build CONFIG=milestone1
   make run   CONFIG=milestone1
   ```
3. You should see Zephyr's `dual-task` app booting on UART0:
   ```
   *** Booting Zephyr OS build ...
   Zephyr dual-task demo (board: baovm_cva6-spmp/cv32a6)
   [task_a] cpu0 iter=0
   [task_b] cpu0 iter=0
   ```
   Checkpoint: one Zephyr guest is running on UART0. Under QEMU, exit with
   **Ctrl-A x** in the main console when you are done observing it.
4. If stuck, append `SOLUTIONS=1` to both commands to peek at the
   reference config.

### 2. Milestone 2 - add a second guest + inter-VM communication (17:45 – 18:00)

> *Goal: add the baremetal back as a second isolated VM with its own
> UART, then connect the two guests with a shared memory region + a
> notification IRQ so Zephyr can drive the LED via the baremetal.
> Observe that the SPMP partitions memory and devices between the
> two guests on the same core.*

1. Open the milestone-2 skeleton (it extends the milestone-1 config
   you just wrote):
   ```bash
   $EDITOR exercises/cva6/milestone2/config.c
   ```
   If you are using QEMU, open `exercises/qemu/milestone2/config.c`
   instead. The commands below assume the same `PLATFORM` value you used
   for milestone 1 is still exported.
   You must add:
   - `vmlist_size = 2` plus a second `vm_config` entry for the
     baremetal guest (UART1 + AXI GPIO passthrough on CVA6, or the
     LED log shim under QEMU, plus AIA base addresses)
   - A top-level `shmemlist` entry (base `0x8A000000`, size `0x4000`)
   - For **each** VM's `platform`, an `ipcs` entry that maps the
     same shmem region and assigns the notification IRQ (APLIC source
     `3`)
2. The supporting code is already in place: the Bao baremetal source
   handles UART1 + the AXI GPIO
   (`guests/baremetal/src/platform/cva6-spmp/cva6.c`), and the Zephyr
   `console` app already speaks the shmem command protocol.
   For QEMU, the matching baremetal platform file is
   `guests/baremetal/src/platform/qemu-riscv32-virt-spmp/virt.c`; LED
   commands are logged on the console instead of driving hardware.
3. For CVA6, flash the matching bitstream if the board is not already
   programmed:
   ```bash
   make flash CONFIG=milestone2
   ```
   This takes about 2 minutes; skip it if an assistant has already flashed
   the board. Press **PROG** after flashing and press **RESET** before
   `make run`.

   Build and run:
   ```bash
   make build CONFIG=milestone2
   make run   CONFIG=milestone2
   ```
4. **What to look for:**
   - The baremetal console is UART1 and the Zephyr console is UART0.
     In the default tmux layout, baremetal appears on the left and
     Zephyr on the right.
   - Both guests print independently - confirming the SPMP is
     partitioning CPU time and memory between them.
   - The Zephyr `console` app boots straight into Zephyr's shell
     (prompt `uart:~$`). Send a command to the baremetal peer over
     the shmem with the `baoipc write_notify` subcommand:
     ```
     uart:~$ baoipc write_notify 0 "led on"
     uart:~$ baoipc write_notify 0 "led off"
     uart:~$ baoipc write_notify 0 "led blink"
     ```
     `baoipc write_notify <id> <msg>` copies `<msg>` into the write
     half of the shmem channel and raises the notification IRQ on
     the peer; `<id>` is the channel ID declared in the app's
     device-tree overlay (`0` here). The baremetal services the
     IRQ, reads `<msg>` from its read half of the shmem, and either
     drives the on-board LED accordingly (on CVA6) or logs the
     action on its UART (under QEMU, where there is no real LED).
     Unknown messages are printed verbatim on the baremetal console
     as `[shmem rx] from zephyr: "..."`, which is a handy way to
     check the channel is wired up before you trust the LED.

   Checkpoint: Zephyr accepts commands on UART0, the baremetal LED /
   console reacts on UART1, and you can see both guests scheduling
   independently. Under QEMU, exit with **Ctrl-A x** in the main
   console.

---

## Useful make targets

```text
make help                                Show this list.
make pull-image                          Fetch the pre-built image from Docker Hub (recommended).
make build-image                         Build the workshop Docker image from source (~15 min).
make push-image                          Push the locally-built image to Docker Hub (maintainers only).
make shell                               Open a tmux session inside the container.
make flash CONFIG=<c>                    Program Genesys 2 SPI flash with milestone bitstream.

make build PLATFORM=<p> CONFIG=<c>       Compile everything for the scenario.
make run   PLATFORM=<p> CONFIG=<c>       Build + boot under QEMU or on CVA6.
make clean PLATFORM=<p> CONFIG=<c>       Wipe the build/<p>/<c>/ tree.

make build-zephyr     PLATFORM=<p> CONFIG=<c>   Cross-compile Zephyr only.
make build-baremetal  PLATFORM=<p> CONFIG=<c>   Cross-compile baremetal only.
make build-bao        PLATFORM=<p> CONFIG=<c>   Build Bao with the scenario cfg.
make build-opensbi    PLATFORM=<p> CONFIG=<c>   Wrap Bao in OpenSBI FW_PAYLOAD.
```

`PLATFORM` values: `qemu`, `cva6`.
`CONFIG` values: `milestone0`, `milestone1`, `milestone2`.
`SOLUTIONS=1` to build from `solutions/` instead of `exercises/`.

---

## Troubleshooting

### `riscv32-unknown-elf-gdb: error while loading shared libraries: libpython3.10.so.1.0`

The pinned RISC-V toolchain links against Python 3.10. The Dockerfile
installs `libpython3.10` from the deadsnakes PPA. If you see this on a
custom host (outside the container), install the package the same way.

### tmux split-window not opening / mouse-click does not switch panes

`make shell` invokes tmux with `-f .tmux.conf` (mouse on). If you launch
tmux yourself, pass the same config or do `set -g mouse on`. The auto
PTY-attach (for QEMU's `-serial pty`) is driven by `scripts/qemu-pty.sh`.

### `mkdir: cannot create directory '.../build/...': Permission denied`

The `build/` directory was created by a previous container run as root.
Delete it from inside the container (`sudo rm -rf build/`) or chown it
back to your host user (`sudo chown -R $(id -u):$(id -g) build/`).

---

## Background and further reading

- **Bao Hypervisor** - https://github.com/bao-project/bao-hypervisor
- **CVA6 (OpenHW Group)** - https://github.com/openhwgroup/cva6
- **RISC-V SPMP / SPMP-for-Hypervisor**: WIP extension that brings
  hardware-enforced supervisor-mode physical memory protection to
  MCU-class cores without an MMU, enabling Bao-style static
  partitioning on Linux-less platforms.
- **RISC-V AIA (Advanced Interrupt Architecture)** - APLIC + IMSIC,
  used here for MSI-style interrupt delivery into each guest.
- **Zephyr RTOS** - https://www.zephyrproject.org

---

## Credits

- **Joerg Seitter & Boerge Schmelz** - Infineon Technologies (workshop speakers)
- **Sandro Pinto** - OSYX Technologies/Bao project (workshop speaker)
- **Jose Martins, David Cerdeira, Daniel Oliveira, Manuel Rodriguez** - OSYX/Bao project (workshop materials)
