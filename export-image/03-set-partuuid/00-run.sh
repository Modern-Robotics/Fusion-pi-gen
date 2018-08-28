#!/bin/bash -e
# ==============================================================================
# Set-Partition UUID Process for export_image stage of FusionOS Build
# ==============================================================================
# Modification History:
#   28-Aug-2018 <jwa> - Added some diagnostic and progress output to help 
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


#---[ Beginning of allow-rerun processing ]-----------------------------------------------
echo "$atBRT$fgCYN***** Setting UUIDs for our image *****$atRST$fgNEU"


IMG_FILE="${STAGE_WORK_DIR}/${IMG_DATE}-${IMG_NAME}${IMG_SUFFIX}.img"

IMGID="$(fdisk -l ${IMG_FILE} | sed -n 's/Disk identifier: 0x\([^ ]*\)/\1/p')"

BOOT_PARTUUID="${IMGID}-01"
ROOT_PARTUUID="${IMGID}-02"

echo "$atBRT$fgGRN===[ WorkSpace Information ]===$atRST$fgNEU"
echo "$atBRT$fgGRN===[ Image File:    ${IMG_FILE} ]===$atRST$fgNEU"
echo "$atBRT$fgGRN===[ Image ID:      ${IMGID} ]===$atRST$fgNEU"
echo
echo "$atBRT$fgGRN===[ Boot Partition UUID: ${BOOT_PARTUUID} ]===$atRST$fgNEU"
echo "$atBRT$fgGRN===[ Root Partition UUID: ${ROOT_PARTUUID} ]===$atRST$fgNEU"
echo


echo "$atBRT$fgGRN===[ updating ${ROOTFS_DIR}/etc/fstab with our new UUIDs ]===$atRST$fgNEU"
sed -i "s/BOOTDEV/PARTUUID=${BOOT_PARTUUID}/" ${ROOTFS_DIR}/etc/fstab
sed -i "s/ROOTDEV/PARTUUID=${ROOT_PARTUUID}/" ${ROOTFS_DIR}/etc/fstab
echo "$atRST$fgGRN"
cat ${ROOTFS_DIR}/etc/fstab
echo "$atRST$fgNEU"
echo

echo "$atBRT$fgGRN===[ updating ${ROOTFS_DIR}/boot/cmdline.txt with our new UUIDs ]===$atRST$fgNEU"
sed -i "s/ROOTDEV/PARTUUID=${ROOT_PARTUUID}/" ${ROOTFS_DIR}/boot/cmdline.txt
echo "$atRST$fgGRN"
cat ${ROOTFS_DIR}/boot/cmdline.txt
echo "$atRST$fgNEU"
echo
