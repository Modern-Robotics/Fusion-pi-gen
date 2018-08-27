#!/bin/bash -e -v
#===============================================================================
# distroinstall.sh - Script that fetches compiled FusionServer from repo and
#   installs it.  It also configures and enables the various I/O devices on
#   the Raspberry Pi.
#-------------------------------------------------------------------------------
# 27-Aug-2018 <jwa> - Moved imult and numpy to stage 4//03-python-pkgs 
#		in the interest of speed.  Compiling numpy takes a long time!
# 24-Aug-2018 <jwa> - Added Google DNS @8.8.8.8 to the /etc/resolv.conf file
#		to maintain DNS Service while perfoming the distro install process.
# 20-Aug-2018 <jwa> - Added progress messages and revision history
#
#===============================================================================

#-<jwa>-----------------------------------------------
# Let's include a little color into the output using
# VT100 (TTY) Substitutions
ESC=
COL60=$ESC[60G

# Attributes    ;    Foregrounds     ;    Backgrounds
atRST=$ESC[0m   ;   fgBLK=$ESC[30m   ;   bgBLK=$ESC[40m
atBRT=$ESC[1m   ;   fgRED=$ESC[31m   ;   bgRED=$ESC[41m
atDIM=$ESC[2m   ;   fgGRN=$ESC[32m   ;   bgGRN=$ESC[42m
atUN1=$ESC[3m   ;   fgYEL=$ESC[33m   ;   bgYEL=$ESC[43m
atUND=$ESC[4m   ;   fgBLU=$ESC[34m   ;   bgBLU=$ESC[44m
atBLK=$ESC[5m   ;   fgMAG=$ESC[35m   ;   bgMAG=$ESC[45m
atUN2=$ESC[6m   ;   fgCYN=$ESC[36m   ;   bgCYN=$ESC[46m
atREV=$ESC[7m   ;   fgWHT=$ESC[37m   ;   bgWHT=$ESC[47m
atHID=$ESC[8m   ;   fgNEU=$ESC[39m   ;   bgNEU=$ESC[49m


#===============================================================================
# Put a name server into /etc/resolv.conf so we can perform URL look-ups
#
# echo "nameserever 8.8.8.8" >> /etc/resolv.conf
#

#===============================================================================
# Default argument values
#
ADDRESS="http://www.github.com/Modern-Robotics/Fusion.git"
MAIN_DIR="/usr/Fusion"
CMDLINE="/boot/cmdline.txt"

echo "$atBRT$fgCYN***** DistroInstaller Active *****$atRST$fgNEU"

#===============================================================================
# Set the Fusion commit number to build, or leave blank to build the most
#   recent Fusion Release (ie: the HEAD)
#
# COMMIT=$(sudo git rev-list --tags --max-count=1)
COMMIT=


#===============================================================================
# Set boot to enable uart
#
echo
echo "$atBRT$fgGRN===[ Checking UART ]==========$atRST$fgNEU"
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
    echo "UART enable added to configuration"
fi

if [[ $? != 0 ]]; then 
    echo "ERROR configuring UART, aborting"
	exit 6
fi


#===============================================================================
# Set uart parameters
#
echo
echo "$atBRT$fgGRN===[ Setting UART Parameters ]==========$atRST$fgNEU"
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


#===============================================================================
# Set boot to enable i2c
#
echo
echo "$atBRT$fgGRN===[ Checking I2C Interface ]==========$atRST$fgNEU"
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
    echo "I2C enable added to configuration"
fi


#===============================================================================
# Set boot to avoid warnings
#
echo
echo "$atBRT$fgGRN===[ Checking Boot Warning Messages ]==========$atRST$fgNEU"
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
    echo "Warnings disabled in configuration"
fi


#===============================================================================
# Update module file with kernel for i2c-dev
#
echo
echo "$atBRT$fgGRN===[ Checking I2C-DEV Kernel Module ]==========$atRST$fgNEU"
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


#===============================================================================
# Update module file with kernel for i2c-bcm2708
#
echo
echo "$atBRT$fgGRN===[ Checking I2C-BCM2708 Kernel Module ]==========$atRST$fgNEU"
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


#===============================================================================
# Update blacklist to turn off bluetooth
#
echo
echo "$atBRT$fgGRN===[ Updating Blacklist ]==========$atRST$fgNEU"
echo "blacklist btbcm" | tee -a /etc/modprobe.d/raspi-blacklist.conf
echo "blacklist hci_uart" | tee -a /etc/modprobe.d/raspi-blacklist.conf


#===============================================================================
# Clone FusionOS Repository
#
echo
echo
echo "$atBRT$fgGRN+++[ Cloning FusionOS Repository from ${ADDRESS} ]+++++$atRST$fgNEU"
cd /usr 
if [ -d Fusion ]; then
	echo "Removing existing Fusion Branch"
	rm -r Fusion
fi

echo "Checking Name Servers:"
cat /etc/resolv.conf

git clone http://www.github.com/Modern-Robotics/Fusion.git
cd ${MAIN_DIR}
#git reset --hard $COMMIT 

#===============================================================================
# Install the correct version of npm and run time environment
#
echo
echo "$atBRT$fgGRN+++[ Installing npm version 9.10.1 ]+++++$atRST$fgNEU"
npm cache clean -f 
npm install -g n 
n 9.10.1 #n stable 

#===============================================================================
# Install various tools used by the FusionOS
#
echo
echo "$atBRT$fgGRN+++[ Installing Tools ]+++++$atRST$fgNEU"
echo "$atBRT$fgGRN---< npm install forever >---$atRST$fgNEU"
npm install forever -g 

# echo "$atBRT$fgGRN---< pip install imutils >---$atRST$fgNEU"
# pip install imutils 
# 
# echo "$atBRT$fgGRN---< pip install numpy >---$atRST$fgNEU"
# pip install numpy 
#
# echo "$atBRT$fgGRN---< pip install --upgrade numpy >---$atRST$fgNEU"
# pip install --upgrade numpy

#===============================================================================
# Install Fusion Interface Board Driver and Required Libraries & Packages
#
echo
echo "$atBRT$fgGRN+++[ Installing Fusion Interface Libraries & Packages ]+++++$atRST$fgNEU"
echo "$atBRT$fgBLU---< pip uninstall Fusion >---$atRST$fgNEU"
pip uninstall Fusion -y

echo "$atBRT$fgBLU---< pip uninstall remi >---$atRST$fgNEU"
pip uninstall remi -y

echo "$atBRT$fgBLU---< pip uninstall pylibftdi >---$atRST$fgNEU"
pip uninstall pylibftdi -y


echo "$atBRT$fgGRN---< pip install ${MAIN_DIR}/lib/*.tar.gz >---$atRST$fgNEU"
pip install $MAIN_DIR/lib/*.tar.gz

echo "$atBRT$fgGRN---< dpkg -i ${MAIN_DIR}/lib/*.deb >---$atRST$fgNEU"
dpkg -i $MAIN_DIR/lib/*.deb


#===============================================================================
# Copy and prepare various system config files from FusionOS Repository
#
echo
echo "$atBRT$fgGRN===[ Copying FusionOS System Config Files ]=====$atRST$fgNEU"
echo "$atBRT$fgGRN===[ Copying FusionOS System Config Files ]=====$atRST$fgNEU"
echo "$atBRT$fgBLU---< Copying /etc/network/interfaces >---$atRST$fgNEU"
cp /usr/Fusion/etc/interfaces /etc/network/interfaces 
chmod 644 /etc/network/interfaces 

echo "$atBRT$fgBLU---< Copying /etc/dhcpcd.conf >---$atRST$fgNEU"
cp /usr/Fusion/etc/dhcpcd.conf /etc/dhcpcd.conf 
chmod 644 /etc/dhcpcd.conf 

echo "$atBRT$fgBLU---< Copying /etc/hostapd/hostapd.conf >---$atRST$fgNEU"
cp /usr/Fusion/etc/hostapd.conf /etc/hostapd/hostapd.conf 
chmod 644 /etc/hostapd/hostapd.conf 

echo "$atBRT$fgBLU---< Copying /etc/default/hostapd >---$atRST$fgNEU"
cp /usr/Fusion/etc/hostapd /etc/default/hostapd 
chmod 644 /etc/default/hostapd

echo "$atBRT$fgBLU---< Copying /etc/dnsmasq.conf >---$atRST$fgNEU"
cp /usr/Fusion/etc/dnsmasq.conf /etc/dnsmasq.conf 
chmod 644 /etc/dnsmasq.conf 

echo "$atBRT$fgBLU---< Setting SSID via Python Script >---$atRST$fgNEU"
python /usr/Fusion/etc/ssid_set.py 

echo "$atBRT$fgBLU---< Copying /etc/rc.local >---$atRST$fgNEU"
cp /usr/Fusion/etc/rc.local /etc/rc.local 
chmod 755 /etc/rc.local 

echo "$atBRT$fgBLU---< Copying /etc/default/keyboard >---$atRST$fgNEU"
cp /usr/Fusion/etc/keyboard /etc/default/keyboard
chmod 644 /etc/default/keyboard

echo "$atBRT$fgBLU---< Copying /root/.vnc/config.d/vncserver-x11 >---$atRST$fgNEU"
cp /usr/Fusion/etc/vncserver-x11 /root/.vnc/config.d/vncserver-x11
chmod 700 /root/.vnc/config.d/vncserver-x11


#===============================================================================
# Enable services
#
echo
echo "$atBRT$fgGRN===[ Enabling Services ]=====$atRST$fgNEU"
echo "$atBRT$fgBLU---< Processing ssh >---$atRST$fgNEU"
update-rc.d ssh enable 
service ssh stop

echo "$atBRT$fgBLU---< Processing mongodb >---$atRST$fgNEU"
update-rc.d mongodb enable 
service mongodb stop

echo "$atBRT$fgBLU---< Processing hostapd >---$atRST$fgNEU"
update-rc.d hostapd enable 
service hostapd stop 

echo "$atBRT$fgBLU---< Processing dnsmasq >---$atRST$fgNEU"
update-rc.d dnsmasq enable 
service dnsmasq stop 

echo "$atBRT$fgBLU---< Processing vncserver-x11 daemon >---$atRST$fgNEU"
systemctl enable vncserver-x11-serviced.service
systemctl stop vncserver-x11-serviced.service


#===============================================================================
# Create symbolic link for videodev.h used by mjpg-streamer
#
echo
echo "$atBRT$fgGRN===[ Creating Symbolic Links to Header Files ]=====$atRST$fgNEU"
ln -s /usr/include/linux/videodev2.h /usr/include/linux/videodev.h


#===============================================================================
# Add support for credentials in url 
# cd /usr/Fusion/FusionServer/Build
# npm install --production

echo
echo "$atBRT$fgCYN***** DistroInstaller Finished *****$atRST$fgNEU"

