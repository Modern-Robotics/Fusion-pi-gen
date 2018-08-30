#!/bin/bash -e
# ==============================================================================
# Finalization Process for export_image stage of FusionOS Build
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
echo "$atBRT$fgCYN***** Beginning Finalization Phase *****$atRST$fgNEU"


IMG_FILE="${STAGE_WORK_DIR}/${IMG_DATE}-${IMG_NAME}${IMG_SUFFIX}.img"

echo "$atBRT$fgGRN===< Scanning target /usr/share/doc for duplicates >===$atRST$fgNEU"

on_chroot << EOF
/etc/init.d/fake-hwclock stop
hardlink -t /usr/share/doc
EOF


echo "$atBRT$fgGRN===< Performing General Housekeeping Tasks >===$atRST$fgNEU"

if [ -d ${ROOTFS_DIR}/home/pi/.config ]; then
	chmod 700 ${ROOTFS_DIR}/home/pi/.config
fi

rm -f ${ROOTFS_DIR}/etc/apt/apt.conf.d/51cache
rm -f ${ROOTFS_DIR}/usr/sbin/policy-rc.d
rm -f ${ROOTFS_DIR}/usr/bin/qemu-arm-static

if [ -e ${ROOTFS_DIR}/etc/ld.so.preload.disabled ]; then
    mv ${ROOTFS_DIR}/etc/ld.so.preload.disabled ${ROOTFS_DIR}/etc/ld.so.preload
fi

rm -f ${ROOTFS_DIR}/etc/apt/sources.list~
rm -f ${ROOTFS_DIR}/etc/apt/trusted.gpg~

rm -f ${ROOTFS_DIR}/etc/passwd-
rm -f ${ROOTFS_DIR}/etc/group-
rm -f ${ROOTFS_DIR}/etc/shadow-
rm -f ${ROOTFS_DIR}/etc/gshadow-

rm -f ${ROOTFS_DIR}/var/cache/debconf/*-old
rm -f ${ROOTFS_DIR}/var/lib/dpkg/*-old

rm -f ${ROOTFS_DIR}/usr/share/icons/*/icon-theme.cache

rm -f ${ROOTFS_DIR}/var/lib/dbus/machine-id

true > ${ROOTFS_DIR}/etc/machine-id

ln -nsf /proc/mounts ${ROOTFS_DIR}/etc/mtab

for _FILE in $(find ${ROOTFS_DIR}/var/log/ -type f); do
	true > ${_FILE}
done

rm -f "${ROOTFS_DIR}/root/.vnc/private.key"


echo
echo "$atBRT$fgGRN===< Preparing to compress the image >===$atRST$fgNEU"


echo "$atBRT$fgGRN===[ WorkSpace Information ]===$atRST$fgNEU"
echo "$atBRT$fgGRN===[ Image File:    ${IMG_FILE} ]===$atRST$fgNEU"
echo "$atBRT$fgGRN===[ RootFS Dir:    ${ROOTFS_DIR} ]===$atRST$fgNEU"
echo "$atBRT$fgGRN===[ Export_RootFS: ${EXPORT_ROOTFS_DIR} ]===$atRST$fgNEU"
echo "$atBRT$fgGRN===[ Export Dir:    ${EXPORT_DIR} ]===$atRST$fgNEU"
echo
echo


# Get the Repo Hash (for something) & include it in a file for tracking purposes
# Install the issue info and the license text file.
#
update_issue $(basename ${EXPORT_DIR})
install -m 644 ${ROOTFS_DIR}/etc/rpi-issue ${ROOTFS_DIR}/boot/issue.txt
install files/LICENSE.oracle ${ROOTFS_DIR}/boot/


ROOT_DEV=$(mount | grep "${ROOTFS_DIR} " | cut -f1 -d' ')
echo "Current Root_dev = ${ROOT_DEV}"


unmount ${ROOTFS_DIR}

echo "$atBRT$fgGRN===[ Zeroing free space for better compression ]===$atRST$fgNEU"
echo "$atRST$fgGRN===[ Blocks Modified, Blocks Free, Total Blocks ]===$atRST$fgNEU"
zerofree -v ${ROOT_DEV}
echo


unmount_image ${IMG_FILE}

mkdir -p ${DEPLOY_DIR}

rm -f ${DEPLOY_DIR}/image_${IMG_DATE}-${IMG_NAME}${IMG_SUFFIX}.zip

echo "$atBRT$fgGRN===[ Preparing to generate .zip file ]===$atRST$fgNEU"
echo "$atBRT$fgGRN---[ zip ${DEPLOY_DIR}/image_${IMG_DATE}-${IMG_NAME}${IMG_SUFFIX}.zip ${IMG_FILE} ]---$atRST$fgNEU"
pushd ${STAGE_WORK_DIR} > /dev/null

##### <jwa> #####
##### Let's skip making the zip file right now -- it takes so long!
##### zip ${DEPLOY_DIR}/image_${IMG_DATE}-${IMG_NAME}${IMG_SUFFIX}.zip $(basename ${IMG_FILE})

popd > /dev/null
