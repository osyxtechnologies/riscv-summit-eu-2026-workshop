/*
 * Copyright (c) 2022 BayLibre, SAS
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * - RISC-V S-mode Physical Memory Protection (SPMP) provides per-hart S-mode 
 * control registers to allow physical memory access privileges (read, write, 
 * execute) to be specified for each physical memory region. So we use it 
 * for memory protection when kernel is on S-mode. 
 *
 * The SPMP is comprized of a number of entries or slots. This number depends
 * on the hardware design. For each slot there is an address register and
 * a configuration register. While each address register is matched to an
 * actual CSR register, configuration registers are small and therefore
 * several of them are bundled in a few additional CSR registers.
 *
 * SPMP slot configurations are updated in memory to avoid read-modify-write
 * cycles on corresponding CSR registers. Relevant CSR registers are always
 * written in batch from their shadow copy in RAM for better efficiency.
 *
 * In the stackguard case we keep an s-mode copy for each thread. Each user
 * mode threads also has a u-mode copy. This makes faster context switching
 * as precomputed content just have to be written to actual registers with
 * no additional processing.
 *
 * Thread-specific s-mode and u-mode SPMP entries start from the SPMP slot
 * indicated by global_spmp_end_index. Lower slots are used by global entries
 * which are never modified.
 */

#include <kernel_internal.h>
#include <spmp.h>
#include <zephyr/arch/riscv/csr.h>
#include <zephyr/kernel.h>
#include <zephyr/linker/linker-defs.h>
#include <zephyr/arch/arch_interface.h>
#include <zephyr/arch/riscv/arch.h>

#define LOG_LEVEL CONFIG_MPU_LOG_LEVEL
#include <zephyr/logging/log.h>
LOG_MODULE_REGISTER(mpu);


#ifdef CONFIG_64BIT
#define PR_ADDR "0x%016lx"
#else
#define PR_ADDR "0x%08lx"
#endif

#define SPMP_TOR_SUPPORTED !IS_ENABLED(CONFIG_SPMP_NO_TOR)
#define SPMP_NA4_SUPPORTED !IS_ENABLED(CONFIG_SPMP_NO_NA4)
#define SPMP_NAPOT_SUPPORTED !IS_ENABLED(CONFIG_SPMP_NO_NAPOT)

#define SPMPCFG_STRIDE sizeof(unsigned long)

#define SPMP_ADDR(addr) ((addr) >> 2)
#define NAPOT_RANGE(size) (((size)-1) >> 1)
#define SPMP_ADDR_NAPOT(addr, size) SPMP_ADDR(addr | NAPOT_RANGE(size))

#define SPMP_NONE 0

/**
 * @brief Set SPMP shadow register values in memory
 *
 * Register content is built using this function which selects the most
 * appropriate address matching mode automatically. Note that the special
 * case start=0 size=0 is valid and means the whole address range.
 *
 * @param index_p Location of the current SPMP slot index to use. This index
 *                will be updated according to the number of slots used.
 * @param perm SPMP permission flags
 * @param start Start address of the memory area to cover
 * @param size Size of the memory area to cover
 * @param spmp_addr Array of spmpaddr values (starting at entry 0).
 * @param spmp_cfg Array of spmpcfg values (starting at entry 0).
 * @param index_limit Index value representing the size of the provided arrays.
 * @return true on success, false when out of free SPMP slots.
 */
