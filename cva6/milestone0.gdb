target extended-remote :3333

load build/cva6/milestone0/baremetal/baremetal.elf
load build/cva6/milestone0/opensbi/platform/fpga/ariane/firmware/fw_payload.elf

continue
