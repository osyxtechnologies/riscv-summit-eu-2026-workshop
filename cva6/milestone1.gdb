target extended-remote :3333

load build/cva6/milestone1/zephyr/zephyr/zephyr.elf
load build/cva6/milestone1/opensbi/platform/fpga/ariane/firmware/fw_payload.elf

continue
