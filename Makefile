#PATH=$PATH:/opt/Xilinx/SDK/2015.4/gnu/arm/lin/bin

CROSS_COMPILE ?= arm-linux-gnueabihf-
VIVADO_SETTINGS ?= /opt/Xilinx/Vivado/2018.2/settings64.sh
XSDK_SETTINGS ?= ${VIVADO_SETTINGS}

NCORES = $(shell nproc)
LINUXDIR = linux
VSUBDIRS = hdl buildroot $(LINUXDIR) u-boot-xlnx

USBPID = 0xb675

VERSION=$(shell git describe --abbrev=4 --dirty --always --tags)
UBOOT_VERSION=$(shell echo -n "M2k " && cd u-boot-xlnx && git describe --abbrev=0 --dirty --always --tags)


ifeq (, $(shell which dfu-suffix))
$(warning "No dfu-utils in PATH consider doing: sudo apt-get install dfu-util")
TARGETS = build/m2k.frm build/boot.frm
else
TARGETS = build/m2k.dfu build/m2k.frm build/boot.dfu build/mtd2.dfu build/uboot-env.dfu build/boot.frm
endif

all: $(TARGETS) zip-all jtag-bootstrap legal-info

build:
	mkdir -p $@

%: build/%
	cp $< $@

### u-boot ###

u-boot-xlnx/u-boot u-boot-xlnx/tools/mkimage:
	make -C u-boot-xlnx ARCH=arm zynq_m2k_defconfig
	make -C u-boot-xlnx ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) UBOOTVERSION="$(UBOOT_VERSION)"

.PHONY: u-boot-xlnx/u-boot

build/u-boot.elf: u-boot-xlnx/u-boot | build
	cp $< $@

build/uboot-env.txt: u-boot-xlnx/u-boot | build
	CROSS_COMPILE=$(CROSS_COMPILE) scripts/get_default_envs.sh > $@

build/uboot-env.bin: build/uboot-env.txt
	u-boot-xlnx/tools/mkenvimage -s 0x20000 -o $@ $<

### Linux ###

$(LINUXDIR)/arch/arm/boot/zImage:
	make -C $(LINUXDIR) ARCH=arm zynq_m2k_defconfig
	make -C $(LINUXDIR) -j $(NCORES) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) zImage UIMAGE_LOADADDR=0x8000

.PHONY: $(LINUXDIR)/arch/arm/boot/zImage


build/zImage: $(LINUXDIR)/arch/arm/boot/zImage  | build
	cp $< $@

### Device Tree ###

$(LINUXDIR)/arch/arm/boot/dts/%.dtb: $(LINUXDIR)/arch/arm/boot/dts/%.dts $(LINUXDIR)/arch/arm/boot/dts/zynq-m2k.dtsi $(LINUXDIR)/arch/arm/boot/dts/zynq-7000.dtsi
	make -C $(LINUXDIR) -j $(NCORES) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) $(notdir $@)

build/%.dtb: $(LINUXDIR)/arch/arm/boot/dts/%.dtb | build
	cp $< $@

### Buildroot ###

buildroot/output/images/rootfs.cpio.gz:
	@echo device-fw $(VERSION)> $(CURDIR)/buildroot/board/m2k/VERSIONS
	@$(foreach dir,$(VSUBDIRS),echo $(dir) $(shell cd $(dir) && git describe --abbrev=4 --dirty --always --tags) >> $(CURDIR)/buildroot/board/m2k/VERSIONS;)
	make -C buildroot ARCH=arm zynq_m2k_defconfig
	make -C buildroot legal-info
	scripts/legal_info_html.sh "M2k" "$(CURDIR)/buildroot/board/m2k/VERSIONS"
	cp build/LICENSE.html buildroot/board/m2k/msd/LICENSE.html
	make -C buildroot TOOLCHAIN_EXTERNAL_INSTALL_DIR= ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) BUSYBOX_CONFIG_FILE=$(CURDIR)/buildroot/board/m2k/busybox-1.25.0.config all

.PHONY: buildroot/output/images/rootfs.cpio.gz

build/rootfs.cpio.gz: buildroot/output/images/rootfs.cpio.gz | build
	cp $< $@

