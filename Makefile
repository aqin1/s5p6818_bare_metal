 #
 #	Copyright (c) 2017 Metro94
 #
 #	File:        Makefile
 #	Description: Makefile for SPL
 #	Author:      Metro94 <flattiles@gmail.com>
 #  Date:        
 #

# Makefile information

VERSION = 0.1

################################

include config.mk

################################

# project settings

target-name		=	$(BOARD)

lds-name		:=	spl

src-dir			:=	src
tools-dir		:=	tools
obj-dir			:=	src
target-dir		:=	out

obj-y			:=	start.o exceptions.o boot.o lib.o

obj-list		=	$(addprefix $(obj-dir)/, $(obj-y))

################################

# chip information

ARCH			:=	armv8-a+crc
CPU				:=	cortex-a53

# build environment
CROSS_COMPILE := aarch64-linux-gnu-

CC				=	$(CROSS_COMPILE)gcc
LD 				=	$(CROSS_COMPILE)ld
OBJCOPY			=	$(CROSS_COMPILE)objcopy

MKDIR			=	mkdir
RM			=	rm -rf

BUILD			=	tools/build
LOAD			=	tools/load

# build parameters

ASFLAGS			:=
CFLAGS			:=	-g -Wall -Wextra -ffreestanding -fno-builtin \
					-mlittle-endian -march=$(ARCH) -mtune=$(CPU)
LDFLAGS			:=	-Bstatic \
					-Wl,-Map=$(target-dir)/$(target-name).map,--cref \
					-T$(lds-name).lds \
					-Wl,--start-group \
					-Lsrc/$(obj-dir) \
					-Wl,--end-group \
					-Wl,--build-id=none \
					-nostdlib

INCLUDES		=	-I src/include

################################


.PHONY: mkdir clean

$(obj-dir)/%.o: $(src-dir)/%.c
	@echo " [CC]   $<"
	@$(CC) -MMD $< -c -o $@ $(CFLAGS) $(INCLUDES)

$(obj-dir)/%.o: $(src-dir)/%.S
	@echo " [CC]   $<"
	@$(CC) -MMD $< -c -o $@ $(ASFLAGS) $(CFLAGS) $(INCLUDES)

all: mkdir $(obj-list) link build

mkdir:
	@if	[ ! -e $(target-dir) ]; then \
		$(MKDIR) $(target-dir); \
	fi;

link: $(obj-list)
	@echo " [LD]   $(target-dir)/$(target-name).elf"
	@$(CC) $(obj-list) $(LDFLAGS) -o $(target-dir)/$(target-name).elf

build: $(target-dir)/$(target-name).elf
	@echo " [IMG]  $(target-dir)/$(target-name)_nonsih.img"
	@$(OBJCOPY) -O binary $(target-dir)/$(target-name).elf $(target-dir)/$(target-name)_nonsih.img
	@echo " [IMG]  $(target-dir)/$(target-name).img"
	@$(BUILD) $(tools-dir)/nsih64.bin $(target-dir)/$(target-name)_nonsih.img $(target-dir)/$(target-name).img

install:
	@$(LOAD) $(target-dir)/$(target-name).img

clean:
	@$(RM) $(obj-dir)/*.o $(obj-dir)/*.d
	@$(RM) $(target-dir)/*.*

version:
	@echo "SPL Builder for S5P6818, Version = $(VERSION)"
