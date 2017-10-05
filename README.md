# M2k-fw
M2k Firmware for the [ADALM-2000](https://wiki.analog.com/university/tools/m2k "ADALM-2000 Wiki Page") Active Learning Module

Latest binary Release : [![GitHub release](https://img.shields.io/github/release/analogdevicesinc/m2k-fw.svg)](https://github.com/analogdevicesinc/m2k-fw/releases/latest)

* Build Instructions
 ```bash
 
      git clone --recursive https://github.com/analogdevicesinc/m2k-fw.git
      cd m2k-fw
      export CROSS_COMPILE=arm-xilinx-linux-gnueabi-
      export PATH=$PATH:/opt/Xilinx/SDK/2016.2/gnu/arm/lin/bin
      export VIVADO_SETTINGS=/opt/Xilinx/Vivado/2016.2/settings64.sh
      make
 
 ```
 
 * Updating your local repository 
 ```bash 
      git pull --recurse-submodules
  ```
 
* Build Artifacts
 ```bash
      michael@HAL9000:~/devel/m2k-fw$ ls -AGhl build
	-rw-rw-r-- 1 michael   69 Sep 29 12:26 boot.bif
	-rw-rw-r-- 1 michael 446K Sep 29 12:26 boot.bin
	-rw-rw-r-- 1 michael 446K Sep 29 12:26 boot.dfu
	-rw-rw-r-- 1 michael 575K Sep 29 12:26 boot.frm
	-rw-rw-r-- 1 michael 8,6M Sep 29 12:26 m2k.dfu
	-rw-rw-r-- 1 michael 8,6M Sep 29 12:26 m2k.frm
	-rw-rw-r-- 1 michael   33 Sep 29 12:26 m2k.frm.md5
	-rw-rw-r-- 1 michael  17M Sep 29 12:26 m2k-fw-v0.16.zip
	-rw-rw-r-- 1 michael 8,6M Sep 29 12:26 m2k.itb
	-rw-rw-r-- 1 michael 509K Sep 29 12:26 m2k-jtag-bootstrap-v0.16.zip
	-rw-r--r-- 1 michael 4,3M Sep 29 12:25 rootfs.cpio.gz
	drwxrwxr-x 6 michael 4,0K Sep 29 12:25 sdk
	-rw-rw-r-- 1 michael 957K Sep 29 12:26 system_top.bit
	-rw-rw-r-- 1 michael 426K Sep 29 12:25 system_top.hdf
	-rwxrwxr-x 1 michael 409K Sep 29 12:26 u-boot.elf
	-rw-rw---- 1 michael 128K Sep 29 12:26 uboot-env.bin
	-rw-rw---- 1 michael 129K Sep 29 12:26 uboot-env.dfu
	-rw-rw-r-- 1 michael 4,6K Sep 29 12:26 uboot-env.txt
	-rwxrwxr-x 1 michael 3,3M Sep 29 12:20 zImage
	-rw-rw-r-- 1 michael  15K Sep 29 12:25 zynq-m2k-reva.dtb
	-rw-rw-r-- 1 michael  15K Sep 29 12:25 zynq-m2k-revb.dtb
 ```
 
 * Main targets
 
     | File  | Comment |
     | ------------- | ------------- | 
     | m2k.frm | Main PlutoSDR firmware file used with the USB Mass Storage Device |
     | m2k.dfu | Main PlutoSDR firmware file used in DFU mode |
     | boot.frm  | First and Second Stage Bootloader (u-boot + fsbl + uEnv) used with the USB Mass Storage Device |
     | boot.dfu  | First and Second Stage Bootloader (u-boot + fsbl) used in DFU mode |
     | uboot-env.dfu  | u-boot default environment used in DFU mode |
     | m2k-fw-vX.XX.zip  | ZIP archive containg all of the files above |
     | m2k-jtag-bootstrap-vX.XX.zip  | ZIP archive containg u-boot and Vivao TCL used for JATG bootstrapping |
 
  * Other intermediate targets

     | File  | Comment |
     | ------------- | ------------- |
     | boot.bif | Boot Image Format file used to generate the Boot Image |
     | boot.bin | Final Boot Image |
     | m2k.frm.md5 | md5sum of the m2k.frm file |
     | m2k.itb | u-boot Flattened Image Tree |
     | rootfs.cpio.gz | The Root Filesystem archive |
     | sdk | Vivado/XSDK Build folder including  the FSBL |
     | system_top.bit | FPGA Bitstream (from HDF) |
     | system_top.hdf | FPGA Hardware Description  File exported by Vivado |
     | u-boot.elf | u-boot ELF Binary |
     | uboot-env.bin | u-boot default environment in binary format created form uboot-env.txt |
     | uboot-env.txt | u-boot default environment in human readable text format |
     | zImage | Compressed Linux Kernel Image |
     | zynq-m2k-reva.dtb | Device Tree Blob for Rev.A |
     | zynq-m2k-revb.dtb | Device Tree Blob for Rev.B|     

 

