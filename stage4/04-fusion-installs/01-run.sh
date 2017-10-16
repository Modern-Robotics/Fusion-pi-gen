#!/bin/bash -e

on_chroot << EOF
apt-get install --fix-missing
wget http://EW7YQNYK608D0QI2TT6T:FZHW0ZS4QD8EYQLXDGCF@raw.githubusercontent.com/Modern-Robotics/Fusion/master/distroInstall.sh
bash distroInstall.sh
rm -r distroInstall.sh
EOF
