NVMe devices need queues allocated to enable the device.  We're
not really going to make use of them, but this is required and
happens to give a basic introduction into DMA allocations.

Signed-off-by: Christoph Hellwig <hch at lst.de>
---
 drivers/block/nvme-cmb.c | 51 ++++++++++++++++++++++++++++++++++++++++
 1 file changed, 51 insertions(+)

diff --git a/drivers/block/nvme-cmb.c b/drivers/block/nvme-cmb.c
index 0ca7cbb97..6638a73d4 100644
--- a/drivers/block/nvme-cmb.c
+++ b/drivers/block/nvme-cmb.c
@@ -3,13 +3,58 @@
 #include <linux/kernel.h>
 #include <linux/pci.h>
 #include <linux/nvme.h>
+#include <linux/io-64-nonatomic-lo-hi.h>
 
 MODULE_LICENSE("GPL");
 
 struct nvme_cmb_dev {
 	void __iomem *bar;
+
+	struct nvme_command *admin_sqes;
+	dma_addr_t admin_sq_dma_addr;
+	struct nvme_completion *admin_cqes;
+	dma_addr_t admin_cq_dma_addr;
 };
 
+#define QUEUE_SIZE 2
+
+static int nvme_cmb_alloc_queues(struct nvme_cmb_dev *dev, struct pci_dev *pdev)
+{
+	dev->admin_sqes = dma_alloc_coherent(&pdev->dev,
+					     QUEUE_SIZE *
+					     sizeof(*dev->admin_sqes),
+					     &dev->admin_sq_dma_addr,
+					     GFP_KERNEL);
+	if (!dev->admin_sqes)
+		return -ENOMEM;
+	lo_hi_writeq(dev->admin_sq_dma_addr, dev->bar + NVME_REG_ASQ);
+
+	dev->admin_cqes = dma_alloc_coherent(&pdev->dev,
+					     QUEUE_SIZE *
+					     sizeof(*dev->admin_cqes),
+					     &dev->admin_cq_dma_addr,
+					     GFP_KERNEL);
+	if (!dev->admin_cqes) {
+		dma_free_coherent(&pdev->dev,
+				  QUEUE_SIZE * sizeof(*dev->admin_cqes),
+				  dev->admin_cqes, dev->admin_cq_dma_addr);
+		return -ENOMEM;
+	}
+	lo_hi_writeq(dev->admin_cq_dma_addr, dev->bar + NVME_REG_ACQ);
+
+	writel((QUEUE_SIZE - 1) | ((QUEUE_SIZE - 1) << 16),
+	       dev->bar + NVME_REG_AQA);
+	return 0;
+}
+
+static void nvme_cmb_free_queues(struct nvme_cmb_dev *dev, struct pci_dev *pdev)
+{
+	dma_free_coherent(&pdev->dev, QUEUE_SIZE * sizeof(*dev->admin_cqes),
+			  dev->admin_cqes, dev->admin_cq_dma_addr);
+	dma_free_coherent(&pdev->dev, QUEUE_SIZE * sizeof(*dev->admin_sqes),
+			  dev->admin_sqes, dev->admin_sq_dma_addr);
+}
+
 static int nvme_cmb_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 {
 	struct nvme_cmb_dev *dev;
@@ -39,6 +84,11 @@ static int nvme_cmb_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 		error = -EIO;
 		goto out_iounmap;
 	}
+
+	error = nvme_cmb_alloc_queues(dev, pdev);
+	if (error)
+		goto out_iounmap;
+
 	dev_set_drvdata(&pdev->dev, dev);
 	return 0;
 
@@ -59,6 +109,7 @@ static void nvme_cmb_remove(struct pci_dev *pdev)
 
 	dev_info(&pdev->dev, "unbinding NVMe device\n");
 
+	nvme_cmb_free_queues(dev, pdev);
 	iounmap(dev->bar);
 	pci_release_mem_regions(pdev);
 	pci_disable_device(pdev);
