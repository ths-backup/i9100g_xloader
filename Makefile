#
# (C) Copyright 2004-2006, Texas Instruments, <www.ti.com>
# Jian Zhang <jzhang@ti.com>
#
# (C) Copyright 2000-2004
# Wolfgang Denk, DENX Software Engineering, wd@denx.de.
#
# See file CREDITS for list of people who contributed to this
# project.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA 02111-1307 USA
#

HOSTARCH := $(shell uname -m | \
	sed -e s/i.86/i386/ \
	    -e s/sun4u/sparc64/ \
	    -e s/arm.*/arm/ \
	    -e s/sa110/arm/ \
	    -e s/powerpc/ppc/ \
	    -e s/macppc/ppc/)

HOSTOS := $(shell uname -s | tr A-Z a-z | \
	    sed -e 's/\(cygwin\).*/cygwin/')

export	HOSTARCH

# Deal with colliding definitions from tcsh etc.
VENDOR=
SEC_MODEL:=GT-I0000

#########################################################################

TOPDIR_	:= $(shell if [ "$$PWD" != "" ]; then echo $$PWD; else pwd; fi)
TOPDIR	:= $(shell echo "$(TOPDIR_)"| sed -e "s/\:/\\\:/g")
export	TOPDIR

ifeq (include/config.mk,$(wildcard include/config.mk))
# load ARCH, BOARD, and CPU configuration
include include/config.mk
export	ARCH CPU BOARD VENDOR
# load other configuration
include $(TOPDIR)/config.mk

ifndef CROSS_COMPILE
CROSS_COMPILE = arm-none-linux-gnueabi-
#CROSS_COMPILE = arm-linux-
export	CROSS_COMPILE
endif

#########################################################################
# X-LOAD objects....order is important (i.e. start must be first)

OBJS  = cpu/$(CPU)/start.o


LIBS += board/$(BOARDDIR)/lib$(BOARD).a
LIBS += cpu/$(CPU)/lib$(CPU).a
LIBS += lib/lib$(ARCH).a
LIBS += fs/fat/libfat.a
LIBS += disk/libdisk.a
LIBS += drivers/libdrivers.a
LIBS += common/libcommon.a
.PHONY : $(LIBS)

# Add GCC lib
PLATFORM_LIBS += -L $(shell dirname `$(CC) $(CFLAGS) -print-libgcc-file-name`) -lgcc

SUBDIRS	=
#########################################################################
#########################################################################

ALL = x-load.bin System.map

all:		$(ALL)

ift:	$(ALL) MLO

MLO: signGP System.map x-load.bin
	TEXT_BASE=`grep -w _start System.map|cut -d ' ' -f1`
	./signGP x-load.bin $(TEXT_BASE)
	cp x-load.bin.ift MLO

x-load.bin:	x-load
		$(OBJCOPY) ${OBJCFLAGS} -O binary $< $@

x-load:	$(OBJS) $(LIBS) $(LDSCRIPT)
		UNDEF_SYM=`$(OBJDUMP) -x $(LIBS) |sed  -n -e 's/.*\(__u_boot_cmd_.*\)/-u\1/p'|sort|uniq`;\
 		$(LD) $(LDFLAGS) $$UNDEF_SYM $(OBJS) \
			--start-group $(LIBS) --end-group $(PLATFORM_LIBS) \
			-Map x-load.map -o x-load

$(LIBS):
		$(MAKE) -C `dirname $@`

System.map:	x-load
		@$(NM) $< | \
		grep -v '\(compiled\)\|\(\.o$$\)\|\( [aUw] \)\|\(\.\.ng$$\)\|\(LASH[RL]DI\)' | \
		sort > System.map

oneboot:	x-load.bin
		scripts/mkoneboot.sh

signGP:		scripts/signGP.c
		gcc -O3 -o signGP  $<

#########################################################################
else
all install x-load x-load.srec oneboot depend dep:
	@echo "System not configured - see README" >&2
	@ exit 1
endif

#########################################################################

unconfig:
	rm -f include/config.h include/config.mk

