#!/bin/bash -e

# ------------------------------------------------------------------------------
# Build procedure for Fusion-based Jessie Debian -------------------------------
# ------------------------------------------------------------------------------
# Modification History:
#   16-Aug-2018 <jwa> - Added additional comments and descriptive output; added
#		code to make sure all .sh files in the source path have their execute
#		bits set.  (files transferred from windows machines will lose the bit)
#
#   10-Aug-2018 <jwa> - Added command line argument (ie: $1) containing build
#		name of Image that we are continuing development work with.  This is
#		necessary since the build.sh script attempts to generate an image name
#		based on the current date.
#
#   09-Aug-2018 <jwa> - Added additional descriptive console output to help the 
#		user keep track of what stage of the process we are running.
#-------------------------------------------------------------------------------

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

#==============================================================================
# Local Function Definitions
#==============================================================================

#---[ gap - adds a gap in the output ]-----------------
#
gap() {
   echo 
   echo
   echo
} #---[ end gap() ]------------------------ 


#---[ run_sub_stage - processes a sub-stage component of the build process ]----
#
run_sub_stage()
{
	echo "$fgRED=============================================================================="
	echo "   Beginning Sub-Stage ${SUB_STAGE_DIR}  $fgNEU"
	log "Begin ${SUB_STAGE_DIR}"
	pushd ${SUB_STAGE_DIR} > /dev/null
	for i in {00..99}; do
		if [ -f ${i}-debconf ]; then
			log "Begin ${SUB_STAGE_DIR}/${i}-debconf"
			on_chroot << EOF
debconf-set-selections <<SELEOF
`cat ${i}-debconf`
SELEOF
EOF
		log "End ${SUB_STAGE_DIR}/${i}-debconf"
		fi
		if [ -f ${i}-packages-nr ]; then
			log "Begin ${SUB_STAGE_DIR}/${i}-packages-nr"
			PACKAGES="$(sed -f "${SCRIPT_DIR}/remove-comments.sed" < ${i}-packages-nr)"
			if [ -n "$PACKAGES" ]; then
				on_chroot << EOF
apt-get install --no-install-recommends -y $PACKAGES
EOF
			fi
			log "End ${SUB_STAGE_DIR}/${i}-packages-nr"
		fi
		if [ -f ${i}-packages ]; then
			log "Begin ${SUB_STAGE_DIR}/${i}-packages"
			PACKAGES="$(sed -f "${SCRIPT_DIR}/remove-comments.sed" < ${i}-packages)"
			if [ -n "$PACKAGES" ]; then
				on_chroot << EOF
apt-get install -y $PACKAGES
EOF
			fi
			log "End ${SUB_STAGE_DIR}/${i}-packages"
		fi
		if [ -d ${i}-patches ]; then
			log "Begin ${SUB_STAGE_DIR}/${i}-patches"
			pushd ${STAGE_WORK_DIR} > /dev/null
			if [ "${CLEAN}" = "1" ]; then
				rm -rf .pc
				rm -rf *-pc
			fi
			QUILT_PATCHES=${SUB_STAGE_DIR}/${i}-patches
			SUB_STAGE_QUILT_PATCH_DIR="$(basename $SUB_STAGE_DIR)-pc"
			mkdir -p $SUB_STAGE_QUILT_PATCH_DIR
			ln -snf $SUB_STAGE_QUILT_PATCH_DIR .pc
			if [ -e ${SUB_STAGE_DIR}/${i}-patches/EDIT ]; then
				echo "Dropping into bash to edit patches..."
				bash
			fi
			quilt upgrade
			RC=0
			quilt push -a || RC=$?
			case "$RC" in
				0|2)
					;;
				*)
					false
					;;
			esac
			popd > /dev/null
			log "End ${SUB_STAGE_DIR}/${i}-patches"
		fi
		if [ -x ${i}-run.sh ]; then
			log "Begin ${SUB_STAGE_DIR}/${i}-run.sh"
			./${i}-run.sh
			log "End ${SUB_STAGE_DIR}/${i}-run.sh"
		fi
		if [ -f ${i}-run-chroot.sh ]; then
			log "Begin ${SUB_STAGE_DIR}/${i}-run-chroot.sh"
			on_chroot < ${i}-run-chroot.sh
			log "End ${SUB_STAGE_DIR}/${i}-run-chroot.sh"
		fi
	done
	popd > /dev/null
	log "End ${SUB_STAGE_DIR}"
	echo "$fgRED   Completed Sub-Stage ${SUB_STAGE_DIR}"
	echo "==============================================================================$fgNEU"
	echo
} #---[ end of run_sub_stage ]--------------------------------------------------


