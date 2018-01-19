#!/bin/bash -e

install -m 777 distroInstall.sh ${ROOTFS_DIR}/

on_chroot << EOF
apt-get install --fix-missing
bash /distroInstall.sh
rm -r distroInstall.sh
EOF