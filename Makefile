
VIVADO_VERSION ?= 2025.2

BR2_EXT_DIR = $(CURDIR)/br2-external
BUILDROOT_DIR = $(CURDIR)/buildroot

# Cross-compiler provided by buildroot toolchain
CROSS_COMPILE = arm-none-linux-gnueabihf-
TOOLS_PATH = PATH="$(BUILDROOT_DIR)/output/host/bin:$(BUILDROOT_DIR)/output/host/sbin:$(PATH)"
TOOLCHAIN = $(BUILDROOT_DIR)/output/host/bin/$(CROSS_COMPILE)gcc

NCORES = $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
VIVADO_SETTINGS ?= /opt/Xilinx/$(VIVADO_VERSION)/Vivado/settings64.sh

VSUBDIRS = hdl br2-external linux u-boot

VERSION:=$(shell git describe --abbrev=4 --dirty --always --tags)
LATEST_TAG:=$(shell git describe --abbrev=0 --tags)
UBOOT_VERSION=$(shell echo -n "M2k " && cd u-boot && git describe --abbrev=0 --dirty --always --tags)
HAVE_VIVADO= $(shell bash -c "source $(VIVADO_SETTINGS) > /dev/null 2>&1 && vivado -version > /dev/null 2>&1 && echo 1 || echo 0")
XSA_URL ?= http://github.com/analogdevicesinc/m2k-fw/releases/download/${LATEST_TAG}/system_top.xsa

ifeq (1, ${HAVE_VIVADO})
	VIVADO_INSTALL= $(shell bash -c "source $(VIVADO_SETTINGS) > /dev/null 2>&1 && vivado -version | head -1 | awk '{print $$2}'")
	ifeq (, $(findstring $(VIVADO_VERSION), $(VIVADO_INSTALL)))
$(warning *** This repository has only been tested with $(VIVADO_VERSION),)
$(warning *** and you have $(VIVADO_INSTALL))
$(warning *** Please 1] set the path to Vivado $(VIVADO_VERSION) OR)
$(warning ***        2] remove $(VIVADO_INSTALL) from the path OR)
$(error "      3] export VIVADO_VERSION=v20xx.x")
	endif
endif

TARGET ?= m2k
SUPPORTED_TARGETS:=m2k

# Include target specific constants
-include scripts/$(TARGET).mk

ifeq (, $(shell which dfu-suffix))
$(warning "No dfu-utils in PATH consider doing: sudo apt-get install dfu-util")
TARGETS = build/$(TARGET).frm
ifeq (1, ${HAVE_VIVADO})
TARGETS += build/boot.frm jtag-bootstrap
endif
else
TARGETS = build/$(TARGET).dfu build/uboot-env.dfu build/$(TARGET).frm build/mtd2.dfu
ifeq (1, ${HAVE_VIVADO})
TARGETS += build/boot.dfu build/boot.frm jtag-bootstrap
endif
endif

ifeq ($(findstring $(TARGET),$(SUPPORTED_TARGETS)),)
all:
	@echo "Invalid TARGET variable ; valid values are: $(SUPPORTED_TARGETS)" && exit 1
else
all: clean-build $(TARGETS) zip-all legal-info
endif

.NOTPARALLEL: all

.PHONY: all clean clean-build zip-all legal-info sysroot jtag-bootstrap
.PHONY: dfu-$(TARGET) dfu-sf-uboot dfu-all dfu-ram uboot-test-ram
.PHONY: git-update-all git-pull

TARGET_DTS_FILES:=$(foreach dts,$(TARGET_DTS_FILES),build/$(dts))

TOOLCHAIN:
	$(MAKE) -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(BR2_EXT_DIR) ARCH=arm zynq_$(TARGET)_defconfig
	$(MAKE) -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(BR2_EXT_DIR) toolchain

build:
	mkdir -p $@

%: build/%
	cp $< $@


### u-boot ###

u-boot/u-boot u-boot/tools/mkimage: TOOLCHAIN
	$(TOOLS_PATH) $(MAKE) -C u-boot ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) zynq_$(TARGET)_defconfig
	$(TOOLS_PATH) $(MAKE) -C u-boot -j $(NCORES) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE)

.PHONY: u-boot/u-boot

