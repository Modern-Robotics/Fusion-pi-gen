#===============================================================================
# Common bash functions used by the pi-gen process
#
# 01-Aug-2018 <jwa> Added some more descriptive error output
#
#===============================================================================


#===============================================================================
# Function log() - sends string arg to console & logfile with timestamp
#
log (){
	date +"[%T] $@" | tee -a "${LOG_FILE}"
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
# Function unmount() - unmounts filesystem
#
unmount(){
	if [ -z "$1" ]; then
		DIR=$PWD
	else
		DIR=$1
	fi

	while mount | grep -q "$DIR"; do
		local LOCS
		LOCS=$(mount | grep "$DIR" | cut -f 3 -d ' ' | sort -r)
		for loc in $LOCS; do
			umount "$loc"
		done
	done
} # // end of unmount() //
export -f unmount


#===============================================================================
# Function unmount_image() - unmounts image of filesystem
#
unmount_image(){
	sync
	sleep 1
	local LOOP_DEVICES
	LOOP_DEVICES=$(losetup -j "${1}" | cut -f1 -d':')
	for LOOP_DEV in ${LOOP_DEVICES}; do
		if [ -n "${LOOP_DEV}" ]; then
			local MOUNTED_DIR
			MOUNTED_DIR=$(mount | grep "$(basename "${LOOP_DEV}")" | head -n 1 | cut -f 3 -d ' ')
			if [ -n "${MOUNTED_DIR}" ] && [ "${MOUNTED_DIR}" != "/" ]; then
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
} # // end of on_chroot() //
export -f on_chroot


#===============================================================================
# Function update_issue() -  
#
update_issue() {
	local GIT_HASH
	GIT_HASH=$(git rev-parse HEAD)
	echo -e "Raspberry Pi reference ${IMG_DATE}\nGenerated using pi-gen, https://github.com/RPi-Distro/pi-gen, ${GIT_HASH}, ${1}" > "${ROOTFS_DIR}/etc/rpi-issue"
} # // end of update_issue() //
export -f update_issue