#---[ run_stage - processes a full stage component of the build process ]-------
#
run_stage(){
	echo "$atBRT$fgBLU=====( ( ( ( ( STARTING STAGE ${STAGE_DIR}     ) ) ) ) )=====$atRST$fgNEU"
	log "Begin ${STAGE_DIR}"
	STAGE=$(basename ${STAGE_DIR})
	pushd ${STAGE_DIR} > /dev/null
	unmount ${WORK_DIR}/${STAGE}
	STAGE_WORK_DIR=${WORK_DIR}/${STAGE}
	ROOTFS_DIR=${STAGE_WORK_DIR}/rootfs
	if [ -f ${STAGE_DIR}/EXPORT_IMAGE ]; then
		EXPORT_DIRS="${EXPORT_DIRS} ${STAGE_DIR}"
	fi
	if [ ! -f SKIP ]; then
		if [ "${CLEAN}" = "1" ]; then
			if [ -d ${ROOTFS_DIR} ]; then
				rm -rf ${ROOTFS_DIR}
			fi
		fi
		if [ -x prerun.sh ]; then
			log "Begin ${STAGE_DIR}/prerun.sh"
			./prerun.sh
			log "End ${STAGE_DIR}/prerun.sh"
		fi
		for SUB_STAGE_DIR in ${STAGE_DIR}/*; do
			if [ -d ${SUB_STAGE_DIR} ] &&
			   [ ! -f ${SUB_STAGE_DIR}/SKIP ]; then
				run_sub_stage
			fi
		done
	fi
	unmount ${WORK_DIR}/${STAGE}
	PREV_STAGE=${STAGE}
	PREV_STAGE_DIR=${STAGE_DIR}
	PREV_ROOTFS_DIR=${ROOTFS_DIR}
	popd > /dev/null
	log "End ${STAGE_DIR}"
	echo "$atBRT$fgBLU=====( ( ( ( ( FINISHING STAGE ${STAGE_DIR}     ) ) ) ) )=====$atRST$fgNEU"
	gap
} #---[ end of run_stage ]------------------------------------------------------


#=======================================
# Start of Mainline Script
#=======================================
#
echo "$fgYEL$bgRED================================================================================="
echo "===== MakeJessie Script Starting                                            ====="
echo "=================================================================================$fgNEU$bgNEU"

if [ "$(id -u)" != "0" ]; then
	echo "Please run as root" 1>&2
	exit 1
fi

if [ -f config ]; then
	source config
fi

if [ -z "${IMG_NAME}" ]; then
	echo "IMG_NAME not set" 1>&2
	exit 1
fi

# See if we were passed the date to use as the IMG_DATE so that we can continue work on a 
# Previous build...
echo -e -n "\n\nChecking for date on command line..."
if [ $# == 0 ]; then
	echo -e "Using new date\n\n"
	export IMG_DATE=${IMG_DATE:-"$(date +%Y-%m-%d)"}
else
	echo -e "Using old date $1\n\n"
	export IMG_DATE=$1
fi


export BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPT_DIR="${BASE_DIR}/scripts"
export WORK_DIR=${WORK_DIR:-"${BASE_DIR}/work/${IMG_DATE}-${IMG_NAME}"}
export DEPLOY_DIR=${DEPLOY_DIR:-"${BASE_DIR}/deploy"}
export LOG_FILE="${WORK_DIR}/build.log"

export CLEAN
export IMG_NAME
export APT_PROXY

export STAGE
export STAGE_DIR
export STAGE_WORK_DIR
export PREV_STAGE
export PREV_STAGE_DIR
export ROOTFS_DIR
export PREV_ROOTFS_DIR
export IMG_SUFFIX
export NOOBS_NAME
export NOOBS_DESCRIPTION
export EXPORT_DIR
export EXPORT_ROOTFS_DIR

export QUILT_PATCHES
export QUILT_NO_DIFF_INDEX=1
export QUILT_NO_DIFF_TIMESTAMPS=1
export QUILT_REFRESH_ARGS="-p ab"


# Make sure the execute bit is set on all .sh files in this branch
echo "...checking that scripts are executable..."
find ${BASE_DIR} -iname "*.sh" -exec chmod +x -v {} \;
echo "...done..."
gap


source ${SCRIPT_DIR}/common
source ${SCRIPT_DIR}/dependencies_check


dependencies_check ${BASE_DIR}/depends

mkdir -p ${WORK_DIR}
log "Begin ${BASE_DIR}"

for STAGE_DIR in ${BASE_DIR}/stage*; do
	run_stage
done

CLEAN=1
for EXPORT_DIR in ${EXPORT_DIRS}; do
	STAGE_DIR=${BASE_DIR}/export-image
	source "${EXPORT_DIR}/EXPORT_IMAGE"
	EXPORT_ROOTFS_DIR=${WORK_DIR}/$(basename ${EXPORT_DIR})/rootfs
	run_stage
	if [ -e ${EXPORT_DIR}/EXPORT_NOOBS ]; then
		source ${EXPORT_DIR}/EXPORT_NOOBS
		STAGE_DIR=${BASE_DIR}/export-noobs
		run_stage
	fi
done

if [ -x postrun.sh ]; then
	log "Begin postrun.sh"
	cd "${BASE_DIR}"
	./postrun.sh
	log "End postrun.sh"
fi

log "End ${BASE_DIR}"
