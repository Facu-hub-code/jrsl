The simple block layer interface is based around a struct gendisk.
We allocate it, set a name and ops, and a (so far fake) size, and
register it.  Right now the submit_bio routine will simply always
return an error, but this allows for the device to actually show
up in the system.
]
Signed-off-by: Christoph Hellwig <hch at lst.de>
---
 drivers/block/nvme-cmb.c | 34 ++++++++++++++++++++++++++++++++++
 1 file changed, 34 insertions(+)

diff --git a/drivers/block/nvme-cmb.c b/drivers/block/nvme-cmb.c
index 9858c8afc..43603f8c7 100644
--- a/drivers/block/nvme-cmb.c
+++ b/drivers/block/nvme-cmb.c
@@ -1,3 +1,4 @@
+#include <linux/blkdev.h>
 #include <linux/delay.h>
 #include <linux/init.h>
 #include <linux/module.h>
@@ -14,6 +15,8 @@ struct nvme_cmb_dev {
 	size_t buffer_offset;
 	size_t buffer_size;
 
+	struct gendisk *disk;
+
 	struct nvme_command *admin_sqes;
 	dma_addr_t admin_sq_dma_addr;
 	struct nvme_completion *admin_cqes;
@@ -24,6 +27,16 @@ struct nvme_cmb_dev {
 
 #define QUEUE_SIZE 2
 
+static void nvme_cmb_submit_bio(struct bio *bio)
+{
+	bio_io_error(bio);
+}
+
+static const struct block_device_operations nvme_cmb_ops = {
+	.owner = THIS_MODULE,
+	.submit_bio = nvme_cmb_submit_bio,
+};
+
 static int nvme_cmb_alloc_queues(struct nvme_cmb_dev *dev, struct pci_dev *pdev)
 {
 	dev->admin_sqes = dma_alloc_coherent(&pdev->dev,
@@ -150,11 +163,29 @@ static int nvme_cmb_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 	if (error)
 		goto out_shutdown;
 
+	dev->disk = blk_alloc_disk(NUMA_NO_NODE);
+	if (!dev->disk) {
+		error = -ENOMEM;
+		goto out_unmap_cmb;
+	}
+	dev->disk->private_data = dev;
+	dev->disk->fops = &nvme_cmb_ops;
+	set_capacity(dev->disk, SZ_16M >> SECTOR_SHIFT);
+	snprintf(dev->disk->disk_name, DISK_NAME_LEN, "nc0");
+
+	error = device_add_disk(&pdev->dev, dev->disk, NULL);
+	if (error)
+		goto out_put_disk;
+
 	dev_set_drvdata(&pdev->dev, dev);
 	dev_info(&pdev->dev, "added %zu MiB ramdisk\n",
 		 dev->buffer_size / SZ_1M);
 	return 0;
 
+out_put_disk:
+	put_disk(dev->disk);
+out_unmap_cmb:
+	iounmap(dev->buffer_bar);
 out_shutdown:
 	nvme_cmb_shutdown(dev);
 	nvme_cmb_free_queues(dev, pdev);
@@ -175,6 +206,9 @@ static void nvme_cmb_remove(struct pci_dev *pdev)
 
 	dev_info(&pdev->dev, "unbinding NVMe device\n");
 
+	del_gendisk(dev->disk);
+	put_disk(dev->disk);
+
 	iounmap(dev->buffer_bar);
 	nvme_cmb_shutdown(dev);
 	nvme_cmb_free_queues(dev, pdev);
