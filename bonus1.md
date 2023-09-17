So far we've just added a 0 postfix to the device name unconditionally.
This does not work if there are multiple devices.  Use the Linux
IDA data structure to allocate and index, and use that for the device
name.

Signed-off-by: Christoph Hellwig <hch at lst.de>
---
 drivers/block/nvme-cmb.c | 15 +++++++++++++--
 1 file changed, 13 insertions(+), 2 deletions(-)

diff --git a/drivers/block/nvme-cmb.c b/drivers/block/nvme-cmb.c
index f5a70b8a7..13160576f 100644
--- a/drivers/block/nvme-cmb.c
+++ b/drivers/block/nvme-cmb.c
@@ -1,5 +1,6 @@
 #include <linux/blkdev.h>
 #include <linux/delay.h>
+#include <linux/idr.h>
 #include <linux/init.h>
 #include <linux/module.h>
 #include <linux/kernel.h>
@@ -16,6 +17,7 @@ struct nvme_cmb_dev {
 	size_t buffer_size;
 
 	struct gendisk *disk;
+	int index;
 
 	struct nvme_command *admin_sqes;
 	dma_addr_t admin_sq_dma_addr;
@@ -27,6 +29,8 @@ struct nvme_cmb_dev {
 
 #define QUEUE_SIZE 2
 
+static DEFINE_IDA(nvme_cmb_index_ida);
+
 static void nvme_cmb_submit_bio(struct bio *bio)
 {
 	struct nvme_cmb_dev *dev = bio->bi_bdev->bd_disk->private_data;
@@ -187,17 +191,23 @@ static int nvme_cmb_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 	dev->disk->private_data = dev;
 	dev->disk->fops = &nvme_cmb_ops;
 	set_capacity(dev->disk, SZ_16M >> SECTOR_SHIFT);
-	snprintf(dev->disk->disk_name, DISK_NAME_LEN, "nc0");
+
+	error = ida_alloc(&nvme_cmb_index_ida, GFP_KERNEL);
+	if (error < 0)
+		goto out_put_disk;
+	snprintf(dev->disk->disk_name, DISK_NAME_LEN, "nc%d", error);
 
 	error = device_add_disk(&pdev->dev, dev->disk, NULL);
 	if (error)
-		goto out_put_disk;
+		goto out_ida_free;
 
 	dev_set_drvdata(&pdev->dev, dev);
 	dev_info(&pdev->dev, "added %zu MiB ramdisk\n",
 		 dev->buffer_size / SZ_1M);
 	return 0;
 
+out_ida_free:
+	ida_free(&nvme_cmb_index_ida, dev->index);
 out_put_disk:
 	put_disk(dev->disk);
 out_unmap_cmb:
@@ -224,6 +234,7 @@ static void nvme_cmb_remove(struct pci_dev *pdev)
 
 	del_gendisk(dev->disk);
 	put_disk(dev->disk);
+	ida_free(&nvme_cmb_index_ida, dev->index);
 
 	iounmap(dev->buffer_bar);
 	nvme_cmb_shutdown(dev);
