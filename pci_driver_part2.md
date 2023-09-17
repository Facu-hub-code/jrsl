>From 74b580e264b0882fea7ed564a0ab17a2e3339ffd Mon Sep 17 00:00:00 2001
From: Christoph Hellwig <hch@lst.de>
Date: Wed, 13 Sep 2023 18:58:58 +0000
Subject: nvme-cmb: add the basic PCI boilerplate code

Set the device into bus mastering mode, enable it and claim the
MMIO regions.

Signed-off-by: Christoph Hellwig <hch@lst.de>
---
 drivers/block/nvme-cmb.c | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)

diff --git a/drivers/block/nvme-cmb.c b/drivers/block/nvme-cmb.c
index 7840bbf4d..06ff67ee3 100644
--- a/drivers/block/nvme-cmb.c
+++ b/drivers/block/nvme-cmb.c
@@ -7,13 +7,31 @@ MODULE_LICENSE("GPL");
 
 static int nvme_cmb_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 {
+	int error;
+
 	dev_info(&pdev->dev, "found NVMe device\n");
+
+	pci_set_master(pdev);
+	error = pci_enable_device_mem(pdev);
+	if (error)
+		return error;
+	error = pci_request_mem_regions(pdev, "nvme-cmb");
+	if (error)
+		goto out_disable_device;
+
 	return 0;
+
+out_disable_device:
+	pci_disable_device(pdev);
+	return error;
 }
 
 static void nvme_cmb_remove(struct pci_dev *pdev)
 {
 	dev_info(&pdev->dev, "unbinding NVMe device\n");
+
+	pci_release_mem_regions(pdev);
+	pci_disable_device(pdev);
 }
 
 static const struct pci_device_id nvme_cmb_id_table[] = {
-- 
2.39.2

