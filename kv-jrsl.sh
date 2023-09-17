#/bin/sh

# qemu
QEMU="qemu-system-x86_64"
# alternatively for self-built qemu
#QEMU="/opt/newqemu/bin/qemu-system-x86_64"

# image file
PREFIX="."
IMAGE="debian-12-nocloud-amd64.qcow2"

# set to something lower if you have less cores
CPUS="2"

mkdir -p shared

${QEMU} \
	-nographic  \
	-enable-kvm \
	-m 2g \
	-smp ${CPUS} \
	-cpu host \
	-drive file=${PREFIX}/${IMAGE},if=virtio \
	-device nvme,id=nvme0,serial=0123456789,cmb_size_mb=16,legacy-cmb \
	-device nvme,id=nvme1,serial=0123456788,cmb_size_mb=32,legacy-cmb \
	-virtfs local,path=./shared,mount_tag=shared,security_model=mapped-xattr
