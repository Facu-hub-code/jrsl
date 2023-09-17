
# Creating an actual hardware driver

Now that we have a stub module, let's do something useful.

You may ask why the module was called nvme_cmb?  NVMe is the short
name of a standard for SSDs, which are used in most new computers.
CMB is a feature in NVMe where the device can just expose some memory
for various uses.  We use that NVMe feature to create a simple ramdisk
driver for a NVMe device emulated by qemu.

If you are curious about NVMe, the NVMe specifications are available here:

	https://nvmexpress.org/specifications/

but we will not need any of them for this workshop.

## Creating a pci_driver

As NVMe is a PCI-Express driver, it will use the Linux PCI subsystem.
That subsystem registers a driver structure, which then gets callbacks
when devices are found, in which we for now send messages about
loading and unloading.  After that we do the usual make, insmod, rmmod
dance to show them.

 - I'll show the changes required as a diff

## PCI probe boilerplate code

There is some code that every driver needs with just a few variations,
independent of what hardware it tries to support.  We need to enable
bus mastering on the device, enable it, request the memory regions
and then undo all of that on removal.  This is totally uninteresting
but we have to do it, and will do the make, insmod, rmmod to verify
it still works.

  - I'll show the changes required as a diff

## Per-device data structure

To make sure a driver support multiple devices, device-specific data
must not be stored in global information.  Instead each device structure
(which is embedded into the pci_dev structure) has a pointer to private
data that can be used.  Just create an empty structure for now, allocate
and set it in the probe routine, and free it in the remove routine.
		    
  - I'll show the changes required as a diff

## Mapping the BAR

The BAR (Base Address Register) is what is used for all register-like
access in PCI/PCIe devices, and we need to map it using the pci_ioremap_bar
function with the right attributes (e.g. noncached) to access it.

Do that, and then use the MMIO access helper readl to read the status
register.  If it reads all-Fs that means we can't talk to the device,
in which case we give up on trying to initialize the device.

  - I'll show the changes required as a diff

