#!/bin/bash
# Script outline to install and build kernel.
# Author: Siddhant Jajoo.
# Student: Hans Van Ingelgom
set -e
set -u

OUTDIR=/tmp/aeld
KERNEL_REPO=git://git.kernel.org/pub/scm/linux/kernel/git/stable/linux-stable.git
KERNEL_VERSION=v5.1.10
BUSYBOX_VERSION=1_33_1
FINDER_APP_DIR=$(realpath $(dirname $0))
ARCH=arm64
CROSS_COMPILE=aarch64-none-linux-gnu-
SYSROOT=$(${CROSS_COMPILE}gcc -print-sysroot)

if [ $# -lt 1 ]
then
	echo "Using default directory ${OUTDIR} for output"
else
	OUTDIR=$1
	echo "Using passed directory ${OUTDIR} for output"
fi
#Make sure we have an absolute path
OUTDIR=$(realpath ${OUTDIR})

if ! mkdir -p ${OUTDIR}
then
	echo "Could not create output directory ${OUTDIR}"
	exit 1
fi

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/linux-stable" ]; then
    #Clone only if the repository does not exist.
	echo "CLONING GIT LINUX STABLE VERSION ${KERNEL_VERSION} IN ${OUTDIR}"
	git clone ${KERNEL_REPO} --depth 1 --single-branch --branch ${KERNEL_VERSION}
fi
if [ ! -e ${OUTDIR}/linux-stable/arch/${ARCH}/boot/Image ]; then
    cd linux-stable
    echo "Checking out version ${KERNEL_VERSION}"
    git checkout ${KERNEL_VERSION}

    # Linux kernel build steps
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE mrproper
    make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE defconfig
    make -j8 ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE all
    make -j8 ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE modules
    make -j8 ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE dtbs
fi

echo "Adding the Image in outdir"

ROOTFS=${OUTDIR}/rootfs

echo "Creating the staging directory for the root filesystem"
cd "$OUTDIR"
if [ -d "${OUTDIR}/rootfs" ]
then
    echo "Deleting rootfs directory at ${OUTDIR}/rootfs and starting over"
    rm  -rf ${OUTDIR}/rootfs
fi

# Create necessary base directories
if ! mkdir -p ${ROOTFS}
then
    echo "could not create directory ${ROOTFS}"
    exit 1
fi

cd ${ROOTFS}
for fsdir in bin dev etc home lib lib64 proc sbin sys tmp usr var usr/bin usr/lib usr/sbin var/log
do
    if ! mkdir -p $fsdir
    then
        echo "Could not create $fsdir"
	exit 1
    fi
done

cd "$OUTDIR"
if [ ! -d "${OUTDIR}/busybox" ]
then
git clone git://busybox.net/busybox.git
    cd busybox
    git checkout ${BUSYBOX_VERSION}
    # Configure busybox
    make distclean
    make defconfig
else
    cd busybox
fi

# Make and install busybox
make ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE
make CONFIG_PREFIX=${ROOTFS} ARCH=$ARCH CROSS_COMPILE=$CROSS_COMPILE install


echo "Library dependencies"
${CROSS_COMPILE}readelf -a ${ROOTFS}/bin/busybox | grep "program interpreter"
${CROSS_COMPILE}readelf -a ${ROOTFS}/bin/busybox | grep "Shared library"

# Add library dependencies to rootfs
for lib in lib/ld-linux-aarch64.so.1 lib64/libm.so.6 lib64/libresolv.so.2 lib64/libc.so.6
do
	if ! cp $SYSROOT/$lib $ROOTFS/lib
	then
		echo "Could not copy file $lib"
	fi
done

# Make device nodes
sudo mknod -m 666 ${ROOTFS}/dev/null c 1 3
sudo mknod -m 666 ${ROOTFS}/dev/console c 5 1
# Clean and build the writer utility
make clean
make CROSS_COMPILE=${CROSS_COMPILE}
# Copy the finder related scripts and executables to the /home directory
# on the target rootfs
for file in finder.sh writer.sh writer
do
	if ! cp ${FINDER_APP_DIR}/${file} ${ROOTFS}/home/${file}
	then
		echo "could not copy file ${file}"
	fi
done
# Chown the root directory (Modify ownership in archive using --owner)
cd ${ROOTFS}
find . | cpio -H newc -ov --owner root:root > ${OUTDIR}/initramfs.cpio
# Create initramfs.cpio.gz
gzip -f ${OUTDIR}/initramfs.cpio

