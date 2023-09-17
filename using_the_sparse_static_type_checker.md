As most people know C can be a somewhat dangerous language as it is not
very strictly typed.  While compilers get stricter and stricter, there
is still a lot of things missing out.  Linux can use the "sparse" tool
to check additional nits, but more importantly additional annotations.

First install sparse:

	apt-get install sparse

Then you can build the module so that sparse is run in addition to the
actual C compiler:

	make C=2 drivers/block/nvme-cmb.ko

This should not report any error with the current code base.

## Address space annotations

Did you see the

	__iomem

annotation on the bar field in struct nvme_cmb_device?  This is a macro
provided by Linux that is defined away for a normal C compiler, but used
by sparse.  If we remove it, you now should see sparse errors.

Why do we do these assignments?  On x86 accessing memory mapped I/O
works using the normal load and store instructions, but on some
architectures it doesn't, or requires memory barriers.  Because of that
Linux always needs to use proper accessors for it, and not just normal
assignments or functions like memcpy.

This becomes even more important when the kernel access the memory in
user space processes (i.e. normal programs) from syscalls, where every
access can cause a page fault.  These pointers are annotated using a
similar

	__user

annotation and also need their own set of special handlers.
