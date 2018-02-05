#!/bin/bash

# -------------------------------------------------------------------
# Default argument values
ADDRESS=https://github.com/Modern-Robotics/Fusion.git
MAIN_DIR=/usr/Fusion
CMDLINE=/boot/cmdline.txt

# -------------------------------------------------------------------
# Set the commit number to build or build the most recent release
COMMIT=4fda0d3 
#COMMIT=$(sudo git rev-list --tags --max-count=1)

# -------------------------------------------------------------------
# Set boot to enable uart
if grep -q "#enable_uart=1" /boot/config.txt 
then
     sed -i "/#enable_uart=1/c\enable_uart=1" /boot/config.txt
    echo "UART now enabled"
elif grep -q "enable_uart=1" /boot/config.txt 
then
    echo "UART already enabled"
else 
     echo |  tee -a /boot/config.txt 
     echo "enable_uart=1" |  tee -a /boot/config.txt
    echo "UART now enabled"
fi
if [[ $? != 0 ]]; then exit 6; fi

# -------------------------------------------------------------------
if grep -q "console=ttyAMA0" $CMDLINE ; then
  if [ -e /proc/device-tree/aliases/serial0 ]; then
    sed -i $CMDLINE -e "s/console=ttyAMA0/console=serial0/"
  fi
elif ! grep -q "console=ttyAMA0" $CMDLINE && ! grep -q "console=serial0" $CMDLINE ; then
  if [ -e /proc/device-tree/aliases/serial0 ]; then
    sed -i $CMDLINE -e "s/root=/console=serial0,115200 root=/"
  else
    sed -i $CMDLINE -e "s/root=/console=ttyAMA0,115200 root=/"
  fi
fi

# -------------------------------------------------------------------
# Set boot to enable i2c
if grep -q "#dtparam=i2c_arm=on" /boot/config.txt 
then
     sed -i "/#dtparam=i2c_arm=on/c\dtparam=i2c_arm=on" /boot/config.txt
    echo "I2C now enabled"
elif grep -q "dtparam=i2c_arm=on" /boot/config.txt 
then
    echo "I2C already enabled"
else 
     echo |  tee -a /boot/config.txt 
     echo "dtparam=i2c_arm=on" |  tee -a /boot/config.txt
    echo "I2C now enabled"
fi

# -------------------------------------------------------------------
# Set boot to avoid warnings
if grep -q "#avoid_warnings=1" /boot/config.txt 
then
     sed -i "/#avoid_warnings=1/c\avoid_warnings=1" /boot/config.txt
    echo "Warnings now disabled"
elif grep -q "avoid_warnings=1" /boot/config.txt 
then
    echo "Warnings already disabled"
else 
     echo |  tee -a /boot/config.txt 
     echo "avoid_warnings=1" |  tee -a /boot/config.txt
    echo "Warnings now disabled"
fi

# -------------------------------------------------------------------
# Update module file with kernel for i2c-dev
if grep -q "#i2c-dev" /etc/modules 
then
     sed -i "/#i2c-dev/c\i2c-dev" /etc/modules
    echo "i2c-dev now enabled"
elif grep -q "i2c-dev" /etc/modules
then
    echo "i2c-dev already enabled"
else 
     echo |  tee -a /etc/modules 
     echo "i2c-dev" |  tee -a /etc/modules
    echo "i2c-dev added and enabled"
fi

# -------------------------------------------------------------------
# Update module file with kernel for i2c-bcm2708
if grep -q "#i2c-bcm2708" /etc/modules 
then
     sed -i "/#i2c-bcm2708/c\i2c-bcm2708" /etc/modules
    echo "i2c-bcm2708 now enabled"
elif grep -q "i2c-bcm2708" /etc/modules
then
    echo "i2c-bcm2708 already enabled"
else 
     echo |  tee -a /etc/modules 
     echo "i2c-bcm2708" |  tee -a /etc/modules
    echo "i2c-bcm2708 added and enabled"
fi

# -------------------------------------------------------------------
# Update blacklist to turn off bluetooth
echo "blacklist btbcm" | tee -a /etc/modprobe.d/raspi-blacklist.conf
echo "blacklist hci_uart" | tee -a /etc/modprobe.d/raspi-blacklist.conf

cd /usr 
rm -r Fusion
git clone $ADDRESS
cd $MAIN_DIR
git reset --hard $COMMIT 

npm cache clean -f 
npm install -g n 
n stable 
npm install forever -g 
pip install imutils 
pip install numpy 
pip install --upgrade numpy

pip uninstall Fusion -y
pip install $MAIN_DIR/lib/Fusion*

cp /usr/Fusion/etc/interfaces /etc/network/interfaces 
chmod 644 /etc/network/interfaces 

cp /usr/Fusion/etc/dhcpcd.conf /etc/dhcpcd.conf 
chmod 644 /etc/dhcpcd.conf 

cp /usr/Fusion/etc/hostapd.conf /etc/hostapd/hostapd.conf 
chmod 644 /etc/hostapd/hostapd.conf 

cp /usr/Fusion/etc/hostapd /etc/default/hostapd 
chmod 644 /etc/default/hostapd

cp /usr/Fusion/etc/dnsmasq.conf /etc/dnsmasq.conf 
chmod 644 /etc/dnsmasq.conf 

python /usr/Fusion/etc/ssid_set.py 

cp /usr/Fusion/etc/rc.local /etc/rc.local 
chmod 755 /etc/rc.local 

cp /usr/Fusion/etc/keyboard /etc/default/keyboard
chmod 644 /etc/default/keyboard

# -----------------------------------------------------------------------------
# Enable services
update-rc.d ssh enable 
service ssh stop

update-rc.d mongodb enable 
service mongodb stop

update-rc.d hostapd enable 
service hostapd stop 

update-rc.d dnsmasq enable 
service dnsmasq stop 

systemctl enable vncserver-x11-serviced.service
systemctl stop vncserver-x11-serviced.service

# -----------------------------------------------------------------------------
# Symbolic link for videodev.h used by mjpg-streamer
ln -s /usr/include/linux/videodev2.h /usr/include/linux/videodev.h

# -----------------------------------------------------------------------------
# Add support for credentials in url 
#cd /usr/Fusion/FusionServer
#sudo npm install --unsafe-perm --production