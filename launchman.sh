#!/bin/bash

# launchman.sh: a script to manage the emulator launch commands for pegasus frontend
# requires the dialog package to work

LR_CORES=($(ls /home/nate/.config/retroarch/cores))
PLATFORMS=($(dirname $(readlink '/home/nate/Games/roms/*')))


#
INPUT=/tmp/menu.sh.$$
OUTPUT=/tmp/output.sh.$$

trap "rm $OUTPUT; rm $INPUT; exit" SIGHUP SIGINT SIGTERM

display_patforms()
{

while true; do

dialog --clear --backtitle "Pegasus Frontend Launch Command Utility"\
	--title "Platform Selection" \
	--menu "\n\
	Platform: \n\
	Emulator: \n\
	\nPlease select a platform." 0 50 ${#PLATFORMS[@]}\
	"" 2>"${INPUT}" 

	SELECTION=$(<"${INPUT}")

	case $SELECTION in

		P) ;;
		C) ;;
		M) ;;
		W) ;;
		Q) exit 0;;

	esac




done





}

# -- main menu -- 

while true; do

dialog --clear --backtitle "Pegasus Frontend Launch Command Utility"\
	--title "Main Menu" \
	--menu "\n\
	Platform: \n\
	Emulator: \n\
	\n" 0 0 0 \
	P "Select a platform" \
	C "Configure emulator and settings." \
	M "Manually enter the command for a platform." \
	W "Write command to metadata_pegasus.txt." \
	Q "Quit this dialog." 2>"${INPUT}" 

	SELECTION=$(<"${INPUT}")

	case $SELECTION in

		P) ;;
		C) ;;
		M) ;;
		W) ;;
		Q) exit 0;;

	esac




done

[ -f $OUTPUT ] && rm $OUTPUT
[ -f $INPUT ] && rm $INPUT
