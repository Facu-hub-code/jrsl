>From 5504c87237f943136baff47d33432d07a42b983c Mon Sep 17 00:00:00 2001
From: Christoph Hellwig <hch@lst.de>
Date: Wed, 13 Sep 2023 19:06:08 +0000
Subject: nvme-pci: map the BAR and check the device is present

The BAR (Base Address Register) is what is used for all register-like
access in PCI/PCIe devices, and we need to map it using the
 pci_ioremap_bar function with the right attributes (e.g. noncached)
 to access it.

Do that, and then use the MMIO access helper to read the status
register.  If it reads all-Fs that means we can't talk to the device,
in which case we give up on trying to initialize the device.

Signed-off-by: Christoph Hellwig <hch@lst.de>
---
 drivers/block/nvme-cmb.c | 17 +++++++++++++++++
 1 file changed, 17 insertions(+)

diff --git a/drivers/block/nvme-cmb.c b/drivers/block/nvme-cmb.c
index f92f0f3cd..0ca7cbb97 100644
--- a/drivers/block/nvme-cmb.c
+++ b/drivers/block/nvme-cmb.c
@@ -2,10 +2,12 @@
 #include <linux/module.h>
 #include <linux/kernel.h>
 #include <linux/pci.h>
+#include <linux/nvme.h>
 
 MODULE_LICENSE("GPL");
 
 struct nvme_cmb_dev {
+	void __iomem *bar;
 };
 
 static int nvme_cmb_probe(struct pci_dev *pdev, const struct pci_device_id *id)
@@ -27,9 +29,23 @@ static int nvme_cmb_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 	if (error)
 		goto out_disable_device;
 
+	dev->bar = pci_ioremap_bar(pdev, 0);
+	if (!dev->bar) {
+		error = -ENOMEM;
+		goto out_release_regions;
+	}
+
+	if (readl(dev->bar + NVME_REG_CSTS) == ~0) {
+		error = -EIO;
+		goto out_iounmap;
+	}
 	dev_set_drvdata(&pdev->dev, dev);
 	return 0;
 
+out_iounmap:
+	iounmap(dev->bar);
+out_release_regions:
+	pci_release_mem_regions(pdev);
 out_disable_device:
 	pci_disable_device(pdev);
 out_free_dev:
@@ -43,6 +59,7 @@ static void nvme_cmb_remove(struct pci_dev *pdev)
 
 	dev_info(&pdev->dev, "unbinding NVMe device\n");
 
+	iounmap(dev->bar);
 	pci_release_mem_regions(pdev);
 	pci_disable_device(pdev);
 	kfree(dev);
-- 
2.39.2

