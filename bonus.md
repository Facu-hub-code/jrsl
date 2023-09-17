Now that we have a working driver we can still finish off the last
bit.

## Setting a device index

Remove the

	snprintf(dev->disk->disk_name, DISK_NAME_LEN, "nc0");

line?  If we had multiple devices, this would give every device
the same name.  That is a bad idea, and would make device_add_disk
fail.  What we really need to do is to replace the hard coded
0 with an index.  Linux has the "IDA" allocator, that just gives
you an index, which can be freed and reused.  We can use that
to give each device a unique name.

## Sending out the patch series

Like we sent the individual patches, you can also send a whole
series of patches (Linux likes patches split into logical chunks).

E.g. do a

	git send-email origin/master..HEAD --to hch at lst.de --compose

to fire off the editor to write and intro mail, to which the patches
are then sent as replies, and send everything to me.

I'd suggest you all send to me instead of spamming the list, and
I will send one series to the list.

## Kconfig

So far we built the nvme-cmb driver unconditionally as a module.
Linux is configurable, and we can add an entry to a Kconfig file,
in this case drivers/block/Kconfig to allow enabling and disabling
it, and build it into the kernel instead of a loadable module.
The Makefile then needs to be adapted to use the config variable
name.

If you try to build the module after the Kconfig option was
added, you will see a prompt like this:

  NVMe CMB ramdisk driver (NVME_CMB) [N/m/y/?] (NEW) 

Press the 'm' key to build it as a module.  If you typed the wrong thing,
you need to reconfigure the kernel.  You can do that by editing the
.config file, or with the menuconfig tool.

## The menuconfig tool

(this part is very optional)

For that you first need to install ncurses:

	apt-get install libncurses-dev

And then do:

	make menuconfig

This will build and start a configuration menu.

Go to

	"Device Drivers" ->
		"Block devices"

and find

	"NVMe CMB ramdisk driver"

at the very end, you can then type 'm' to build it as a module, or 'y'
to build it into the kernel, then press "Save" and write it to the
default .config file.

In case you build the driver into the kernel, you will have to rebuild
the whole kernel, install it and reboot into it to use the driver.