build/u-boot.elf: u-boot/u-boot | build
	cp $< $@

build/uboot-env.txt: u-boot/u-boot TOOLCHAIN | build
	$(TOOLS_PATH) $(MAKE) -C u-boot ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) u-boot-initial-env
	cp u-boot/u-boot-initial-env $@

build/uboot-env.bin: build/uboot-env.txt
	u-boot/tools/mkenvimage -s 0x20000 -o $@ $<

### Linux ###

linux/arch/arm/boot/zImage: TOOLCHAIN
	$(TOOLS_PATH) $(MAKE) -C linux ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) zynq_$(TARGET)_defconfig
	$(TOOLS_PATH) $(MAKE) -C linux -j $(NCORES) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) zImage UIMAGE_LOADADDR=0x8000


.PHONY: linux/arch/arm/boot/zImage


build/zImage: linux/arch/arm/boot/zImage | build
	cp $< $@

### Device Tree ###

linux/arch/arm/boot/dts/xilinx/%.dtb: TOOLCHAIN linux/arch/arm/boot/dts/xilinx/%.dts linux/arch/arm/boot/dts/xilinx/zynq-m2k.dtsi
	$(TOOLS_PATH) DTC_FLAGS=-@ $(MAKE) -C linux -j $(NCORES) ARCH=arm CROSS_COMPILE=$(CROSS_COMPILE) xilinx/$(notdir $@)

build/%.dtb: linux/arch/arm/boot/dts/xilinx/%.dtb | build
	dtc -q -@ -I dtb -O dts $< | sed 's/axi {/amba {/g' | dtc -q -@ -I dts -O dtb -o $@

### Buildroot ###

$(BUILDROOT_DIR)/output/images/rootfs.cpio.gz:
	@echo device-fw $(VERSION)> $(BR2_EXT_DIR)/board/adi/$(TARGET)/VERSIONS
	@$(foreach dir,$(VSUBDIRS),echo $(dir) $(shell cd $(dir) && git describe --abbrev=4 --dirty --always --tags) >> $(BR2_EXT_DIR)/board/adi/$(TARGET)/VERSIONS;)
	@echo buildroot $(shell cd $(BUILDROOT_DIR) && git describe --abbrev=4 --dirty --always --tags 2>/dev/null || echo unknown) >> $(BR2_EXT_DIR)/board/adi/$(TARGET)/VERSIONS
	$(MAKE) -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(BR2_EXT_DIR) ARCH=arm zynq_$(TARGET)_defconfig

ifneq (1, ${SKIP_LEGAL})
	$(MAKE) -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(BR2_EXT_DIR) legal-info
	scripts/legal_info_html.sh "$(COMPLETE_NAME)" "$(BR2_EXT_DIR)/board/adi/$(TARGET)/VERSIONS" "$(BUILDROOT_DIR)/output/legal-info/manifest.csv"
	cp build/LICENSE.html $(BR2_EXT_DIR)/board/adi/$(TARGET)/msd/LICENSE.html
endif

	$(MAKE) -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(BR2_EXT_DIR) BUSYBOX_CONFIG_FILE=$(BR2_EXT_DIR)/board/adi/$(TARGET)/busybox-1.25.0.config all

.PHONY: $(BUILDROOT_DIR)/output/images/rootfs.cpio.gz

build/rootfs.cpio.gz: $(BUILDROOT_DIR)/output/images/rootfs.cpio.gz | build
	cp $< $@

build/$(TARGET).itb: u-boot/tools/mkimage build/zImage build/rootfs.cpio.gz $(TARGET_DTS_FILES) build/system_top.bit
	u-boot/tools/mkimage -f scripts/$(TARGET).its $@

build/system_top.xsa:  | build
ifeq (1, ${HAVE_VIVADO})
	bash -c "source $(VIVADO_SETTINGS) && $(MAKE) -C hdl/projects/$(TARGET) && cp hdl/projects/$(TARGET)/$(TARGET).sdk/system_top.xsa $@"
	unzip -l $@ | grep -q ps7_init || cp hdl/projects/$(TARGET)/$(TARGET).srcs/sources_1/bd/system/ip/system_sys_ps7_0/ps7_init* build/
