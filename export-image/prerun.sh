#!/bin/bash -e
# ==============================================================================
# PreRun Process for export_image stage of FusionOS Build
# ==============================================================================
# Modification History:
#   28-Aug-2018 <jwa> - Made sure that nothing with our image name is mounted
#       Before beginning. Added some diagnostic and progress output to help 
#       follow the process.
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



#---[ Beginning of prerun.sh ]-----------------------------------------------
echo "$atBRT$fgCYN***** EXPORT_IMAGE PRERUN ACTIVE *****$atRST$fgNEU"

#
# If our image name shows up in the mount output, something is still mounted.
# We may need to unmount it before proceeding, HOWEVER...
# ... it does look like the builder is supposed to do that shortly.
# mount | grep ${IMG_DATE} | awk  '{ print "umount " $3 }' | bash


IMG_FILE="${STAGE_WORK_DIR}/${IMG_DATE}-${IMG_NAME}${IMG_SUFFIX}.img"

unmount_image ${IMG_FILE}

rm -f ${IMG_FILE}

rm -rf ${ROOTFS_DIR}

mkdir -p ${ROOTFS_DIR}

echo "$atBRT$fgBLU===[ Computing Partition Sizes ]===$atRST$fgNEU"
BOOT_SIZE=$(du --apparent-size -s ${EXPORT_ROOTFS_DIR}/boot --block-size=1 | cut -f 1)
TOTAL_SIZE=$(du --apparent-size -s ${EXPORT_ROOTFS_DIR} --exclude var/cache/apt/archives --block-size=1 | cut -f 1)

IMG_SIZE=$((BOOT_SIZE + TOTAL_SIZE + (800 * 1024 * 1024)))

echo "$atBRT$fgGRN===[ WorkSpace Information ]===$atRST$fgNEU"
echo "$atBRT$fgGRN===[ Image File:    ${IMG_FILE} ]===$atRST$fgNEU"
echo "$atBRT$fgGRN===[ RootFS:        ${ROOTFS_DIR} ]===$atRST$fgNEU"
echo "$atBRT$fgGRN===[ Export_RootFS: ${EXPORT_ROOTFS_DIR} ]===$atRST$fgNEU"
echo
echo "$atBRT$fgGRN===[ Boot Size:     ${BOOT_SIZE} ]===$atRST$fgNEU"
echo "$atBRT$fgGRN===[ Total Size:    ${TOTAL_SIZE} ]===$atRST$fgNEU"
echo "$atBRT$fgGRN===[ Image Size:    ${IMG_SIZE} ]===$atRST$fgNEU"
echo
echo

echo "$atBRT$fgBLU===[ Creating ${IMG_SIZE} Byte Image file ${IMG_FILE} and Running fdisk to partition ]===$atRST$fgNEU"
# Um..., forget that it says 'truncate', we're using it to set the file size...
truncate -s ${IMG_SIZE} ${IMG_FILE}

fdisk -H 255 -S 63 ${IMG_FILE} <<EOF
p
o
n


8192
+$((BOOT_SIZE * 2 /512))
p
t
c
n


8192


p
w
EOF
echo "$atBRT$fgBLU===[ fdisk Complete ]===$atRST$fgNEU"


PARTED_OUT=$(parted -s ${IMG_FILE} unit b print)
BOOT_OFFSET=$(echo "$PARTED_OUT" | grep -e '^ 1'| xargs echo -n | cut -d" " -f 2 | tr -d B)
BOOT_LENGTH=$(echo "$PARTED_OUT" | grep -e '^ 1'| xargs echo -n | cut -d" " -f 4 | tr -d B)

ROOT_OFFSET=$(echo "$PARTED_OUT" | grep -e '^ 2'| xargs echo -n | cut -d" " -f 2 | tr -d B)
ROOT_LENGTH=$(echo "$PARTED_OUT" | grep -e '^ 2'| xargs echo -n | cut -d" " -f 4 | tr -d B)

# Prepare the Loop Devices
BOOT_DEV=$(losetup --show -f -o ${BOOT_OFFSET} --sizelimit ${BOOT_LENGTH} ${IMG_FILE})
ROOT_DEV=$(losetup --show -f -o ${ROOT_OFFSET} --sizelimit ${ROOT_LENGTH} ${IMG_FILE})
echo
echo "$atBRT$fgGRN===[ Output from Parted ]===$atRST$fgNEU"
echo "$fgGRN${PARTED_OUT}$atRST$fgNEU"
echo 
echo "$atBRT$fgGRN===[ Image Parameters ]===$atRST$fgNEU"
echo "$atBRT$fgGRN===[ Boot_Device = ${BOOT_DEV}  -  /boot: offset  ${BOOT_OFFSET},  length   ${BOOT_LENGTH} ]===$atRST$fgNEU"
echo "$atBRT$fgGRN===[ Root_Device = ${ROOT_DEV}  -  /    : offset ${ROOT_OFFSET},  length ${ROOT_LENGTH} ]===$atRST$fgNEU"
echo 
echo "$atRST$fgGRN ---------- Loop Device Table ----------$atRST$fgNEU"
losetup -a 
echo
echo


echo "$atBRT$fgBLU===[ Making DOS Filesystem on ${BOOT_DEV} ]===$atRST$fgNEU"
mkdosfs -n boot -F 32 -v $BOOT_DEV > /dev/null

echo
echo "$atBRT$fgBLU===[ Making Ext4 Filesystem on ${ROOT_DEV} ]===$atRST$fgNEU"
mkfs.ext4 -O ^metadata_csum,^huge_file $ROOT_DEV > /dev/null

echo
echo "$atBRT$fgBLU===[ Mounting ${ROOT_DEV} on ${ROOTFS_DIR}/boot ]===$atRST$fgNEU"
mount -v $ROOT_DEV ${ROOTFS_DIR} -t ext4
mkdir -p ${ROOTFS_DIR}/boot

echo
echo "$atBRT$fgBLU===[ Mounting ${BOOT_DEV} on ${ROOTFS_DIR}/boot ]===$atRST$fgNEU"
mount -v $BOOT_DEV ${ROOTFS_DIR}/boot -t vfat


echo
echo "$atBRT$fgBLU===[ Copying Root Filesystem to Export ]===$atRST$fgNEU"
echo "$atRST$fgBLU===[      Source: ${EXPORT_ROOTFS_DIR} ]===$atRST$fgNEU"
echo "$atRST$fgBLU===[ Destination: ${ROOTFS_DIR} ]===$atRST$fgNEU"
rsync -aHAXx --exclude var/cache/apt/archives ${EXPORT_ROOTFS_DIR}/ ${ROOTFS_DIR}/

echo "Name Resolution..."
cat /builds/MakeJessie/work/RC_1.1-JWA_Jessie/export-image/rootfs/etc/resolv.conf

	echo
	echo "${fgGRN}Checking DNS for Source ${EXPORT_ROOTFS_DIR}"
	cat  ${EXPORT_ROOTFS_DIR}/etc/resolv.conf
	echo "${fgNEU}"
	echo 
	echo "${fgBLU}Checking DNS for Destination ${ROOTFS_DIR}"
	cat  ${ROOTFS_DIR}/etc/resolv.conf
	echo "${fgNEU}"
	echo 


echo "$atBRT$fgCYN***** EXPORT_IMAGE PRERUN COMPLETE *****$atRST$fgNEU"

