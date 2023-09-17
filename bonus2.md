Instead of unconditionally build the nvme-cmb driver as a module,
add a Kconfig entry and make the build conditional on it.

Signed-off-by: Christoph Hellwig <hch at lst.de>
---
 drivers/block/Kconfig  | 6 ++++++
 drivers/block/Makefile | 2 +-
 2 files changed, 7 insertions(+), 1 deletion(-)

diff --git a/drivers/block/Kconfig b/drivers/block/Kconfig
index 5b9d4aaeb..29aa857e6 100644
--- a/drivers/block/Kconfig
+++ b/drivers/block/Kconfig
@@ -404,4 +404,10 @@ config BLKDEV_UBLK_LEGACY_OPCODES
 
 source "drivers/block/rnbd/Kconfig"
 
+config NVME_CMB
+	tristate "NVMe CMB ramdisk driver"
+	help
+	  This driver exports the controller memory buffer of a NVMe controller
+	  that supports this driver as a ramdisk.
+
 endif # BLK_DEV
diff --git a/drivers/block/Makefile b/drivers/block/Makefile
index 3ad5dcb18..8d8695fa6 100644
--- a/drivers/block/Makefile
+++ b/drivers/block/Makefile
@@ -41,4 +41,4 @@ obj-$(CONFIG_BLK_DEV_UBLK)			+= ublk_drv.o
 
 swim_mod-y	:= swim.o swim_asm.o
 
-obj-m += nvme-cmb.o
+obj-$(CONFIG_NVME_CMB)		+= nvme-cmb.o
