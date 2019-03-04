# AMD Radeon ACPI Enduro patch

[![MSI GT60 WITH AMD 7970m](http://img.youtube.com/vi/yZrYYQ5fnms/0.jpg)](http://www.youtube.com/watch?v=yZrYYQ5fnms)

## Source 
The instructions and the ACPI code for Linux have been written with the help of the Linux kernel source code:
- [The ACPI initrd table override documentation;](https://elixir.free-electrons.com/linux/v4.14/source/Documentation/acpi/initrd_table_override.txt)
- [The radeon module ACPI headers.](https://elixir.free-electrons.com/linux/v4.14/source/drivers/gpu/drm/radeon/radeon_acpi.h)

The instructions for Microsoft Windows have been written with the help of Microsoft documentation:
- [Microsoft ASL compiler.](https://docs.microsoft.com/en-us/windows-hardware/drivers/bringup/microsoft-asl-compiler)

## System status
It has been tested with my MSI GT60 (Intel 4710MQ) and Radeon 7970m:
- Ubuntu 17.10 (radeon module): Working;
- Ubuntu 17.10 (amdgpu module): Crashing if dynamic power switching is enabled ([Phoronix](https://www.phoronix.com/scan.php?page=news_item&px=AMDKFD-dGPU-Initialization): amdgpu module seems to lack initialisation patches);
- Windows 7 (Radeon software 17.4): Working;
- Windows 10 (Radeon software 17.12): Crashing if dynamic power switching is enabled.

## Caution!
**_The temperature support for FANs is not implemented!!!
I do not take any responsability if your OS becomes unbootable or if your hardware breaks!!!_**

## How it works?
First of all, all AMD Radeon GPU drivers need to be initialised with the graphic card VGA bios.
There is two way to get this firmware code:
- From the pci subsystem (It seems deprecated on new laptops that have UEFI);
- From the ATRM ACPI function.

For the dynamic switching part the driver needs the ATPX ACPI function to be implemented.

This patch implements these two ACPI functions.

## How to compile 
### On Linux
First, install the iasl package and get a copy of your VGA bios (with ATIFLASH for example).
Get an VGA Bios ASL hexadecimal representation with the python tool provided.
```
python3 BiosExtract.py vgabios.bin
```
Replace the VGA bios size in the SROM (SIZE ROM) field (in the RADC.dsl file) with the one provided by the tool.
Copy the vgabios.hex content in the CROM (CONTENT ROM) braces.
Compile the ASL code with the following command:
```
iasl RADC.asl
```
We will now create the cpio archive that contains the ACPI code;
```
mkdir -p kernel/firmware/acpi
cp RADC.aml kernel/firmware/acpi/
find kernel | cpio -H newc --create > acpi_initrd
```
Finally concatenate the acpi_initrd file with your current initrd and move it in your boot folder.
```
sudo bash -c "cat /boot/initrd >> acpi_initrd"
sudo mv acpi_initrd /boot/
```
Reboot your computer and load the new initrd in GRUB.

### On Windows
First, install the Windows Driver Kit and a software to extract the ACPI tables (example: RWEverything).
Extract the SSDT5 table and decompile it with the asl tool.
```
asl /u SSDT5.aml
```
Add the "External" fields from the RADC.asl file in the SSDT5.asl file.
Copy the code from the "Scope()" braces in the "Device (GFX0)" braces.
Compile the ASL code with asl and correct minor errors.
```
asl SSDT5.asl
```
Load the new ACPI table.
```
asl /loadtable SSDT5.aml
```
Enable testsigning and reboot.
```
bcdedit -set TESTSIGNING ON
```

**If you have a BSOD (Blue Screen Of Death)**
- Reboot into the repair mode and open a command prompt;
- Execute regedit and load your computer registry (C:\Windows\System32\config\SYSTEM);
- Remove the folder \ControlSet001\Services\ACPI\Parameters\SSDT;
- Reboot.

**If you want to unload the SSDT5.aml do:**
```
asl /loadtable -d SSDT5.aml
```

## How to adapt this method to another laptop?
The best way to enable power switching for another laptop is to have a Linux running on it to identify ACPI functions needed to power on and off the card. I recommend you to have first installed acpi_call to test the turn_off_gpu.sh script that identify the powering ACPI methods. Then you will have to find the integrated GPU ACPI reference with the help of lspci and the files available at /sys/bus/acpi/devices. When you have the integrated GPU reference, replace the scope in the RADC.asl file and edit the power methods in "External" fields and in the ATPX function. Then you are good to compile the code and put it in your initrd.
