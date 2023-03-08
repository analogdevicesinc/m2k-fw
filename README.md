# M2k-fw
M2k Firmware for the [ADALM-2000](https://wiki.analog.com/university/tools/m2k "ADALM-2000 Wiki Page") Active Learning Module

Latest binary Release : [![GitHub Release](https://img.shields.io/github/release/analogdevicesinc/m2k-fw.svg)](https://github.com/analogdevicesinc/m2k-fw/releases/latest)  [![Github Releases](https://img.shields.io/github/downloads/analogdevicesinc/m2k-fw/total.svg)](https://github.com/analogdevicesinc/m2k-fw/releases/latest)

Firmware License : [![Many Licenses](https://img.shields.io/badge/license-LGPL2+-blue.svg)](https://github.com/analogdevicesinc/m2k-fw/blob/master/LICENSE.md)  [![Many License](https://img.shields.io/badge/license-GPL2+-blue.svg)](https://github.com/analogdevicesinc/m2k-fw/blob/master/LICENSE.md)  [![Many License](https://img.shields.io/badge/license-BSD-blue.svg)](https://github.com/analogdevicesinc/m2k-fw/blob/master/LICENSE.md)  [![Many License](https://img.shields.io/badge/license-apache-blue.svg)](https://github.com/analogdevicesinc/m2k-fw/blob/master/LICENSE.md) and many others.

* Build Instructions
```bash
 sudo apt-get install git build-essential fakeroot libncurses5-dev libssl-dev ccache
 sudo apt-get install dfu-util u-boot-tools device-tree-compiler libssl1.0-dev mtools
 sudo apt-get install bc python cpio zip unzip rsync file wget
 git clone --recursive https://github.com/analogdevicesinc/m2k-fw.git
 cd m2k-fw
 export CROSS_COMPILE=arm-linux-gnueabihf-
 export PATH=$PATH:/opt/Xilinx/Vitis/2021.2/gnu/aarch32/lin/gcc-arm-linux-gnueabi/bin
 export VIVADO_SETTINGS=/opt/Xilinx/Vivado/2021.2/settings64.sh
 make

```
 
 * Updating your local repository 
 ```bash 
      git pull --recurse-submodules
  ```
 
* Build Artifacts
 ```bash
      michael@HAL9000:~/devel/m2k-fw$ ls -AGhl build
      total 536M
      -rw-rw-r-- 1 michael   69 Mär  1 09:30 boot.bif
      -rw-rw-r-- 1 michael 443K Mär  1 09:30 boot.bin
      -rw-rw-r-- 1 michael 443K Mär  1 09:30 boot.dfu
      -rw-rw-r-- 1 michael 572K Mär  1 09:31 boot.frm
      -rw-rw-r-- 1 michael 471M Mär  1 09:31 legal-info-v0.30.tar.gz
      -rw-rw-r-- 1 michael 560K Mär  1 09:28 LICENSE.html
      -rw-rw-r-- 1 michael 9,7M Mär  1 09:30 m2k.dfu
      -rw-rw-r-- 1 michael 9,7M Mär  1 09:30 m2k.frm
      -rw-rw-r-- 1 michael   33 Mär  1 09:30 m2k.frm.md5
      -rw-rw-r-- 1 michael  19M Mär  1 09:31 m2k-fw-v0.30.zip
      -rw-rw-r-- 1 michael 9,7M Mär  1 09:30 m2k.itb
      -rw-rw-r-- 1 michael 504K Mär  1 09:31 m2k-jtag-bootstrap-v0.30.zip
      -rw-r--r-- 1 michael 897K Mär  1 09:30 mtd2.dfu
      -rw-rw-r-- 1 michael 442K Mär  1 09:29 ps7_init.c
      -rw-rw-r-- 1 michael 443K Mär  1 09:29 ps7_init_gpl.c
      -rw-rw-r-- 1 michael 4,2K Mär  1 09:29 ps7_init_gpl.h
      -rw-rw-r-- 1 michael 3,6K Mär  1 09:29 ps7_init.h
      -rw-rw-r-- 1 michael 2,4M Mär  1 09:29 ps7_init.html
      -rw-rw-r-- 1 michael  31K Mär  1 09:29 ps7_init.tcl
      -rw-r--r-- 1 michael 4,8M Mär  1 09:28 rootfs.cpio.gz
      drwxrwxr-x 6 michael 4,0K Mär  1 09:29 sdk
      -rw-rw-r-- 1 michael 949K Mär  1 09:29 system_top.bit
      -rw-rw-r-- 1 michael 645K Mär  1 09:29 system_top.xsa
      -rwxrwxr-x 1 michael 761K Mär  1 09:31 u-boot.elf
      -rw-rw---- 1 michael 128K Mär  1 09:31 uboot-env.bin
      -rw-rw---- 1 michael 129K Mär  1 09:31 uboot-env.dfu
      -rw-rw-r-- 1 michael 7,0K Mär  1 09:31 uboot-env.txt
      -rwxrwxr-x 1 michael 3,9M Mär  1 09:27 zImage
      -rw-rw-r-- 1 michael  17K Mär  1 09:28 zynq-m2k-reva.dtb
      -rw-rw-r-- 1 michael  17K Mär  1 09:29 zynq-m2k-revb.dtb
      -rw-rw-r-- 1 michael  17K Mär  1 09:29 zynq-m2k-revc.dtb
      -rw-rw-r-- 1 michael  17K Mär  1 09:29 zynq-m2k-revd.dtb
      -rw-rw-r-- 1 michael  17K Mär  1 09:29 zynq-m2k-reve.dtb
      -rw-rw-r-- 1 michael  17K Mär  1 09:29 zynq-m2k-revf.dtb
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
     | zynq-m2k-revc.dtb | Device Tree Blob for Rev.C|  

 