else ifneq ($(XSA_FILE),)
	cp $(XSA_FILE) $@
else ifneq ($(XSA_URL),)
	wget -T 3 -t 1 -N --directory-prefix build $(XSA_URL)
endif

### TODO: Build system_top.xsa from src if dl fails ...

build/sdk/fsbl/Release/fsbl.elf build/system_top.bit : build/system_top.xsa
	rm -Rf build/sdk
ifeq (1, ${HAVE_VIVADO})
	bash -c "source $(VIVADO_SETTINGS) && xsct scripts/create_fsbl_project.tcl"
else
	unzip -o build/system_top.xsa system_top.bit -d build
endif

build/boot.bin: build/sdk/fsbl/Release/fsbl.elf build/u-boot.elf
	@echo img:{[bootloader] $^ } > build/boot.bif
	bash -c "source $(VIVADO_SETTINGS) && bootgen -image build/boot.bif -w -o $@"

### MSD update firmware file ###

build/$(TARGET).frm: build/$(TARGET).itb
	md5sum $< | cut -d ' ' -f 1 > $@.md5
	cat $< $@.md5 > $@

build/boot.frm: build/boot.bin build/uboot-env.bin scripts/target_mtd_info.key
	cat $^ | tee $@ | md5sum | cut -d ' ' -f1 | tee -a $@

### DFU update firmware file ###

define dfu-suffix-recipe
	cp $< $<.tmp
	dfu-suffix -a $<.tmp -v $(DEVICE_VID) -p $(DEVICE_PID)
	mv $<.tmp $@
endef

build/%.dfu: build/%.bin
	$(dfu-suffix-recipe)

build/$(TARGET).dfu: build/$(TARGET).itb
	$(dfu-suffix-recipe)

build/mtd2.dfu: scripts/mtd2.img
	$(dfu-suffix-recipe)