static bool set_spmp_entry(unsigned int *index_p, uint16_t perm,
						uintptr_t start, size_t size,
						unsigned long *spmp_addr, uint16_t *spmp_cfg,
						unsigned long *spmp_switch, unsigned int index_limit) {
	unsigned int index = *index_p;
	bool ok = true;

	__ASSERT((start & 0x3) == 0, "misaligned start address");
	__ASSERT((size & 0x3) == 0, "misaligned size");

	if (index >= index_limit) {
		LOG_ERR("out of SPMP slots");
		ok = false;
	} else if (SPMP_TOR_SUPPORTED &&
			((index == 0 && start == 0) ||
				(index != 0 && spmp_addr[index - 1] == SPMP_ADDR(start)))) {
		/* We can use TOR using only one additional slot */
		spmp_addr[index] = SPMP_ADDR(start + size);
		spmp_cfg[index] = perm | SPMP_TOR;
		spmp_switch[index/(RV_REGSIZE*8)] |= (1UL << ((index%(RV_REGSIZE*8))));
		index += 1;
	} else if (SPMP_NA4_SUPPORTED && size == 4) {
		spmp_addr[index] = SPMP_ADDR(start);
		spmp_cfg[index] = perm | SPMP_NA4;
		spmp_switch[index/(RV_REGSIZE*8)] |= (1UL << ((index%(RV_REGSIZE*8))));
		index += 1;
	} else if (SPMP_NAPOT_SUPPORTED &&
			((size & (size - 1)) == 0) /* power of 2 */ &&
			((start & (size - 1)) == 0) /* naturally aligned */ &&
			(SPMP_NA4_SUPPORTED || (size != 4))) {
		spmp_addr[index] = SPMP_ADDR_NAPOT(start, size);
		spmp_cfg[index] = perm | SPMP_NAPOT;
		spmp_switch[index/(RV_REGSIZE*8)] |= (1UL << ((index%(RV_REGSIZE*8))));
		index += 1;
	} else if (SPMP_TOR_SUPPORTED && index + 1 >= index_limit) {
		LOG_ERR("out of SPMP slots");
		ok = false;
	} else if (SPMP_TOR_SUPPORTED) {
		spmp_addr[index] = SPMP_ADDR(start);
		spmp_cfg[index] = 0;
		index += 1;
		spmp_addr[index] = SPMP_ADDR(start + size);
		spmp_cfg[index] = perm | SPMP_TOR;
		spmp_switch[index/(RV_REGSIZE*8)] |= (1UL << ((index%(RV_REGSIZE*8))));
		index += 1;
	} else {
		LOG_ERR("inappropriate SPMP range (start=%#lx size=%#zx)", start, size);
		ok = false;
	}

	*index_p = index;
	return ok;
}

/**
 * @brief Write a range of SPMP entries to corresponding SPMP registers
 *
 * SPMP registers are accessed with the csr instruction which only takes an
 * immediate value as the actual register. This is performed more efficiently
 * in assembly code (spmp.S) than what is possible with C code.
 *
 * Requirement: start < end && end <= CONFIG_SPMP_SLOTS
 *
 * @param start Start of the SPMP range to be written
 * @param end End (exclusive) of the SPMP range to be written
 * @param clear_trailing_entries True if trailing entries must be turned off
 * @param spmp_addr Array of spmpaddr values (starting at entry 0).
 * @param spmp_cfg Array of spmpcfg values (starting at entry 0).
 * @param spmp_switch spmpswitch value to be written
 */
extern void z_riscv_write_spmp_entries(unsigned int start, unsigned int end,
									const uint16_t *spmp_cfg,
									const unsigned long *spmp_addr,
									const unsigned long *spmp_switch);

/**
 * @brief Write a range of SPMP entries to corresponding SPMP registers
 *
 * This performs some sanity checks before calling z_riscv_write_spmp_entries().
 *
 * @param start Start of the SPMP range to be written
 * @param end End (exclusive) of the SPMP range to be written
 * @param clear_trailing_entries True if trailing entries must be turned off
 * @param spmp_addr Array of spmpaddr values (starting at entry 0).
 * @param spmp_cfg Array of spmpcfg values (starting at entry 0).
 * @param index_limit Index value representing the size of the provided arrays.
 */