#========================================================================
# ARM
#========================================================================
#########################################################################
## OMAP1 (ARM92xT) Systems
#########################################################################

omap1710h3_config :    unconfig
	@./mkconfig $(@:_config=) arm arm926ejs omap1710h3

#########################################################################
## OMAP2 (ARM1136) Systems
#########################################################################

omap2420h4_config :    unconfig
	@./mkconfig $(@:_config=) arm arm1136 omap2420h4

omap2430sdp_config :    unconfig
	@./mkconfig $(@:_config=) arm arm1136 omap2430sdp

#########################################################################
## OMAP3 (ARM-CortexA8) Systems
#########################################################################
omap3430sdp_config :    unconfig
	@./mkconfig $(@:_config=) arm omap3 omap3430sdp

omap4430sdp_MPU_600MHz_config \
omap4430sdp_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 omap4430sdp
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/omap4430sdp.h>" >>./include/config.h
	@[ -n "$(findstring _MPU_600MHz,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
		}
	@[ -z "$(findstring _MPU_600MHz,$@)" ] || \
		{ echo "#define CONFIG_MPU_600 1"	>>./include/config.h ; \
		  echo "MPU at 600MHz revision.." ; \
		}

android_t1_omap4430_r00_eng_config :        unconfig
	@./mkconfig $(@:_config=) arm omap4 omap4430sdp
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/android_t1_omap4430_r00.h>" >>./include/config.h
	echo "#define CONFIG_MPU_1000 1"      >>./include/config.h ; \
        echo "MPU at 1GHz revision.." ;

android_t1_omap4430_r00_user_config :        unconfig
	@./mkconfig $(@:_config=) arm omap4 omap4430sdp
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/android_t1_omap4430_r00.h>" >>./include/config.h
	echo "#define CONFIG_MPU_1000 1"      >>./include/config.h ; \
        echo "MPU at 1GHz revision.." ;

android_t1_omap4430_r01_eng_config :
	@./mkconfig $(@:_config=) arm omap4 omap4430sdp
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/android_t1_omap4430_r01.h>" >>./include/config.h
	echo "#define CONFIG_MPU_1000 1"      >>./include/config.h ; \
        echo "MPU at 1GHz revision.." ;

android_t1_omap4430_r01_user_config :
	@./mkconfig $(@:_config=) arm omap4 omap4430sdp
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/android_t1_omap4430_r01.h>" >>./include/config.h
	echo "#define CONFIG_MPU_1000 1"      >>./include/config.h ; \
        echo "MPU at 1GHz revision.." ;

android_t1_omap4430_r02_eng_config :
	@./mkconfig $(@:_config=) arm omap4 omap4430sdp
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/android_t1_omap4430_r02.h>" >>./include/config.h
	echo "#define CONFIG_MPU_1000 1"      >>./include/config.h ; \
        echo "MPU at 1GHz revision.." ;

android_t1_omap4430_r02_user_config :
	@./mkconfig $(@:_config=) arm omap4 omap4430sdp
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/android_t1_omap4430_r02.h>" >>./include/config.h
	echo "#define CONFIG_MPU_1000 1"      >>./include/config.h ; \
        echo "MPU at 1GHz revision.." ;

android_t1_omap4430_r03_eng_config :
	@./mkconfig $(@:_config=) arm omap4 omap4430sdp
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/android_t1_omap4430_r03.h>" >>./include/config.h
	echo "#define CONFIG_MPU_1000 1"      >>./include/config.h ; \
        echo "MPU at 1GHz revision.." ;

android_t1_omap4430_r03_user_config :
	@./mkconfig $(@:_config=) arm omap4 omap4430sdp
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/android_t1_omap4430_r03.h>" >>./include/config.h
	echo "#define CONFIG_MPU_1000 1"      >>./include/config.h ; \
        echo "MPU at 1GHz revision.." ;

android_t1_omap4430_r07_eng_config :
	@./mkconfig $(@:_config=) arm omap4 omap4430sdp
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/android_t1_omap4430_r03.h>" >>./include/config.h
	echo "#define CONFIG_MPU_1000 1"      >>./include/config.h ; \
        echo "MPU at 1GHz revision.." ;

