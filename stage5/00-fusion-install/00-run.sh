#!/bin/bash -e
################################################################################
# FusionServer Integrator/Installer - This script drives the integration and
# configuration of the JessieOS with the FusionOS.
#-------------------------------------------------------------------------------
# 20-Aug-2018 <jwa> - Added progress messages and revision history
#
################################################################################

echo "Copying the installer..."
install -m 777 distroInstall.sh ${ROOTFS_DIR}/

echo "Running the installer..."
on_chroot << EOF
apt-get install --fix-missing
bash /distroInstall.sh
rm -r distroInstall.sh
EOF

echo "Copying the dnsmasq service script..."
install -m 755 dnsmasq ${ROOTFS_DIR}/etc/init.d/