static void write_spmp_entries(unsigned int start, unsigned int end,
							bool clear_trailing_entries,
							unsigned long *spmp_addr, uint16_t *spmp_cfg,
							unsigned long *spmp_switch, unsigned int index_limit) {
	__ASSERT(start < end && end <= index_limit &&
				index_limit <= CONFIG_SPMP_SLOTS,
			"bad SPMP range (start=%u end=%u)", start, end);

	/* Be extra paranoid in case assertions are disabled */
	if (start >= end || end > index_limit) {
		k_panic();
	}

	if (clear_trailing_entries) {
		/*
		* There are many config entries per spmpcfg register.
		* Make sure to clear trailing garbage in the last
		* register to be written if any. Remaining registers
		* will be cleared in z_riscv_write_spmp_entries().
		*/
		unsigned int index;

		for (index = end; index % SPMPCFG_STRIDE != 0; index++) {
			spmp_cfg[index] = 0;
			*spmp_switch &= ~(1UL << index);
		}
	}

#ifdef CONFIG_QEMU_TARGET
	/*
	* A QEMU bug may create bad transient SPMP representations causing
	* false access faults to be reported. Work around it by setting
	* spmp registers to zero from the update start point to the end
	* before updating them with new values.
	* The QEMU fix is here with more details about this bug:
	* https://lists.gnu.org/archive/html/qemu-devel/2022-06/msg02800.html
	*/
	static const unsigned long spmp_zero[CONFIG_SPMP_SLOTS] = {
		0,
	};

	z_riscv_write_spmp_entries(start, CONFIG_SPMP_SLOTS,
							spmp_zero, spmp_zero, spmp_zero);
#endif

	z_riscv_write_spmp_entries(start, end,
							spmp_cfg, spmp_addr, spmp_switch);
}

/**
 * @brief Abstract the last 4 arguments to set_spmp_entry() and
 *        write_spmp_entries for s-mode.
 */
#define SPMP_S_MODE(thread)                 \
	thread->arch.s_mode_spmpaddr_regs,      \
		thread->arch.s_mode_spmpcfg_regs,   \
		thread->arch.s_mode_spmpswitch_reg, \
		ARRAY_SIZE(thread->arch.s_mode_spmpaddr_regs)

/**
 * @brief Abstract the last 4 arguments to set_spmp_entry() and
 *        write_spmp_entries for u-mode.
 */
#define SPMP_U_MODE(thread)                 \
	thread->arch.u_mode_spmpaddr_regs,      \
		thread->arch.u_mode_spmpcfg_regs,   \
		thread->arch.u_mode_spmpswitch_reg, \
		ARRAY_SIZE(thread->arch.u_mode_spmpaddr_regs)

/*
* This is used to seed thread SPMP copies with global s-mode cfg entries
* sharing the same cfg register. 
*/
static uint16_t global_spmp_cfg[1];
static unsigned long global_spmp_last_addr;

/* End of global SPMP entry range */
static unsigned int global_spmp_end_index;

/**
 * @Brief Initialize the SPMP with global entries on each CPU
 */
