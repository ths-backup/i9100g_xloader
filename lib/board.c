/*
 * Copyright (C) 2005 Texas Instruments.
 *
 * (C) Copyright 2004
 * Jian Zhang, Texas Instruments, jzhang@ti.com.
 *
 * (C) Copyright 2002
 * Wolfgang Denk, DENX Software Engineering, wd@denx.de.
 *
 * (C) Copyright 2002
 * Sysgo Real-Time Solutions, GmbH <www.elinos.com>
 * Marius Groeger <mgroeger@sysgo.de>
 *
 * See file CREDITS for list of people who contributed to this
 * project.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston,
 * MA 02111-1307 USA
 */

#include <common.h>
#include <part.h>
#include <fat.h>
#include <asm/io.h>
#include <mmc.h>
#define WDT_WSPR 0x4A314048
#define WDT_WWPS 0x4A314034

void reset_wd()
{
	*((volatile unsigned int*)WDT_WSPR) = 0xAAAA;
	while (*((volatile unsigned int*)WDT_WWPS));
	*((volatile unsigned int*)WDT_WSPR) = 0x5555;
}

int enable_ap_uart(void)
{
	unsigned int gpio_reg;

	/* GPIO_CTRL */
	gpio_reg = __raw_readl(0x48055130);
	gpio_reg &= ~(0x1);
	__raw_writel(gpio_reg, 0x48055130);

	/* GPIO_OE */
	gpio_reg = __raw_readl(0x48055134);
	gpio_reg |= (0x1 << 15);
	__raw_writel(gpio_reg, 0x48055134);

	/* GPIO_SETDATAOUT */
	gpio_reg = __raw_readl(0x48055194);
	gpio_reg |= (0x1 << 15);
	__raw_writel(gpio_reg, 0x48055194);
}

#ifdef CFG_PRINTF
int print_info(void)
{
	printf ("\n\nTexas Instruments X-Loader 1.41 ("
		__DATE__ " - " __TIME__ ")\n");
	return 0;
}
#endif
typedef int (init_fnc_t) (void);

init_fnc_t *init_sequence[] = {
	cpu_init,		/* basic cpu dependent setup */
	board_init,		/* basic board dependent setup */
#ifdef CFG_PRINTF
 	serial_init,		/* serial communications setup */
	enable_ap_uart,
	print_info,
#endif
   	//nand_init,		/* board specific nand init */
	NULL,
};

#ifdef CFG_CMD_FAT
extern char * strcpy(char * dest,const char *src);
#else
char * strcpy(char * dest,const char *src)
{
	 char *tmp = dest;

	 while ((*dest++ = *src++) != '\0')
	         /* nothing */;
	 return tmp;
}
#endif

#ifdef CFG_CMD_MMC
extern block_dev_desc_t *mmc_get_dev(int dev);
#define SBL_START_SECTOR  0xC000
int mmc_read_bootloader(int dev)
{
	unsigned char ret = 0;
	unsigned long offset = CFG_LOADADDR;
	unsigned int start_sector = SBL_START_SECTOR;
	unsigned int magic_code = 0;

	ret = mmc_init(dev);
	if (ret != 0){
		printf("\n MMC init failed \n");
		return -1;
	}

#ifdef CFG_CMD_FAT
	long size;
	block_dev_desc_t *dev_desc = NULL;

	if (fat_boot()) {
		dev_desc = mmc_get_dev(dev);
		fat_register_device(dev_desc, 1);
		size = file_fat_read("u-boot.bin", (unsigned char *)offset, 0);
		if (size == -1)
			return -1;
	} else {
		/* FIXME: OMAP4 specific */
#if defined(OMAP4_ESPRESSO)
		ret = mmc_read(dev, start_sector,
			  (unsigned char *)CFG_LOADADDR, 0x140000);
		memcpy(&magic_code, (CFG_LOADADDR + 0x140000 - 2048), sizeof(magic_code));
		if (ret == 1 && magic_code == 0x4c424e53)
			return 0;

		printf("The magic code of SBL1 was broken, try agin with SBL2\n");
		ret = mmc_read(dev, start_sector + 0x1000,
			  (unsigned char *)CFG_LOADADDR, 0x140000);
		memcpy(&magic_code, (CFG_LOADADDR + 0x140000 - 2048), sizeof(magic_code));
		if (ret == 1 && magic_code == 0x4c424e53)
			return 0;

		printf("The magic code of SBL2 also was broken, load default SBL(SBL1)\n");
		ret = mmc_read(dev, start_sector,
			  (unsigned char *)CFG_LOADADDR, 0x140000);
#else
		ret = mmc_read(dev, start_sector,
			  (unsigned char *)CFG_LOADADDR, 0x000A0000);
#endif
	}
#endif
	return 0;
}
#endif

extern int do_load_serial_bin(ulong offset, int baudrate);

#define __raw_readl(a)	(*(volatile unsigned int *)(a))

void start_armboot (void)
{
  	init_fnc_t **init_fnc_ptr;
	uchar *buf;
	char boot_dev_name[8];
 
	reset_wd();
   	for (init_fnc_ptr = init_sequence; *init_fnc_ptr; ++init_fnc_ptr) {
		if ((*init_fnc_ptr)() != 0) {
			hang ();
		}
	}
#ifdef START_LOADB_DOWNLOAD
	strcpy(boot_dev_name, "UART");
	do_load_serial_bin (CFG_LOADADDR, 115200);
#else
	buf = (uchar *) CFG_LOADADDR;

	switch (get_boot_device()) {
	case 0x03:
		strcpy(boot_dev_name, "ONENAND");
#if defined(CFG_ONENAND)
		for (i = ONENAND_START_BLOCK; i < ONENAND_END_BLOCK; i++) {
			if (!onenand_read_block(buf, i))
				buf += ONENAND_BLOCK_SIZE;
			else
				goto error;
		}
#endif
		break;
	case 0x02:
	case 0x07:
		strcpy(boot_dev_name, "NAND");
#if defined(CFG_NAND)
		for (i = NAND_UBOOT_START; i < NAND_UBOOT_END;
				i+= NAND_BLOCK_SIZE) {
			if (!nand_read_block(buf, i))
				buf += NAND_BLOCK_SIZE; /* advance buf ptr */
		}
#endif
		break;
	case 0x05:
		strcpy(boot_dev_name, "MMC/SD1");
#if defined(CONFIG_MMC)
		if (mmc_read_bootloader(0) != 0)
			goto error;
#endif
		break;
	default:
		strcpy(boot_dev_name, "EMMC");
		printf("Uboot-loading from Emmc\n");
#if defined(CONFIG_MMC)
		if (mmc_read_bootloader(1) != 0)
			goto error;
#endif
		break;
	};
#endif
	/* go run U-Boot and never return */
	printf("Starting OS Bootloader from %s ...\n", boot_dev_name);
 	((init_fnc_t *)CFG_LOADADDR)();

	/* should never come here */
#if defined(CFG_ONENAND) || defined(CONFIG_MMC)
error:
#endif
	printf("Could not read bootloader!\n");
	hang();
}

void hang (void)
{
	/* call board specific hang function */
	board_hang();
	
	/* if board_hang() returns, hange here */
	printf("X-Loader hangs\n");
	for (;;);
}
