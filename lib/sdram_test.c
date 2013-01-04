#include <common.h>

#define SDRAM_BASE_ADDR		0x80000000
#define SIZE			0x10000000
#define TRUE		0
#define FALSE		-1

unsigned int testSDRAM_32(void)
{
	unsigned int i, j;
	volatile unsigned int *addr;

	addr = (unsigned int*)SDRAM_BASE_ADDR;

	printf("\r\nWriting...\r\n");
	for ( i = 0, j = 0; i < SIZE; i += sizeof(unsigned int), j++) {
		*(addr) = (unsigned int)j;
		if(!((unsigned int)addr & 0xFFFFF)) {
			//One . for each 1MB
			printf(".");
		}
		addr++;
	}

	printf("\r\nReading...\r\n");
	addr = (unsigned int*)SDRAM_BASE_ADDR;
	for (i = 0, j = 0; i < SIZE; i += sizeof(unsigned int), j++) {
		if (*(addr) != (unsigned int)j) {
			printf("\r\n value @(0x%p) = %x value  = %x..\r\n",(addr+i),*(addr+i),j);
			return(FALSE);
		}

		if(!((unsigned int)addr & 0xFFFFF)) {
			//One . for each 1MB
			printf(".");
		}
		addr++;
	}
	printf("\r\nIteration Passed..\r\n");
	return(TRUE);
}

unsigned int testSDRAM(void)
{
	unsigned int i = 0;
	while (1) {
		printf("\r\n\nSDRAM Testing...Loop Count %d\r\n", i++);
		if(testSDRAM_32() != 0) {
			printf("Iteration %d Failed..\r\n", i);
			return -1;
		}
	}
	return 0;
}