android_t1_omap4430_r07_user_config :
	@./mkconfig $(@:_config=) arm omap4 omap4430sdp
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/android_t1_omap4430_r03.h>" >>./include/config.h
	echo "#define CONFIG_MPU_1000 1"      >>./include/config.h ; \
        echo "MPU at 1GHz revision.." ;

## GT-P3100 : ESPRESSO 3G EUR OPEN
## GT-P3110 : ESPRESSO WIFI EUR OPEN
## GT-P3113 : ESPRESSO WIFI USA BBY
## GT_P5100 : ESPRESSO 10" 3G
## GT-P5110 : ESPRESSO 10" WIFI
## GT-P5113 : ESPRESSO WIFI USA
GT-P5100_ALL_WW_00_eng_config \
GT-P5100_ALL_WW_00_user_config \
GT-P5100_ALL_WW_01_eng_config \
GT-P5100_ALL_WW_01_user_config \
GT-P5100_ALL_WW_02_eng_config \
GT-P5100_ALL_WW_02_user_config \
GT-P5110_ALL_WW_00_eng_config \
GT-P5110_ALL_WW_00_user_config \
GT-P5110_ALL_WW_01_eng_config \
GT-P5110_ALL_WW_01_user_config \
GT-P5110_ALL_WW_02_eng_config \
GT-P5110_ALL_WW_02_user_config \
GT-P5113_NA_XAR_00_eng_config \
GT-P5113_NA_XAR_00_user_config \
GT-P5113_NA_XAR_01_eng_config \
GT-P5113_NA_XAR_01_user_config \
GT-P5113_NA_XAR_02_eng_config \
GT-P5113_NA_XAR_02_user_config \
GT-P5100_CHN_CHN_1G_00_eng_config \
GT-P5100_CHN_CHN_1G_00_user_config \
GT-P5100_CHN_CHN_1G_01_eng_config \
GT-P5100_CHN_CHN_1G_01_user_config \
GT-P5100_CHN_CHN_1G_02_eng_config \
GT-P5100_CHN_CHN_1G_02_user_config \
GT-P5110_CHN_CHN_1G_00_eng_config \
GT-P5110_CHN_CHN_1G_00_user_config \
GT-P5110_CHN_CHN_1G_01_eng_config \
GT-P5110_CHN_CHN_1G_01_user_config \
GT-P5110_CHN_CHN_1G_02_eng_config \
GT-P5110_CHN_CHN_1G_02_user_config \
GT-P3100_EUR_XX_00_eng_config \
GT-P3100_EUR_XX_00_user_config \
GT-P3100_EUR_XX_04_eng_config \
GT-P3100_EUR_XX_04_user_config \
GT-P3100_EUR_XX_05_eng_config \
GT-P3100_EUR_XX_05_user_config \
GT-P3110_EUR_XX_00_eng_config \
GT-P3110_EUR_XX_00_user_config \
GT-P3110_EUR_XX_04_eng_config \
GT-P3110_EUR_XX_04_user_config \
GT-P3110_EUR_XX_05_eng_config \
GT-P3110_EUR_XX_05_user_config \
GT-P3108_CHN_ZM_1G_00_eng_config \
GT-P3108_CHN_ZM_1G_00_user_config \
GT-P3108_CHN_ZM_1G_04_eng_config \
GT-P3108_CHN_ZM_1G_04_user_config \
GT-P3108_CHN_ZM_1G_05_eng_config \
GT-P3108_CHN_ZM_1G_05_user_config \
GT-P3100_CHN_CHN_1G_00_eng_config \
GT-P3100_CHN_CHN_1G_00_user_config \
GT-P3100_CHN_CHN_1G_04_eng_config \
GT-P3100_CHN_CHN_1G_04_user_config \
GT-P3100_CHN_CHN_1G_05_eng_config \
GT-P3100_CHN_CHN_1G_05_user_config \
GT-P3100_CHN_ZH_1G_00_eng_config \
GT-P3100_CHN_ZH_1G_00_user_config \
GT-P3100_CHN_ZH_1G_04_eng_config \
GT-P3100_CHN_ZH_1G_04_user_config \
GT-P3100_CHN_ZH_1G_05_eng_config \
GT-P3100_CHN_ZH_1G_05_user_config \
GT-P3110_CHN_CHN_1G_00_eng_config \
GT-P3110_CHN_CHN_1G_00_user_config \
GT-P3110_CHN_CHN_1G_04_eng_config \
GT-P3110_CHN_CHN_1G_04_user_config \
GT-P3110_CHN_CHN_1G_05_eng_config \
GT-P3110_CHN_CHN_1G_05_user_config \
GT-P3110_HKTW_WW_1G_00_eng_config \
GT-P3110_HKTW_WW_1G_00_user_config \
GT-P3110_HKTW_WW_1G_04_eng_config \
GT-P3110_HKTW_WW_1G_04_user_config \
GT-P3110_HKTW_WW_1G_05_eng_config \
GT-P3110_HKTW_WW_1G_05_user_config \
GT-P3113_NA_XAR_00_eng_config \
GT-P3113_NA_XAR_00_user_config \
GT-P3113_NA_XAR_04_eng_config \
GT-P3113_NA_XAR_04_user_config \
GT-P3113_NA_XAR_05_eng_config \
GT-P3113_NA_XAR_05_user_config :		unconfig
	@./mkconfig $(@:_config=) arm omap4 omap4430sdp
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/android_espresso_omap4430_r00.h>" >>./include/config.h
	echo "#define CONFIG_MPU_1000 1"      >>./include/config.h ; \
        echo "MPU at 1GHz revision.." ;