void z_riscv_spmp_init(void) {
	unsigned long spmp_addr[CONFIG_SPMP_SLOTS];
	uint16_t spmp_cfg[CONFIG_SPMP_SLOTS];
	unsigned long spmp_switch[2] = {0, 0};
	unsigned int index = 0;

	/* Read-only area: Shared RX */
	set_spmp_entry(&index, SPMP_SHARED | SPMP_L | SPMP_R | SPMP_X,
				(uintptr_t)__rom_region_start,
				(size_t)__rom_region_size,
				spmp_addr, spmp_cfg, spmp_switch, ARRAY_SIZE(spmp_addr));

	/* Data region: Shared RW */
	set_spmp_entry(&index, SPMP_SHARED | SPMP_L | SPMP_R | SPMP_W,
				(uintptr_t)__kernel_ram_start,
				(size_t)__kernel_ram_size,
				spmp_addr, spmp_cfg, spmp_switch, ARRAY_SIZE(spmp_addr));

#ifdef CONFIG_NULL_POINTER_EXCEPTION_DETECTION_SPMP
	/*
	* Use a SPMP slot to make region (starting at address 0x0) inaccessible
	* for detecting null pointer dereferencing
	*/
	set_spmp_entry(&index, SPMP_NONE,
				0,
				CONFIG_NULL_POINTER_EXCEPTION_REGION_SIZE,
				spmp_addr, spmp_cfg, spmp_switch, ARRAY_SIZE(spmp_addr));
#endif

#ifdef CONFIG_SPMP_STACK_GUARD
	/*
	* Set the stack guard for this CPU's IRQ stack by making the bottom
	* addresses inaccessible.
	*/
	set_spmp_entry(&index, SPMP_NONE,
				(uintptr_t)z_interrupt_stacks[_current_cpu->id],
				Z_RISCV_STACK_GUARD_SIZE,
				spmp_addr, spmp_cfg, spmp_switch, ARRAY_SIZE(spmp_addr));
#endif

	write_spmp_entries(0, index, true, spmp_addr, spmp_cfg, spmp_switch, ARRAY_SIZE(spmp_addr));

#ifdef CONFIG_SMP
#ifdef CONFIG_SPMP_STACK_GUARD
	/*
	* The IRQ stack guard area is different for each CPU.
	* Make sure TOR entry sharing won't be attempted with it by
	* remembering a bogus address for those entries.
	*/
	spmp_addr[index - 1] = -1L;
#endif

	/* Make sure secondary CPUs produced the same values */
	if (global_spmp_end_index != 0) {
		__ASSERT(global_spmp_end_index == index, "");
		__ASSERT(global_spmp_cfg[0] == spmp_cfg[0], "");
		__ASSERT(global_spmp_last_addr == spmp_addr[index - 1], "");
	}
#endif

	global_spmp_cfg[0] = spmp_cfg[0];
	global_spmp_last_addr = spmp_addr[index - 1];
	global_spmp_end_index = index;

}

/**
 * @Brief Initialize the per-thread SPMP register copy with global values.
 */
static inline unsigned int z_riscv_spmp_thread_init(unsigned long *spmp_addr,
												uint16_t *spmp_cfg,
												unsigned long *spmp_switch,
												unsigned int index_limit) {
	ARG_UNUSED(index_limit);
	ARG_UNUSED(spmp_switch);

	/*
	* Retrieve spmpcfg0 partial content from global entries.
	*/
	spmp_cfg[0] = global_spmp_cfg[0];

	/*
	* Retrieve the spmpaddr value matching the last global SPMP slot.
	* This is so that set_spmp_entry() can safely attempt TOR with it.
	*/
	spmp_addr[global_spmp_end_index - 1] = global_spmp_last_addr;

	return global_spmp_end_index;
}

#ifdef CONFIG_SPMP_STACK_GUARD

/**
 * @brief Prepare the SPMP stackguard content for given thread.
 *
 * This is called once during new thread creation.
 */
void z_riscv_spmp_stackguard_prepare(struct k_thread *thread) {
	unsigned int index = z_riscv_spmp_thread_init(SPMP_S_MODE(thread));
	uintptr_t stack_bottom;

	/* make the bottom addresses of our stack inaccessible */
	stack_bottom = thread->stack_info.start - K_KERNEL_STACK_RESERVED;
#ifdef CONFIG_USERSPACE
	if (thread->arch.priv_stack_start != 0) {
		stack_bottom = thread->arch.priv_stack_start;
	} else if (z_stack_is_user_capable(thread->stack_obj)) {
		stack_bottom = thread->stack_info.start - K_THREAD_STACK_RESERVED;
	}
#endif
	set_spmp_entry(&index, SPMP_NONE,
				stack_bottom, Z_RISCV_STACK_GUARD_SIZE,
				SPMP_S_MODE(thread));

	/* remember how many entries we use */
	thread->arch.s_mode_spmp_end_index = index;
}

/**
 * @brief Write SPMP stackguard content to actual SPMP registers
 *
 * This is called on every context switch.
 */
