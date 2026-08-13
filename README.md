# M2k-fw
M2k Firmware for the [ADALM-2000](https://wiki.analog.com/university/tools/m2k "ADALM-2000 Wiki Page") Active Learning Module

Latest binary Release : [![GitHub Release](https://img.shields.io/github/release/analogdevicesinc/m2k-fw.svg)](https://github.com/analogdevicesinc/m2k-fw/releases/latest)  [![Github Releases](https://img.shields.io/github/downloads/analogdevicesinc/m2k-fw/total.svg)](https://github.com/analogdevicesinc/m2k-fw/releases/latest)

Firmware License : [![Many Licenses](https://img.shields.io/badge/license-LGPL2+-blue.svg)](https://github.com/analogdevicesinc/m2k-fw/blob/master/LICENSE.md)  [![Many License](https://img.shields.io/badge/license-GPL2+-blue.svg)](https://github.com/analogdevicesinc/m2k-fw/blob/master/LICENSE.md)  [![Many License](https://img.shields.io/badge/license-BSD-blue.svg)](https://github.com/analogdevicesinc/m2k-fw/blob/master/LICENSE.md)  [![Many License](https://img.shields.io/badge/license-apache-blue.svg)](https://github.com/analogdevicesinc/m2k-fw/blob/master/LICENSE.md) and many others.

* Build Instructions
```bash
 sudo apt-get install git build-essential fakeroot libncurses5-dev libssl-dev ccache
 sudo apt-get install dfu-util u-boot-tools device-tree-compiler mtools
 sudo apt-get install bc python3 cpio zip unzip rsync file wget
 git clone --recursive https://github.com/analogdevicesinc/m2k-fw.git
 cd m2k-fw
 export VIVADO_SETTINGS=/opt/Xilinx/2025.1/Vivado/settings64.sh
 make

```
Due to incompatibility between the AMD/Xilinx GCC toolchain supplied with Vivado/Vitis and Buildroot,
this project uses the Buildroot external toolchain infrastructure with the Arm GNU toolchain
(arm-none-linux-gnueabihf), which is downloaded and set up automatically during the build.

This toolchain is used to build: Buildroot, Linux and u-boot

* Repository layout

     | Submodule  | Comment |
     | ------------- | ------------- |
     | linux | ADI Linux kernel tree |
     | u-boot | ADI u-boot tree |
     | hdl | ADI HDL designs used to build the FPGA bitstream |
     | buildroot | Buildroot tree used to build the toolchain and root filesystem |
     | br2-external | Buildroot external tree with the ADI board files (board/adi/m2k) and defconfigs |

 * Updating your local repository 
 ```bash 
      git pull --recurse-submodules
  ```
 
* Build Artifacts
 ```bash
      michael@HAL9000:~/devel/m2k-fw$ ls -AGhl build
      total 872M
      -rw-rw-r-- 1 michael   69 Aug  3 13:55 boot.bif
      -rw-rw-r-- 1 michael 623K Aug  3 13:55 boot.bin
      -rw-rw-r-- 1 michael 623K Aug  3 13:55 boot.dfu
      -rw-rw-r-- 1 michael 752K Aug  3 13:55 boot.frm
      -rw-rw-r-- 1 michael 785M Aug  3 13:56 legal-info-v0.33.tar.gz
      -rw-rw-r-- 1 michael 739K Aug  3 13:45 LICENSE.html
      -rw-rw-r-- 1 michael  14M Aug  3 13:54 m2k.dfu
      -rw-rw-r-- 1 michael  14M Aug  3 13:55 m2k.frm
      -rw-rw-r-- 1 michael   33 Aug  3 13:55 m2k.frm.md5
      -rw-rw-r-- 1 michael  26M Aug  3 13:55 m2k-fw-v0.33.zip
      -rw-rw-r-- 1 michael  14M Aug  3 13:54 m2k.itb
      -rw-rw-r-- 1 michael 597K Aug  3 13:55 m2k-jtag-bootstrap-v0.33.zip
      -rw-r--r-- 1 michael 897K Aug  3 13:55 mtd2.dfu
      -rw-rw-r-- 1 michael 441K Aug  3 13:54 ps7_init.c
      -rw-rw-r-- 1 michael 442K Aug  3 13:54 ps7_init_gpl.c
      -rw-rw-r-- 1 michael 4,2K Aug  3 13:54 ps7_init_gpl.h
      -rw-rw-r-- 1 michael 3,6K Aug  3 13:54 ps7_init.h
      -rw-rw-r-- 1 michael 2,4M Aug  3 13:54 ps7_init.html
      -rw-rw-r-- 1 michael  31K Aug  3 13:54 ps7_init.tcl
      -rw-r--r-- 1 michael 7,8M Aug  3 13:45 rootfs.cpio.gz
      drwxrwxr-x 2 michael 4,0K Aug  3 13:56 sbom
      drwxrwxr-x 6 michael 4,0K Aug  3 13:54 sdk
      -rw-rw-r-- 1 michael 950K Aug  3 13:54 system_top.bit
      -rw-rw-r-- 1 michael 654K Aug  3 13:54 system_top.xsa
      -rwxrwxr-x 1 michael 600K Aug  3 13:55 u-boot.elf
      -rw-rw---- 1 michael 128K Aug  3 13:55 uboot-env.bin
      -rw-rw---- 1 michael 129K Aug  3 13:55 uboot-env.dfu
      -rw-rw-r-- 1 michael 4,0K Aug  3 13:55 uboot-env.txt
      -rwxrwxr-x 1 michael 4,5M Aug  3 13:44 zImage
      -rw-rw-r-- 1 michael  21K Aug  3 13:45 zynq-m2k-reva.dtb
      -rw-rw-r-- 1 michael  20K Aug  3 13:45 zynq-m2k-revb.dtb
      -rw-rw-r-- 1 michael  20K Aug  3 13:45 zynq-m2k-revc.dtb
      -rw-rw-r-- 1 michael  20K Aug  3 13:45 zynq-m2k-revd.dtb
      -rw-rw-r-- 1 michael  20K Aug  3 13:45 zynq-m2k-reve.dtb
      -rw-rw-r-- 1 michael  20K Aug  3 13:45 zynq-m2k-revf.dtb
 ```
 
 * Main targets
 
     | File  | Comment |
     | ------------- | ------------- | 
     | m2k.frm | Main M2k firmware file used with the USB Mass Storage Device |
     | m2k.dfu | Main M2k firmware file used in DFU mode |
     | boot.frm  | First and Second Stage Bootloader (u-boot + fsbl + uEnv) used with the USB Mass Storage Device |
     | boot.dfu  | First and Second Stage Bootloader (u-boot + fsbl) used in DFU mode |
     | uboot-env.dfu  | u-boot default environment used in DFU mode |
     | mtd2.dfu  | Calibration data partition image used in DFU mode |
     | m2k-fw-vX.XX.zip  | ZIP archive containing all of the files above |
     | m2k-jtag-bootstrap-vX.XX.zip  | ZIP archive containing u-boot and Vivado TCL used for JTAG bootstrapping |
 
  * Other intermediate targets

     | File  | Comment |
     | ------------- | ------------- |
     | boot.bif | Boot Image Format file used to generate the Boot Image |
     | boot.bin | Final Boot Image |
     | m2k.frm.md5 | md5sum of the m2k.frm file |
     | m2k.itb | u-boot Flattened Image Tree |
     | rootfs.cpio.gz | The Root Filesystem archive |
     | sbom | Software Bill of Materials (CycloneDX) for buildroot, linux, u-boot, hdl and the full firmware |
     | sdk | Vivado/Vitis Build folder including the FSBL |
     | system_top.bit | FPGA Bitstream (from XSA) |
     | system_top.xsa | FPGA Hardware Description File exported by Vivado |
     | u-boot.elf | u-boot ELF Binary |
     | uboot-env.bin | u-boot default environment in binary format created from uboot-env.txt |
     | uboot-env.txt | u-boot default environment in human readable text format |
     | zImage | Compressed Linux Kernel Image |
     | zynq-m2k-reva.dtb | Device Tree Blob for Rev.A |
     | zynq-m2k-revb.dtb | Device Tree Blob for Rev.B |
     | zynq-m2k-revc.dtb | Device Tree Blob for Rev.C |
     | zynq-m2k-revd.dtb | Device Tree Blob for Rev.D |
     | zynq-m2k-reve.dtb | Device Tree Blob for Rev.E |
     | zynq-m2k-revf.dtb | Device Tree Blob for Rev.F |

 

