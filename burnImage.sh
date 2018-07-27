#!/bin/bash

# change to the deploy directory
cd deploy

# Check to see if *4GB.zip has been extracted
ls *.img
if [ $? != "0" ]
then
    unzip "*4GB.zip"    
else
    echo "already unzipped"
fi

# Test for which device is the usb key
# SDA ---------------------------------------------------------------
# udevadm info --query=all --name=sda | grep ID_BUS=usb
# if [ $? == "0" ]
# then
    # echo "USB on device sda, burning image..."
    # umount /dev/sda*
    # image=`ls *.img`
    # dd if=$image of=/dev/sda bs=8192 status=progress &
# else
    # echo "sda is not a usb device"
# fi

# SDB ---------------------------------------------------------------
udevadm info --query=all --name=sdb | grep ID_BUS=usb
if [ $? == "0" ]
then
    echo "USB on device sdb, burning image..."
    umount /dev/sdb*
    image=`ls *.img`
    dd if=$image of=/dev/sdb bs=8192 status=progress &
else
    echo "sdb is not a usb device"
fi

# SDC ---------------------------------------------------------------
udevadm info --query=all --name=sdc | grep ID_BUS=usb
if [ $? == "0" ]
then
    echo "USB on device sdc, burning image..."
    umount /dev/sdc*
    image=`ls *.img`
    dd if=$image of=/dev/sdc bs=8192 status=progress &
else
    echo "sdc is not a usb device"
fi

# SDD ---------------------------------------------------------------
udevadm info --query=all --name=sdd | grep ID_BUS=usb
if [ $? == "0" ]
then
    echo "USB on device sdd, burning image..."
    umount /dev/sdd*
    image=`ls *.img`
    dd if=$image of=/dev/sdd bs=8192 status=progress &
else
    echo "sdd is not a usb device"
fi

# SDE ---------------------------------------------------------------
udevadm info --query=all --name=sde | grep ID_BUS=usb
if [ $? == "0" ]
then
    echo "USB on device sde, burning image..."
    umount /dev/sde*
    image=`ls *.img`
    dd if=$image of=/dev/sde bs=8192 status=progress &
else
    echo "sde is not a usb device"
fi

# SDF ---------------------------------------------------------------
udevadm info --query=all --name=sdf | grep ID_BUS=usb
if [ $? == "0" ]
then
    echo "USB on device sdf, burning image..."
    umount /dev/sdf*
    image=`ls *.img`
    dd if=$image of=/dev/sdf bs=8192 status=progress &
else
    echo "sdf is not a usb device"
fi

# SDG ---------------------------------------------------------------
udevadm info --query=all --name=sdg | grep ID_BUS=usb
if [ $? == "0" ]
then
    echo "USB on device sdg, burning image..."
    umount /dev/sdg*
    image=`ls *.img`
    dd if=$image of=/dev/sdg bs=8192 status=progress &
else
    echo "sdg is not a usb device"
fi

# SDH ---------------------------------------------------------------
udevadm info --query=all --name=sdh | grep ID_BUS=usb
if [ $? == "0" ]
then
    echo "USB on device sdh, burning image..."
    umount /dev/sdh*
    image=`ls *.img`
    dd if=$image of=/dev/sdh bs=8192 status=progress &
else
    echo "sdh is not a usb device"
fi

# SDI ---------------------------------------------------------------
udevadm info --query=all --name=sdi | grep ID_BUS=usb
if [ $? == "0" ]
then
    echo "USB on device sdi, burning image..."
    umount /dev/sdi*
    image=`ls *.img`
    dd if=$image of=/dev/sdi bs=8192 status=progress &
else
    echo "sdi is not a usb device"
fi