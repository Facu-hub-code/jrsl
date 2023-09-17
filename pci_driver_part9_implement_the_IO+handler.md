The ->submit_bio method gets the bio structure that describes the
I/O passed to it.  We use that to find the device we're operating
on, the size and length of the I/O, which could be broken into
discontiguous buffers, and then just copy it from/to the device
memory.

Signed-off-by: Christoph Hellwig <hch at lst.de>
---
 drivers/block/nvme-cmb.c | 18 +++++++++++++++++-
 1 file changed, 17 insertions(+), 1 deletion(-)

diff --git a/drivers/block/nvme-cmb.c b/drivers/block/nvme-cmb.c
index 43603f8c7..f5a70b8a7 100644
--- a/drivers/block/nvme-cmb.c
+++ b/drivers/block/nvme-cmb.c
@@ -29,7 +29,23 @@ struct nvme_cmb_dev {
 
 static void nvme_cmb_submit_bio(struct bio *bio)
 {
-	bio_io_error(bio);
+	struct nvme_cmb_dev *dev = bio->bi_bdev->bd_disk->private_data;
+	void __iomem *buffer = dev->buffer_bar + dev->buffer_offset;
+	struct bvec_iter iter;
+	struct bio_vec bv;
+
+	bio_for_each_segment(bv, bio, iter) {
+		void __iomem *dev_addr = buffer +
+		    (iter.bi_sector << SECTOR_SHIFT);
+		void *kaddr = bvec_virt(&bv);
+
+		if (bio_op(bio) == REQ_OP_READ)
+			memcpy_fromio(kaddr, dev_addr, bv.bv_len);
+		else
+			memcpy_toio(dev_addr, kaddr, bv.bv_len);
+	}
+
+	bio_endio(bio);
 }
 
 static const struct block_device_operations nvme_cmb_ops = {
