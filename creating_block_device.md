This shows how to connect the hardware we found to the Linux block layer.

**Note**: `If you want to know more about the Linux block layer come to
my talk tomorrow.

## Allocating a gendisk

The main object in the Linux block layer is called struct gendisk.
We need to allocate it, set a things up and then register it.

What do we need:

 - an operations vector that the kernel uses to call into the driver
 - the name of the disk
 - the size of the disk

What we also really want:

 - let the private data in the gendisk point to our device structure

We set all this up, but stub out the I/O submission handler to always
return an error.

With this we can re-load the driver, and the /dev/nc0 device should show
up, e.g.:

	ls -l /dev/nc0
	lsblk

Note that loading the driver will show errors like:

[ 4784.867593] Buffer I/O error on dev nc0, logical block 0, async page read
[ 4784.868215] Buffer I/O error on dev nc0, logical block 0, async page read
[ 4784.868870]  nc0: unable to read partition table

because all I/O fails.

## Supporting I/O

Our I/O is really just copying memory to and from the memory on the NVMe
device, so we're basically implementing a driver for a hardware ramdisk.

For this we remove the bio_io_error() in nvme_cmb_submit_bio
and add a real handler.  This handler basically gets the address of the
ramdisk from the device structure, then uses the block layer iterator
over the bio structure that is passed to it, and then copies between
that and the ramdisk on the device.

memcpy_fromio / memcpy_toio are special version of memcpy that copy
from / to device memory (remember the __iomem annotation from earlier?)

Once you've added this function and load the module, you should not
set the errors any more.

## Creating a file system

Our ramdisk is very small, and that is too small for many modern file
systems.  But we can create an ext2 file system on it and mount it:

	mkfs.ext2 /dev/nc0
	mkdir /mnt/test
	mount /dev/nc0 /mnt/test/
	dmesg > /mnt/test/dmesg

Because the device is now used trying to remove the module will fail:

	rmmod nvme_cmb

So you first have to unmount the file system again:

	umount /mnt/test

Because the device is a ramdisk, the content of the file system will
be lost if you reboot.  It will survive removing and reloadin the
module, because it is a "hardware" ramdisk, and not just one in
the kernel, though!
