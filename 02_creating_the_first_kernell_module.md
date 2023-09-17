
# Creating the first kernel module

## Build the module

First we create a little no-op module that literally does nothing,
but it shows how to compile a source file into a kernel module and
how to load it.

For this we create a new file named "drivers/block/nvme-cmb.c" in
the Linux source tree with the editor of our choice and add the
following three lines to it:

	#include <linux/module.h>

	MODULE_LICENSE("GPL");

and then wire it up to the build system, for this edit the
file "drivers/block/Makefile" to add this line:

	obj-m += nvme-cmb.o

at the end of the file.

You should now be able to do a

	make drivers/block/nvme-cmb.ko

to build the kernel module, and then do a

	insmod drivers/block/nvme-cmb.ko

to load it.  The load should be silent, if you see anything there was
an error and we need to look at it.  lsmod should now show that the
module is loaded, for that do a:

	lsmod | grep nvme

After that we can remove the module again to create a clean state
for our next round of improvements:

	rmmod nvme_cmb

Note that your should avoid doing a "make modules_install" while
doing the driver development, as that means the drivers gets loaded
at boot, which would be really annoying if your crashed due to a bug.

## Commit the module to git

To not lose the important work we just did we want to commit it to
version control.  Newly created files need to be added using git add,
which for us means:

	git add drivers/block/nvme-cmb.c

As we don't really want to add every single changed file, we tend
to use git commit -a to commit all changes, so:

	git commit -a

Then the editor fires up to write a commit message.  A good one
for this commit would be:

	nvme-cmb: create an initial stub module

	This is the absolute minimal viable Linux kernel module.

	Signed-off-by: Your Name <your@mail.address>

You can now do a

	git show

which should show you a patch with the commit message, the new file and
the change to the Makefile.

## Mailing out the patch

If this was a real kernel patch you'd now want to submit it to the
proper mailing list.  We'll send it to our usual list, for that do a:

	git send-email --anotate HEAD^..HEAD --to lkw@jrsl.org

The --anotate means you can review your changes in the editor before
sending, which is always a good idea.

## Module load/unload handlers

Well, a module without any code is a little boring, isn't it?  Let's do
the equivalent of a hello world program.

Linux modules have init and exit handlers that are called when a module
is loaded and unloaded.  While for a minimal module one of them would
be enough, having only an init handler but not exit one will make the
module unloadable, so we do both.

For that we first need two additional includes in the source file:

	#include <linux/init.h>
	#include <linux/kernel.h>

And then a few lines of code to print something on load and unload:

	static int __init nvme_cmb_init(void)
	{
		pr_info("loading nvme-cmb module\n");
		return 0;
	}

	static void __exit nvme_cmb_exit(void)
	{
		pr_info("unloading nvme-cmb module\n");
	}

	module_init(nvme_cmb_init);
	module_exit(nvme_cmb_exit);


Now we can build the module again using:

	make drivers/block/nvme-cmb.ko

And do the usual

	insmod drivers/block/nvme-cmb.ko

and

	rmmod nvme_cmb

which should send messages to the kernel log and console.

You can now send out your changes using

	git send-email --anotate HEAD^..HEAD --to lkw@jrsl.org

again.

## Coding style

Linux tries to have a uniform coding style for all code.  The style
is roughly the traditional C style going back to the invention of
the Language with a bunch of minor tweaks and all kinds of additional
requirements.  The easiest thing is to automate this and run the
Lindent script.  For this first install the "indent" tool:

	apt-get install indent

and then from the linux directory run the script:

	./scripts/Lindent drivers/block/nvme-cmb.c

If you have previously commit the work, a

	git diff

will show what this changed.  You can then do a

	git commit -a --amend

to update your current commit to include this changes instead of
doing a new commit.

You should probably run the script before every commit from now on.

## Summary

We've now written a trivial kernel module, load and unloaded it and
committed to source control.  Well done!
