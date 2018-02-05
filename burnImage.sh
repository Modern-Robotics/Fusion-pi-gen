#!/bin/bash

cd deploy

# see if /deploy has any .img 
# if not unzip ...4GB

files=$(ls *4GB.img 2> /dev/null | wc -l)
if [ **"$files" != "0"** ]
then
#if [ -f '*4GB.img' ] ; then
    echo "already unzipped"
else
    unzip "*4GB.zip"
fi

# if sdb* is /dev 
umount /dev/sdb*

# dd if=*/deply/.img*
image=`ls *.img`
dd if=$image of=/dev/sdb bs=8192 status=progress
