
## Pre-Workshop setup for the JRSL Linux Kernel workshop

# Preparation steps on the host system

Make sure qemu is install on the host system (i.e. the laptop / desktop).

For Debian this is done by:

	sudo apt-get install qemu-system-x86

Created a directory for all the files related to this workshop.  E.g.

	mkdir jrsl
	cd jrsl

This directory will need enough space for the 8 Gigabytes image and some
smaller files.

The download the VM image we are going to use.  This is a semi-official
Debian cloud image, that comes with a pre-installed Debian 12 with current
security updates.

	wget https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-nocloud-amd64.qcow2

Resize the image to have enough space for a kernel build:

	qemu-img resize debian-12-nocloud-amd64.qcow2 8G


# Preparation setps in the VM

Start the VM using the provided script kvm-jrsl script, then log in as root
without any password (Do not do that with any real system or a VM connected
to the internet!)

	chmod +x kvm-jrsl.sh
	./kvm-jrsl.sh

Resize the root partition and file system so that we have enough space to
actually install the kernel environment:

	echo ", +" | sfdisk --force -N 1 /dev/vda

And then reboot the system for the new partition size to be available:

	reboot

Log in again as root with root without password and then resize the file
root system as well.

	resize2fs /dev/vda1

After this we can install the required packages for building the kernel,
but first update the package list:

	apt-get update
	apt-get upgrade
	apt-get install build-essential flex bison gdb libelf-dev bc libssl-dev
	apt-get install git git-email

You'll want a favorite text-based editor installed in the VM.  It is needed
at very least for some configuration file edits, but if you like writing
code in text based environments (as I do) this means you can do all the work
in the VM, which simplifies a few things.  If you don't like writing code
in a text based editor, you can write the actual code outside the VM using a
graphical editor and IDE and use a shared folder to copy the file over.

vim and nano are already installed in the VM, but if you for example like
emacs, install it now:

	apt-get intall emacs

Now we need to clone the kernel git tree.  For real kernel development we'd
clone the entire tree using this command:

	git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git

But as the repository contains the Linux development history going back many
years this could take a long time, especially with a not quite perfect
internet connection.  So I'd suggest this instead to only clone the very
latest version without any history:

	mkdir linux
	cd linux
	git init
	git remote add origin git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
	git fetch --depth=1 origin master
	git checkout origin/master

With this, we are prepared for the workshop.  If you can do this at home it
will speed thing up, if not you at least know what do and we can do it
together at the beginning of the workshop.
