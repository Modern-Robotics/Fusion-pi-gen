#===============================================================================
# dependencies_check - Make sure required dependencies are installed
#-------------------------------------------------------------------------------
# Input ($@) is a list of files containing the names of dependent packages
#
# Each dependency in the file(s) is in the form of a tool to test for, 
# optionally followed by a : and the name of a package if the package on a 
# Debian-ish system is not named for the tool. For example,
#    qemu-arm-static:qemu-user-static  --or--  mkdosfs:dosfstools
#===============================================================================
dependencies_check()
{
    local depfile deps missing

    for depfile in "$@"; do
        if [[ -e "$depfile" ]]; then
            deps="$(sed -f "${SCRIPT_DIR}/remove-comments.sed" < ${BASE_DIR}/depends)"

        fi
        for dep in $deps; do
            if ! hash ${dep%:*} 2>/dev/null; then
                missing="${missing:+$missing }${dep#*:}"
            fi
        done
    done

    if [[ "$missing" ]]; then
        echo "Required dependencies not installed"
        echo
        echo "This can be resolved on Debian/Raspbian systems by installing:"
        echo "$missing"
        false
    fi
}