void z_riscv_spmp_stackguard_enable(struct k_thread *thread) {
	LOG_DBG("spmp_stackguard_enable for thread %p", thread);

	/* Write our m-mode MPP entries */
	write_spmp_entries(global_spmp_end_index, thread->arch.s_mode_spmp_end_index,
					false /* no need to clear to the end */,
					SPMP_S_MODE(thread));
}

#endif /* CONFIG_SPMP_STACK_GUARD */

#ifdef CONFIG_USERSPACE

/**
 * @brief Initialize the usermode portion of the SPMP configuration.
 *
 * This is called once during new thread creation.
 */
void z_riscv_spmp_usermode_init(struct k_thread *thread) {
	/* Only indicate that the u-mode SPMP is not prepared yet */
	thread->arch.u_mode_spmp_end_index = 0;
}

/**
 * @brief Prepare the u-mode SPMP content for given thread.
 *
 * This is called once before making the transition to usermode.
 */
void z_riscv_spmp_usermode_prepare(struct k_thread *thread) {
	unsigned int index = z_riscv_spmp_thread_init(SPMP_U_MODE(thread));

	LOG_DBG("spmp_usermode_prepare for thread %p", thread);

	/* Map the usermode stack */
	set_spmp_entry(&index, SPMP_U | SPMP_R | SPMP_W,
				thread->stack_info.start, thread->stack_info.size,
				SPMP_U_MODE(thread));

	thread->arch.u_mode_spmp_domain_offset = index;
	thread->arch.u_mode_spmp_end_index = index;
	thread->arch.u_mode_spmp_update_nr = 0;
}

/**
 * @brief Convert partition information into SPMP entries
 */
static void resync_spmp_domain(struct k_thread *thread,
							struct k_mem_domain *domain) {
	unsigned int index = thread->arch.u_mode_spmp_domain_offset;
	int p_idx, remaining_partitions;
	bool ok;

	k_spinlock_key_t key = k_spin_lock(&z_mem_domain_lock);

	remaining_partitions = domain->num_partitions;
	for (p_idx = 0; remaining_partitions > 0; p_idx++) {
		struct k_mem_partition *part = &domain->partitions[p_idx];

		if (part->size == 0) {
			/* skip empty partition */
			continue;
		}

		remaining_partitions--;

		if (part->size < 4) {
			/* * 4 bytes is the minimum we can map */
			LOG_ERR("non-empty partition too small");
			__ASSERT(false, "");
			continue;
		}

		ok = set_spmp_entry(&index, (SPMP_U | SPMP_W | SPMP_X),
						part->start, part->size, SPMP_U_MODE(thread));
		__ASSERT(ok,
				"no SPMP slot left for %d remaining partitions in domain %p",
				remaining_partitions + 1, domain);
	}

	thread->arch.u_mode_spmp_end_index = index;
	thread->arch.u_mode_spmp_update_nr = domain->arch.spmp_update_nr;

	k_spin_unlock(&z_mem_domain_lock, key);
}

/**
 * @brief Write SPMP usermode content to actual SPMP registers
 *
 * This is called on every context switch.
 */
void z_riscv_spmp_usermode_enable(struct k_thread *thread) {
	struct k_mem_domain *domain = thread->mem_domain_info.mem_domain;

	LOG_DBG("spmp_usermode_enable for thread %p with domain %p", thread, domain);

	if (thread->arch.u_mode_spmp_end_index == 0) {
		/* z_riscv_spmp_usermode_prepare() has not been called yet */
		return;
	}

	if (thread->arch.u_mode_spmp_update_nr != domain->arch.spmp_update_nr) {
		/*
		* Resynchronize our SPMP entries with
		* the latest domain partition information.
		*/
		resync_spmp_domain(thread, domain);
	}

	/* Write our u-mode SPMP entries */
	write_spmp_entries(global_spmp_end_index, thread->arch.u_mode_spmp_end_index,
					true /* must clear to the end */,
					SPMP_U_MODE(thread));

}

