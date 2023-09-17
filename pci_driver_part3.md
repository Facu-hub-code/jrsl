>From 390cfb54c29efc30f0cd6c6c596ab057c7d44cf7 Mon Sep 17 00:00:00 2001
From: Christoph Hellwig <hch@lst.de>
Date: Wed, 13 Sep 2023 19:03:43 +0000
Subject: nvme-cmb: add a per-device private data structure

To make sure a driver support multiple devices, device-specific data
must not be stored in global information.  Instead each device structure
(which is embedded into the pci_dev structure) has a pointer to private
data that can be used.  Just create an empty structure for now, allocate
and set it in the probe routine, and free it in the remove routine.

Signed-off-by: Christoph Hellwig <hch@lst.de>
---
 drivers/block/nvme-cmb.c | 16 +++++++++++++++-
 1 file changed, 15 insertions(+), 1 deletion(-)

diff --git a/drivers/block/nvme-cmb.c b/drivers/block/nvme-cmb.c
index 06ff67ee3..f92f0f3cd 100644
--- a/drivers/block/nvme-cmb.c
+++ b/drivers/block/nvme-cmb.c
@@ -5,33 +5,47 @@
 
 MODULE_LICENSE("GPL");
 
+struct nvme_cmb_dev {
+};
+
 static int nvme_cmb_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 {
+	struct nvme_cmb_dev *dev;
 	int error;
 
 	dev_info(&pdev->dev, "found NVMe device\n");
 
+	dev = kzalloc(sizeof(*dev), GFP_KERNEL);
+	if (!dev)
+		return -ENOMEM;
+
 	pci_set_master(pdev);
 	error = pci_enable_device_mem(pdev);
 	if (error)
-		return error;
+		goto out_free_dev;
 	error = pci_request_mem_regions(pdev, "nvme-cmb");
 	if (error)
 		goto out_disable_device;
 
+	dev_set_drvdata(&pdev->dev, dev);
 	return 0;
 
 out_disable_device:
 	pci_disable_device(pdev);
+out_free_dev:
+	kfree(dev);
 	return error;
 }
 
 static void nvme_cmb_remove(struct pci_dev *pdev)
 {
+	struct nvme_cmb_dev *dev = dev_get_drvdata(&pdev->dev);
+
 	dev_info(&pdev->dev, "unbinding NVMe device\n");
 
 	pci_release_mem_regions(pdev);
 	pci_disable_device(pdev);
+	kfree(dev);
 }
 
 static const struct pci_device_id nvme_cmb_id_table[] = {
-- 
2.39.2

