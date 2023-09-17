The NVMe controller memory buffer is essentially just a bit of memory
a NVMe device can expose through a PCIe bar.  We're going to expose
it as a ramdisk.  For that we need to read very strangly encoded
values about the location from regisers.  You're not really supposed
to understand this unless you've already dealt with hardware interface
before, in which case you understand the horrors.

Signed-off-by: Christoph Hellwig <hch at lst.de>
---
 drivers/block/nvme-cmb.c | 31 +++++++++++++++++++++++++++++++
 1 file changed, 31 insertions(+)

diff --git a/drivers/block/nvme-cmb.c b/drivers/block/nvme-cmb.c
index f072fe2f9..9858c8afc 100644
--- a/drivers/block/nvme-cmb.c
+++ b/drivers/block/nvme-cmb.c
@@ -10,6 +10,9 @@ MODULE_LICENSE("GPL");
 
 struct nvme_cmb_dev {
 	void __iomem *bar;
+	void __iomem *buffer_bar;
+	size_t buffer_offset;
+	size_t buffer_size;
 
 	struct nvme_command *admin_sqes;
 	dma_addr_t admin_sq_dma_addr;
@@ -89,6 +92,24 @@ static void nvme_cmb_shutdown(struct nvme_cmb_dev *dev)
 	}
 }
 
+static int nvme_cmb_map_buffer(struct nvme_cmb_dev *dev, struct pci_dev *pdev)
+{
+	u32 cmbloc = readl(dev->bar + NVME_REG_CMBLOC);
+	u32 cmbsz = readl(dev->bar + NVME_REG_CMBSZ);
+	u64 unit = 1ULL << (12 + 4 *
+			    ((cmbsz >> NVME_CMBSZ_SZU_SHIFT) &
+			     NVME_CMBSZ_SZU_MASK));
+
+	dev->buffer_bar = pci_ioremap_bar(pdev, NVME_CMB_BIR(cmbloc));
+	if (!dev->buffer_bar)
+		return -ENOMEM;
+
+	dev->buffer_offset = unit * NVME_CMB_OFST(cmbloc);
+	dev->buffer_size =
+	    unit * ((cmbsz >> NVME_CMBSZ_SZ_SHIFT) & NVME_CMBSZ_SZ_MASK);
+	return 0;
+}
+
 static int nvme_cmb_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 {
 	struct nvme_cmb_dev *dev;
@@ -125,9 +146,18 @@ static int nvme_cmb_probe(struct pci_dev *pdev, const struct pci_device_id *id)
 
 	nvme_cmb_enable(dev);
 
+	error = nvme_cmb_map_buffer(dev, pdev);
+	if (error)
+		goto out_shutdown;
+
 	dev_set_drvdata(&pdev->dev, dev);
+	dev_info(&pdev->dev, "added %zu MiB ramdisk\n",
+		 dev->buffer_size / SZ_1M);
 	return 0;
 
+out_shutdown:
+	nvme_cmb_shutdown(dev);
+	nvme_cmb_free_queues(dev, pdev);
 out_iounmap:
 	iounmap(dev->bar);
 out_release_regions:
@@ -145,6 +175,7 @@ static void nvme_cmb_remove(struct pci_dev *pdev)
 
 	dev_info(&pdev->dev, "unbinding NVMe device\n");
 
+	iounmap(dev->buffer_bar);
 	nvme_cmb_shutdown(dev);
 	nvme_cmb_free_queues(dev, pdev);
 	iounmap(dev->bar);