int arch_mem_domain_max_partitions_get(void) {
	int available_spmp_slots = CONFIG_SPMP_SLOTS;

	/* remove those slots dedicated to global entries */
	available_spmp_slots -= global_spmp_end_index;

	/*
	* User thread stack mapping:
	* 1 slot if CONFIG_MPU_REQUIRES_POWER_OF_TWO_ALIGNMENT=y,
	* most likely 2 slots otherwise.
	*/
	available_spmp_slots -=
		IS_ENABLED(CONFIG_MPU_REQUIRES_POWER_OF_TWO_ALIGNMENT) ? 1 : 2;

	/*
	* Each partition may require either 1 or 2 SPMP slots depending
	* on a couple factors that are not known in advance. Even when
	* arch_mem_domain_partition_add() is called, we can't tell if a
	* given partition will fit in the remaining SPMP slots of an
	* affected thread if it hasn't executed in usermode yet.
	*
	* Give the most optimistic answer here (which should be pretty
	* accurate if CONFIG_MPU_REQUIRES_POWER_OF_TWO_ALIGNMENT=y) and be
	* prepared to deny availability in resync_spmp_domain() if this
	* estimate was too high.
	*/
	return available_spmp_slots;
}

int arch_mem_domain_init(struct k_mem_domain *domain) {
	domain->arch.spmp_update_nr = 0;
	return 0;
}

int arch_mem_domain_partition_add(struct k_mem_domain *domain,
								uint32_t partition_id) {
	/* Force resynchronization for every thread using this domain */
	domain->arch.spmp_update_nr += 1;
	return 0;
}

int arch_mem_domain_partition_remove(struct k_mem_domain *domain,
									uint32_t partition_id) {
	/* Force resynchronization for every thread usinginit this domain */
	domain->arch.spmp_update_nr += 1;
	return 0;
}

int arch_mem_domain_thread_add(struct k_thread *thread) {
	/* Force resynchronization for this thread */
	thread->arch.u_mode_spmp_update_nr = 0;
	return 0;
}

int arch_mem_domain_thread_remove(struct k_thread *thread) {
	return 0;
}

#define IS_WITHIN(inner_start, inner_size, outer_start, outer_size)    \
	((inner_start) >= (outer_start) && (inner_size) <= (outer_size) && \
	((inner_start) - (outer_start)) <= ((outer_size) - (inner_size)))

int arch_buffer_validate(const void *addr, size_t size, int write) {
	uintptr_t start = (uintptr_t)addr;
	int ret = -1;

	/* Check if this is on the stack */
	if (IS_WITHIN(start, size,
				_current->stack_info.start, _current->stack_info.size)) {
		return 0;
	}

	/* Check if this is within the global read-only area */
	if (!write) {
		uintptr_t ro_start = (uintptr_t)__rom_region_start;
		size_t ro_size = (size_t)__rom_region_size;

		if (IS_WITHIN(start, size, ro_start, ro_size)) {
			return 0;
		}
	}

	/* Look for a matching partition in our memory domain */
	struct k_mem_domain *domain = _current->mem_domain_info.mem_domain;
	int p_idx, remaining_partitions;
	k_spinlock_key_t key = k_spin_lock(&z_mem_domain_lock);

	remaining_partitions = domain->num_partitions;
	for (p_idx = 0; remaining_partitions > 0; p_idx++) {
		struct k_mem_partition *part = &domain->partitions[p_idx];

		if (part->size == 0) {
			/* unused partition */
			continue;
		}

		remaining_partitions--;

		if (!IS_WITHIN(start, size, part->start, part->size)) {
			/* unmatched partition */
			continue;
		}

		/* partition matched: determine access result */
		if ((part->attr.spmp_attr & (write ? SPMP_W : SPMP_R)) != 0) {
			ret = 0;
		}
		break;
	}

	k_spin_unlock(&z_mem_domain_lock, key);
	return ret;
}

#endif /* CONFIG_USERSPACE */
