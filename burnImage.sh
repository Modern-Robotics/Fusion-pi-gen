#!/bin/bash

# see if /deploy has any .img 
# if not unzip ...4GB
if [ ! -x 'deploy/*4GB.img' ] ; then
    unzip *4GB.zip
fi

# if sdb* is /dev 
umount /dev/sdb*

# dd if=*/deply/.img*
image=`ls deploy/*.img`
dd if=$image of=/dev/sdb bs=8192 &