build/m2k.itb: u-boot-xlnx/tools/mkimage build/zImage build/rootfs.cpio.gz build/zynq-m2k-reva.dtb build/zynq-m2k-revb.dtb build/zynq-m2k-revc.dtb build/zynq-m2k-revd.dtb build/zynq-m2k-reve.dtb build/zynq-m2k-revf.dtb build/system_top.bit
	u-boot-xlnx/tools/mkimage -f scripts/m2k.its $@

build/system_top.hdf:  | build
	bash -c "source $(VIVADO_SETTINGS) && make -C hdl m2k.standalone && cp hdl/projects/m2k/standalone/m2k.sdk/system_top.hdf $@"
	unzip -l $@ | grep -q ps7_init || cp hdl/projects/m2k/standalone/m2k.srcs/sources_1/bd/system/ip/system_sys_ps7_0/ps7_init* build/

build/sdk/fsbl/Release/fsbl.elf build/sdk/hw_0/system_top.bit : build/system_top.hdf
	bash -c "source $(XSDK_SETTINGS) && xsdk -batch -source scripts/create_fsbl_project.tcl"

build/system_top.bit: build/sdk/hw_0/system_top.bit
	cp $< $@

build/boot.bin: build/sdk/fsbl/Release/fsbl.elf build/u-boot.elf
	@echo img:{[bootloader] $^ } > build/boot.bif
	bash -c "source  $(XSDK_SETTINGS) && bootgen -image build/boot.bif -w -o $@"

### MSD update firmware file ###

build/m2k.frm: build/m2k.itb
	md5sum $< | cut -d ' ' -f 1 > $@.md5
	cat $< $@.md5 > $@

build/boot.frm: build/boot.bin build/uboot-env.bin scripts/target_mtd_info.key
	cat $^ | tee $@ | md5sum | cut -d ' ' -f1 | tee -a $@

### DFU update firmware file ###

build/%.dfu: build/%.bin
	cp $< $<.tmp
	dfu-suffix -a $<.tmp -v 0x0456 -p $(USBPID)
	mv $<.tmp $@

build/m2k.dfu: build/m2k.itb
	cp $< $<.tmp
	dfu-suffix -a $<.tmp -v 0x0456 -p $(USBPID)
	mv $<.tmp $@

build/mtd2.dfu: scripts/mtd2.img
	cp $< $<.tmp
	dfu-suffix -a $<.tmp -v 0x0456 -p $(USBPID)
	mv $<.tmp $@

clean-build:
	rm -f $(notdir $(wildcard build/*))
	rm -rf build/*

clean:
	make -C u-boot-xlnx clean
	make -C $(LINUXDIR) clean
	make -C buildroot clean
	rm -f $(notdir $(wildcard build/*))
	rm -rf build/*

zip-all: $(TARGETS)
	zip -j build/m2k-fw-$(VERSION).zip $^

dfu-m2k: build/m2k.dfu
	dfu-util -D build/m2k.dfu -a firmware.dfu
	dfu-util -e

dfu-sf-uboot: build/boot.dfu build/uboot-env.dfu
	echo "Erasing u-boot be careful - Press Return to continue... " && read key  && \
		dfu-util -D build/boot.dfu -a boot.dfu && \
		dfu-util -D build/uboot-env.dfu -a uboot-env.dfu
	dfu-util -e

dfu-all: build/m2k.dfu build/boot.dfu build/uboot-env.dfu
	echo "Erasing u-boot be careful - Press Return to continue... " && read key && \
		dfu-util -D build/m2k.dfu -a firmware.dfu && \
		dfu-util -D build/boot.dfu -a boot.dfu  && \
		dfu-util -D build/uboot-env.dfu -a uboot-env.dfu
	dfu-util -e

dfu-ram: build/m2k.dfu
	sshpass -p analog ssh root@m2k '/usr/sbin/device_reboot ram;'
	sleep 5
	dfu-util -D build/m2k.dfu -a firmware.dfu
	dfu-util -e

jtag-bootstrap: build/u-boot.elf build/sdk/hw_0/ps7_init.tcl build/sdk/hw_0/system_top.bit scripts/run.tcl
	$(CROSS_COMPILE)strip build/u-boot.elf
	zip -j build/m2k-$@-$(VERSION).zip $^

legal-info: buildroot/output/images/rootfs.cpio.gz
	tar czvf build/legal-info-$(VERSION).tar.gz -C buildroot/output legal-info

git-update-all:
	git submodule update --recursive --remote

git-pull:
	git pull --recurse-submodules