clean-build:
	rm -rf build/*

clean:
	$(MAKE) -C u-boot clean
	$(MAKE) -C linux clean
	test -d $(BUILDROOT_DIR) && $(MAKE) -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(BR2_EXT_DIR) clean || true
	$(MAKE) -C hdl clean
	rm -rf build/*

zip-all: $(TARGETS)
	zip -j build/$(ZIP_ARCHIVE_PREFIX)-fw-$(VERSION).zip $^

dfu-$(TARGET): build/$(TARGET).dfu
	dfu-util -D build/$(TARGET).dfu -a firmware.dfu
	dfu-util -e

dfu-sf-uboot: build/boot.dfu build/uboot-env.dfu
	echo "Erasing u-boot be careful - Press Return to continue... " && read key  && \
		dfu-util -D build/boot.dfu -a boot.dfu && \
		dfu-util -D build/uboot-env.dfu -a uboot-env.dfu
	dfu-util -e

dfu-all: build/$(TARGET).dfu build/boot.dfu build/uboot-env.dfu
	echo "Erasing u-boot be careful - Press Return to continue... " && read key && \
		dfu-util -D build/$(TARGET).dfu -a firmware.dfu && \
		dfu-util -D build/boot.dfu -a boot.dfu  && \
		dfu-util -D build/uboot-env.dfu -a uboot-env.dfu
	dfu-util -e

dfu-ram: build/$(TARGET).dfu
	sshpass -p analog ssh root@$(TARGET) '/usr/sbin/device_reboot ram;'
	sleep 7
	dfu-util -D build/$(TARGET).dfu -a firmware.dfu
	dfu-util -e

uboot-test-ram: u-boot/u-boot
	@echo "Rebooting $(TARGET) into DFU RAM mode..."
	sshpass -p analog ssh root@$(TARGET) '/usr/sbin/device_reboot ram;'
	sleep 7
	@echo "Uploading new u-boot to RAM via DFU..."
	dfu-util -D u-boot/u-boot.bin -a firmware.dfu
	@echo ""
	@echo "u-boot.bin uploaded to RAM. Connect to serial console and run:"
	@echo "  go 0x4000000"
	@echo ""
	@echo "Or if that fails, re-upload as ELF:"
	@echo "  setenv dfu_alt_info \"u-boot.elf ram 0x1000000 0x200000\""
	@echo "  dfu 0 ram 0"
	@echo "  (then: dfu-util -D u-boot/u-boot -a u-boot.elf)"
	@echo "  bootelf 0x1000000"

jtag-bootstrap: build/u-boot.elf build/ps7_init.tcl build/system_top.bit scripts/run.tcl scripts/run-xsdb.tcl
	$(TOOLS_PATH) $(CROSS_COMPILE)strip build/u-boot.elf
	zip -j build/$(ZIP_ARCHIVE_PREFIX)-$@-$(VERSION).zip $^

sysroot: $(BUILDROOT_DIR)/output/images/rootfs.cpio.gz
	tar czfh build/sysroot-$(VERSION).tar.gz --hard-dereference --exclude=usr/share/man --exclude=dev --exclude=etc -C $(BUILDROOT_DIR)/output staging

LINUX_VERSION = $(shell cd linux && git describe --abbrev=4 --dirty --always --tags)
LINUX_URL = https://github.com/analogdevicesinc/linux.git
UBOOT_VER = $(shell cd u-boot && git describe --abbrev=4 --dirty --always --tags)
UBOOT_URL = https://github.com/analogdevicesinc/u-boot.git
HDL_VERSION = $(shell cd hdl && git describe --abbrev=4 --dirty --always --tags)
HDL_URL = https://github.com/analogdevicesinc/hdl

PKG_LINUX = linux,$(LINUX_VERSION),GPL-2.0-only,$(LINUX_URL)
PKG_UBOOT = u-boot,$(UBOOT_VER),GPL-2.0-or-later,$(UBOOT_URL)
PKG_HDL = hdl,$(HDL_VERSION),NOASSERTION,$(HDL_URL)

EXTRA_PKGS = \
	--extra-pkg $(PKG_LINUX) \
	--extra-pkg $(PKG_UBOOT) \
	--extra-pkg $(PKG_HDL)

SBOM_DIR = build/sbom

legal-info: $(BUILDROOT_DIR)/output/images/rootfs.cpio.gz
ifneq (1, ${SKIP_LEGAL})
	tar czvf build/legal-info-$(VERSION).tar.gz -C $(BUILDROOT_DIR)/output legal-info
	mkdir -p $(SBOM_DIR)
	$(MAKE) --no-print-directory -C $(BUILDROOT_DIR) BR2_EXTERNAL=$(BR2_EXT_DIR) show-info > $(SBOM_DIR)/show-info.json
	@echo "=== Generating individual SBOMs ==="
	# Buildroot SBOM (CycloneDX via native tool)
	$(BUILDROOT_DIR)/utils/generate-cyclonedx \
		-i $(SBOM_DIR)/show-info.json \
		--project-name buildroot \
		--project-version $(VERSION) \
		-o $(SBOM_DIR)/buildroot-$(VERSION).cdx.json
	# Linux SBOM
	python3 scripts/merge_cyclonedx.py \
		--project-name linux --project-version $(LINUX_VERSION) \
		--extra-pkg $(PKG_LINUX) \
		-o $(SBOM_DIR)/linux-$(LINUX_VERSION).cdx.json
	# U-Boot SBOM
	python3 scripts/merge_cyclonedx.py \
		--project-name u-boot --project-version $(UBOOT_VER) \
		--extra-pkg $(PKG_UBOOT) \
		-o $(SBOM_DIR)/u-boot-$(UBOOT_VER).cdx.json
	# HDL SBOM
	python3 scripts/merge_cyclonedx.py \
		--project-name hdl --project-version $(HDL_VERSION) \
		--extra-pkg $(PKG_HDL) \
		-o $(SBOM_DIR)/hdl-$(HDL_VERSION).cdx.json
	@echo "=== Generating full firmware SBOM ==="
	# Full firmware SBOM (buildroot packages + linux + u-boot + hdl)
	python3 scripts/merge_cyclonedx.py \
		-i $(SBOM_DIR)/buildroot-$(VERSION).cdx.json \
		--project-name $(TARGET) --project-version $(VERSION) \
		$(EXTRA_PKGS) \
		-o $(SBOM_DIR)/$(TARGET)-$(VERSION).cdx.json
endif


git-update-all:
	git submodule update --recursive --remote

git-pull:
	git pull --recurse-submodules