omap4430panda_MPU_600MHz_config \
omap4430panda_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 omap4430panda
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/omap4430panda.h>" >>./include/config.h
	@[ -n "$(findstring _MPU_600MHz,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
		}
	@[ -z "$(findstring _MPU_600MHz,$@)" ] || \
		{ echo "#define CONFIG_MPU_600 1"	>>./include/config.h ; \
		  echo "MPU at 600MHz revision.." ; \
		}

omap3430labrador_config :    unconfig
	@./mkconfig $(@:_config=) arm omap3 omap3430labrador

omap3430labradordownload_config :    unconfig
	@./mkconfig omap3430labrador arm omap3 omap3430labrador; \
	echo "#define START_LOADB_DOWNLOAD" >> ./include/config-2.h; \
	cat ./include/config.h >> ./include/config-2.h; \
	mv ./include/config-2.h ./include/config.h

omap3430zoom2_config :    unconfig
	@./mkconfig $(@:_config=) arm omap3 omap3430labrador

omap3430zoom2_512m_config :    unconfig
	@./mkconfig $(@:_config=) arm omap3 omap3430labrador
	sed -e ' s/CONFIG_3430ZOOM2/CONFIG_3430ZOOM2_512M/ ' < \
	  ./include/configs/omap3430zoom2.h  | \
	sed -e ' s/#define CFG_NAND 1/#undef CFG_NAND/ ' \
	>> ./include/config-2.h; \
	mv ./include/config-2.h ./include/config.h

#########################################################################

clean:
	find . -type f \
		\( -name 'core' -o -name '*.bak' -o -name '*~' \
		-o -name '*.o'  -o -name '*.a'  \) -print \
		| xargs rm -f

clobber:	clean
	find . -type f \
		\( -name .depend -o -name '*.srec' -o -name '*.bin' \) \
		-print \
		| xargs rm -f
	rm -f $(OBJS) *.bak tags TAGS
	rm -fr *.*~
	rm -f x-load x-load.map $(ALL) x-load.bin.ift signGP MLO MLO.hs signed_ift_x-load.bin
	rm -f include/asm/proc include/asm/arch

mrproper \
distclean:	clobber unconfig

backup:
	F=`basename $(TOPDIR)` ; cd .. ; \
	gtar --force-local -zcvf `date "+$$F-%Y-%m-%d-%T.tar.gz"` $$F

#########################################################################
