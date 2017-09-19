#!/bin/bash -e

on_chroot << EOF
apt-get install --fix-missing
wget http://raw.githubusercontent.com/Modern-Robotics/Fusion/master/distroInstall.sh
bash distroInstall.sh
rm -r distroInstall.sh
EOF