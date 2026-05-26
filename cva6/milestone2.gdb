target extended-remote :3333

load build/cva6/milestone2/zephyr/zephyr/zephyr.elf
load build/cva6/milestone2/baremetal/baremetal.elf
load build/cva6/milestone2/opensbi/platform/fpga/ariane/firmware/fw_payload.elf

continue
