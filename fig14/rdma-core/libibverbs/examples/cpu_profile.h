#ifndef __CPU_PROFILE_H__
#define __CPU_PROFILE_H__

//#define USE_CPUID
//#ifdef USE_CPUID
static inline uint64_t my_read_cycles(void)
{
	unsigned cycles_low, cycles_high;

	asm volatile("CPUID\n\t"
			"RDTSC\n\t"
			"mov %%edx, %0\n\t"
			"mov %%eax, %1\n\t": "=r" (cycles_high), "=r" (cycles_low)::
			"%rax", "%rbx", "%rcx", "%rdx");
	return ( ((uint64_t)cycles_high  << 32) | cycles_low  );
}

static inline uint64_t my_update_cycles(void)
{
	unsigned cycles_low, cycles_high;

	asm volatile("RDTSCP\n\t"
			"mov %%edx, %0\n\t"
			"mov %%eax, %1\n\t"
			"CPUID\n\t": "=r" (cycles_high), "=r" (cycles_low)::
			"%rax", "%rbx", "%rcx", "%rdx");

	return ( ((uint64_t)cycles_high << 32) | cycles_low );
}
//#else
//#define my_read_cycles get_cycles
//#define my_update_cycles get_cycles
//#endif /* USE_CPUID */

/*
	preempt_disable(); 			// disable preemption on this core
	raw_local_irq_save(flags); 	// disable hard interrupts on this core
	start = my_read_cycles()

	end = my_update_cycles();
	raw_local_irq_restore(flags);
	preempt_enable();
 */


#define LARGE_UL_INT 0xffffffff
#define ROUNDS 100000
static uint64_t calibrate(void)
{
	uint64_t start, end,  diff = 0;
	uint64_t min = LARGE_UL_INT, max = 0, tmp = 0;
	int i;

	for( i = 0; i < ROUNDS; i++) {

		start = my_read_cycles();
		//  tested code should go here
		end = my_update_cycles();


		tmp = (end - start);
		diff += tmp;
		if(tmp > max)
			max = tmp;
		if(tmp < min)
			min = tmp;
	}

	diff = diff / ROUNDS;
	//printf("#cpu_profile: calibration  average is %llu clock cycles, min is %llu, max is %llu \n", diff, min, max);
	return diff;
}

#endif
