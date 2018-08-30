#===============================================================================
# Common bash functions used by the pi-gen process
#
# 01-Aug-2018 <jwa> Added some more descriptive error output
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
# Function log() - sends string arg to console & logfile with timestamp
#
log (){
    echo -n "${fgRED}"
	date +"[%T] $@" | tee -a "${LOG_FILE}"
	echo -n "${fgNEU}"
} # // end of log() //
export -f log


#===============================================================================
# Function bootstrap() - 
#
bootstrap(){
    echo "$atBRT$fgCYN   ==> running bootstrap process...$atRST$fgNEU"
    local ARCH
    ARCH=$(dpkg --print-architecture)

    export http_proxy=${APT_PROXY}

    if [ "$ARCH" !=  "armhf" ]; then
        local BOOTSTRAP_CMD=qemu-debootstrap
    else
        local BOOTSTRAP_CMD=debootstrap
    fi

    capsh --drop=cap_setfcap -- -c "${BOOTSTRAP_CMD} --components=main,contrib,non-free \
        --arch armhf \
        --keyring "${STAGE_DIR}/files/raspberrypi.gpg" \
        $1 $2 $3" || rmdir "$2/debootstrap"
} # // end of bootstrap() //
export -f bootstrap


#===============================================================================
# Function copy_previous() - copies previous stage's workspace for next stage
#
copy_previous(){
    echo "$atBRT$fgCYN   ==> running copy_previous process...$atRST$fgNEU"
    if [ ! -d "${PREV_ROOTFS_DIR}" ]; then
        # <jwa> Let's add the offending path to the error output...
        echo "Previous stage rootfs (${PREV_ROOTFS_DIR}) not found"
        false
    fi
    mkdir -p "${ROOTFS_DIR}"
    rsync -aHAXx --exclude var/cache/apt/archives "${PREV_ROOTFS_DIR}/" "${ROOTFS_DIR}/"
} # // end of copy_previous() //
export -f copy_previous


#===============================================================================
# Function unmount() - unmounts all instances of filesystem
#
# The argument is compared to mount output and all mounts with 
unmount(){
	# If we have not been passed a name, use the pwd instead
    if [ -z "$1" ]; then
        DIR=$PWD
		DIRTEXT=$PWD
    else
        DIR=$1
		DIRTEXT="it"
    fi
	echo ">>> unmount(${1}) called:  ==> unmounting ${DIRTEXT}"
	
    while mount | grep -q "$DIR"; do
        local LOCS
        LOCS=$(mount | grep "$DIR" | cut -f 3 -d ' ' | sort -r)
		echo "--[ unmount targets ]------------------------------"
        for loc in $LOCS; do
			echo "  [ ${loc}"
            umount "$loc"
        done
		echo "--[ unmount complete ]-----------------------------"
    done
} # // end of unmount() //
export -f unmount


#===============================================================================
# Function unmount_image() - unmounts image of filesystem
#
unmount_image(){
	echo ">>> unmount_image called: unmounting(${1})"
    sync
    sleep 1
    local LOOP_DEVICES
    LOOP_DEVICES=$(losetup -j "${1}" | cut -f1 -d':')
	echo "    Active loop devices: ${LOOP_DEVICES}"
	
	# Go through the list of active loop devices, strip the path info with
	#   basename, and check the mount table for that device basename
    for LOOP_DEV in ${LOOP_DEVICES}; do
        if [ -n "${LOOP_DEV}" ]; then
            local MOUNTED_DIR
            MOUNTED_DIR=$(mount | grep "$(basename "${LOOP_DEV}")" | head -n 1 | cut -f 3 -d ' ')
            if [ -n "${MOUNTED_DIR}" ] && [ "${MOUNTED_DIR}" != "/" ]; then
				echo "    unmounting $(dirname ${MOUNTED_DIR})"
                unmount "$(dirname "${MOUNTED_DIR}")"
            fi
            sleep 1
            losetup -d "${LOOP_DEV}"
        fi
    done
} # // end of unmount_image() //
export -f unmount_image


#===============================================================================
# Function on_chroot() - mounts the target filesystem and executes argument 
#
on_chroot() {
	echo "${atBRT}${fgRED}${bgYEL} ==> CHROOT( "$*" ) on ${ROOTFS_DIR} <===${atNEU}${fgNEU}${bgNEU}"

    if ! mount | grep -q "$(realpath "${ROOTFS_DIR}"/proc)"; then
        mount -t proc proc "${ROOTFS_DIR}/proc"
    fi

    if ! mount | grep -q "$(realpath "${ROOTFS_DIR}"/dev)"; then
        mount --bind /dev "${ROOTFS_DIR}/dev"
    fi
    
    if ! mount | grep -q "$(realpath "${ROOTFS_DIR}"/dev/pts)"; then
        mount --bind /dev/pts "${ROOTFS_DIR}/dev/pts"
    fi

    if ! mount | grep -q "$(realpath "${ROOTFS_DIR}"/sys)"; then
        mount --bind /sys "${ROOTFS_DIR}/sys"
    fi

    capsh --drop=cap_setfcap "--chroot=${ROOTFS_DIR}/" -- "$@"
	
	echo "${atBRT}${fgRED}${bgYEL} ==> CHROOT Exits <===${atNEU}${fgNEU}${bgNEU}"
} # // end of on_chroot() //
export -f on_chroot


#===============================================================================
# Function update_issue() -  
#
update_issue() {
    local GIT_HASH
    GIT_HASH=$(git rev-parse HEAD)
    echo -e "Raspberry Pi reference ${IMG_DATE}\nGenerated using pi-gen, https://github.com/RPi-Distro/pi-gen, ${GIT_HASH}, ${1}" > "${ROOTFS_DIR}/etc/rpi-issue"
    echo ">>> Update_Issue:   Git Hash = ${GIT_HASH} <<<"
    cat ${ROOTFS_DIR}/etc/rpi-issue
    echo
    
} # // end of update_issue() //
export -f update_issue

