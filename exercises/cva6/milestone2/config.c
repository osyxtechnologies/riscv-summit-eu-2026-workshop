/**
 * SPDX-License-Identifier: Apache-2.0
 *
 * Exercise 02 -- Zephyr + baremetal guests on CVA6 with IPC shared memory.
 *
 * Goal: configure Bao to boot two isolated VMs that communicate over a
 * shared memory region. Each VM gets its own UART console. The baremetal
 * guest also controls the on-board LED via the AXI GPIO peripheral.
 *
 * Memory map reference (CVA6 FPGA, riscv32):
 *   Zephyr image:    0x84200000  (16 MiB)
 *   Baremetal image: 0x88200000  (16 MiB)
 *   IPC shmem:       0x8A000000  (16 KiB = 2x 8 KiB channels)
 *     Zephyr  writes [shmem+0x0000, shmem+0x2000)
 *     Zephyr  reads  [shmem+0x2000, shmem+0x4000)
 *   UART0 (NS16550): 0x10000000  APLIC source 1   -> Zephyr
 *   UART1 (NS16550): 0x10002000  APLIC source 8   -> baremetal
 *   AXI GPIO (LEDs): 0x40000000  no interrupt     -> baremetal
 *   APLIC:           0x0d000000
 *   IMSIC:           0x28000000
 *   IPC interrupt:   APLIC source 3 (injected by Bao on shmem notify)
 */

#include <config.h>

struct config config = {

    /* TODO: declare the shared memory region */
    .shmemlist_size = 1,
    .shmemlist = (struct shmem[]) {
        [0] = {
            /* TODO: shmem physical base and size */
            .base = /* TODO */,
            .size = /* TODO */,
        },
    },

    .vmlist_size = 2,
    .vmlist = (struct vm_config[]) {

        /* VM1: Zephyr ----------------------------------------------------- */
        {
            .image = VM_IMAGE_LOADED(/* TODO */, /* TODO */, /* TODO */),
            .entry = /* TODO */,

            .platform = {
                .cpu_num = 1,

                .region_num = 1,
                .regions = (struct vm_mem_region[]) {
                    {
                        .base = /* TODO */,
                        .size = /* TODO */,
                    },
                },

                /* TODO: wire the IPC channel into this VM */
                .ipc_num = 1,
                .ipcs = (struct ipc[]) {
                    {
                        /* TODO: shmem base, size, shmem_id, and IPC interrupt */
                        .base          = /* TODO */,
                        .size          = /* TODO */,
                        .shmem_id      = /* TODO */,
                        .interrupt_num = 1,
                        .interrupts    = (irqid_t[]) {/* TODO */}
                    }
                },

                .dev_num = 1,
                .devs = (struct vm_dev_region[]) {
                    {
                        /* TODO: UART0 for Zephyr console */
                        .pa   = /* TODO */,
                        .va   = /* TODO */,
                        .size = 0x1000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {/* TODO */}
                    },
                },

                .arch = {
                    .irqc.aia.aplic.base = /* TODO */,
                    .irqc.aia.imsic.base = /* TODO */,
                },
            },
        },

        /* VM2: Baremetal --------------------------------------------------- */
        {
            .image = VM_IMAGE_LOADED(/* TODO */, /* TODO */, /* TODO */),
            .entry = /* TODO */,

            .platform = {
                .cpu_num = 1,

                .region_num = 1,
                .regions = (struct vm_mem_region[]) {
                    {
                        .base = /* TODO */,
                        .size = /* TODO */,
                    }
                },

                /* TODO: wire the IPC channel into this VM */
                .ipc_num = 1,
                .ipcs = (struct ipc[]) {
                    {
                        .base          = /* TODO */,
                        .size          = /* TODO */,
                        .shmem_id      = /* TODO */,
                        .interrupt_num = 1,
                        .interrupts    = (irqid_t[]) {/* TODO */}
                    }
                },

                /* TODO: two devices -- UART1 for console, AXI GPIO for LEDs.
                 * The GPIO has no interrupt (output only). */
                .dev_num = 2,
                .devs = (struct vm_dev_region[]) {
                    {
                        /* TODO: UART1 for baremetal console */
                        .pa   = /* TODO */,
                        .va   = /* TODO */,
                        .size = 0x1000,
                        .interrupt_num = 1,
                        .interrupts = (irqid_t[]) {/* TODO */}
                    },
                    {
                        /* TODO: AXI GPIO for LED control */
                        .pa   = /* TODO */,
                        .va   = /* TODO */,
                        .size = 0x1000,
                        .interrupt_num = 0,
                    },
                },

                .arch = {
                    .irqc.aia.aplic.base = /* TODO */,
                    .irqc.aia.imsic.base = /* TODO */,
                },
            },
        },
    }
};
