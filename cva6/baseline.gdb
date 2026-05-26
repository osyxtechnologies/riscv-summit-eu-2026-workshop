# Workshop bootstrap: Bao + single Zephyr guest.
#
# For milestone 1 / 2 copy this file and adjust the `add-symbol-file` path
# to point at the matching Bao config's bao.elf (and add a `load` for the
# baremetal guest ELF when one is configured).

tui enable
layout src
focus cmd

target extended-remote :3333

# Guests are loaded into RAM because the Bao configuration uses
# VM_IMAGE_LOADED rather than embedding them in the Bao binary.
load guests/zephyr/build/zephyr/zephyr.elf

# OpenSBI runs in M-mode and chainloads Bao (S-mode) via FW_PAYLOAD.
load opensbi/build/platform/fpga/ariane/firmware/fw_payload.elf

# Bao symbols only - the binary is already inside the OpenSBI FW_PAYLOAD above.
add-symbol-file bao-hypervisor/bin/cva6-spmp/baseline/bao.elf
