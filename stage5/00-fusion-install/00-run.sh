#!/bin/bash -e
################################################################################
# FusionServer Integrator/Installer - This script drives the integration and
# configuration of the JessieOS with the FusionOS.
#-------------------------------------------------------------------------------
# 20-Aug-2018 <jwa> - Added progress messages and revision history
#
################################################################################

echo "Copying the installer distroInstaller.sh to ${ROOTFS_DIR}"
install -m 777 distroInstall.sh ${ROOTFS_DIR}/

echo
echo "Running the installer..."
on_chroot << EOF
echo "...Checking for missing libraries..."
apt-get install --fix-missing
echo "...running distroInstall.sh..."
bash /distroInstall.sh
rm -r distroInstall.sh
EOF

echo
echo "Copying the dnsmasq service script to ${ROOTFS_DIR}/etc/init.d..."
install -m 755 dnsmasq ${ROOTFS_DIR}/etc/init.d/

