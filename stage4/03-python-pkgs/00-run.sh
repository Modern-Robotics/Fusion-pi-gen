#!/bin/bash -e

#===============================================================================
# Script to install various Python packages used for the Fusion
#===============================================================================
# 27-Aug-2018 <jwa> - Created, moved numpy install to here since it takes up so
#		much time to compile all of the modules in the upgrade to 1.15.1
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

echo "$atBRT$fgREDInstalling various Python Modules and Libraries$atRST$fgNEU"

echo "$atBRT$fgGRN---< pip install imutils >---$atRST$fgNEU"
pip -vvv install imutils 

echo "$atBRT$fgGRN---< pip install numpy >---$atRST$fgNEU"
pip -vvv install numpy 

echo "$atBRT$fgGRN---< pip install --upgrade numpy >---$atRST$fgNEU"
pip -vvv install --upgrade numpy

echo
