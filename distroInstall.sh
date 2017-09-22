#!/bin/bash

# -------------------------------------------------------------------
# Default argument values
ADDRESS=https://github.com/Modern-Robotics/Fusion.git
MAIN_DIR=/usr/Fusion
PYTHON_TAR=Fusion-0.9.1.tar.gz

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
# Set console baud rate to 38400
if grep -q "console=serial0,115200" /boot/cmdline.txt
then
    sed -i "/115200/c\38400" /boot/cmdline.txt
    echo "Baud rate now 38400"
elif grep -q "console=serial0,38400" /boot/cmdline.txt
then
    echo "Baud rate already at 38400"
else
    echo " console=serial0,38400" | tee -a /boot/cmdline.txt
    echo "Baud rate now 38400"
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
if [[ $? != 0 ]]; then exit 7; fi

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
if [[ $? != 0 ]]; then exit 8; fi

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
if [[ $? != 0 ]]; then exit 9; fi

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
if [[ $? != 0 ]]; then exit 10; fi

cd /usr 
rm -r Fusion
git clone https://www.github.com/Modern-Robotics/Fusion.git
npm cache clean -f 
npm install -g n 
n stable 
npm install forever -g 
pip install imutils 
pip uninstall Fusion -y
pip install /usr/Fusion/lib/Fusion-0.9.1.tar.gz
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
service mongodb start
service mongodb stop
service hostapd start 
service hostapd stop
service dnsmasq start
service dnsmasq stop 
# update-rc.d mongodb defaults
# update-rc.d hostapd defaults 
# update-rc.d dnsmasq defaults
# update-rc.d dhcpcd defaults
