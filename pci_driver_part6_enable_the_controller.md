This sets a bunch of (for us basically magic) values in the config
register, and then flip the enable bit and then waits for the
controller to be live.  On the remove side we also have to shut it
down in a similar way.

Signed-off-by: Christoph Hellwig <hch at lst.de>
---
 drivers/block/nvme-cmb.c | 37 +++++++++++++++++++++++++++++++++++++
 1 file changed, 37 insertions(+)

diff --git a/drivers/block/nvme-cmb.c b/drivers/block/nvme-cmb.c
index 6638a73d4..f072fe2f9 100644
--- a/drivers/block/nvme-cmb.c
+++ b/drivers/block/nvme-cmb.c
@@ -1,3 +1,4 @@
+#include <linux/delay.h>
 #include <linux/init.h>
 #include <linux/module.h>
 #include <linux/kernel.h>
@@ -14,6 +15,8 @@ struct nvme_cmb_dev {
 	dma_addr_t admin_sq_dma_addr;
 	struct nvme_completion *admin_cqes;
 	dma_addr_t admin_cq_dma_addr;
+
+	u32 cc;
 };
 
 #define QUEUE_SIZE 2
@@ -55,6 +58,37 @@ static void nvme_cmb_free_queues(struct nvme_cmb_dev *dev, struct pci_dev *pdev)
 			  dev->admin_sqes, dev->admin_sq_dma_addr);
 }
 
+static void nvme_cmb_enable(struct nvme_cmb_dev *dev)
+{
+	dev->cc = NVME_CC_CSS_NVM | NVME_CC_AMS_RR |
+	    NVME_CC_IOSQES | NVME_CC_IOCQES;
+	writel(dev->cc, dev->bar + NVME_REG_CC);
+
+	dev->cc |= NVME_CC_ENABLE;
+	writel(dev->cc, dev->bar + NVME_REG_CC);
+	while (true) {
+		u32 csts = readl(dev->bar + NVME_REG_CSTS);
+
+		if (csts & NVME_CSTS_RDY)
+			break;
+		usleep_range(1000, 2000);
+	}
+}
+
+static void nvme_cmb_shutdown(struct nvme_cmb_dev *dev)
+{
+	dev->cc &= ~NVME_CC_SHN_MASK;
+	dev->cc |= NVME_CC_SHN_NORMAL;
+	writel(dev->cc, dev->bar + NVME_REG_CC);
+	while (true) {
+		u32 csts = readl(dev->bar + NVME_REG_CSTS);
+
+		if ((csts & NVME_CSTS_SHST_MASK) == NVME_CSTS_SHST_CMPLT)
+			break;
+		usleep_range(1000, 2000);
+	}
+}
+
 static int nvme_cmb_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 {
 	struct nvme_cmb_dev *dev;
@@ -89,6 +123,8 @@ static int nvme_cmb_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 	if (error)
 		goto out_iounmap;
 
+	nvme_cmb_enable(dev);
+
 	dev_set_drvdata(&pdev->dev, dev);
 	return 0;
 
@@ -109,6 +145,7 @@ static void nvme_cmb_remove(struct pci_dev *pdev)
 
 	dev_info(&pdev->dev, "unbinding NVMe device\n");
 
+	nvme_cmb_shutdown(dev);
 	nvme_cmb_free_queues(dev, pdev);
 	iounmap(dev->bar);
 	pci_release_mem_regions(pdev);
