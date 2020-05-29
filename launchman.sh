#!/bin/bash  

# LAUNCH CMD CONFIG FOR PEGASUS FRONTEND
# enters the command to launch an emulator specified in cores.txt
# into the metadata file (in cases where the config file does not
# work in Skyscraper, or you don't want to run it again)

IFS=$'\n'

INPUT=/tmp/menu.sh.$$
OUTPUT=/tmp/output.sh.$$

trap "rm $OUTPUT; rm $INPUT; exit" SIGHUP SIGINT SIGTERM

## DEFAULT FILE LOCATIONS ##
declare MD_PATH="/home/nate/Games/roms"
declare CMD_PATH="/home/nate/Games/emulator_files/cores.txt"
declare LR_PATH="/home/nate/.config/retroarch"
declare -a ALL_CORES=$(ls "$LR_PATH"/cores/*.so); 
declare PLATFORM="none"
declare CORE="none"

## PLATFORM ID AND NAME ASSOCIATIVE ARRAY##
declare -a DIR=(`cat $CMD_PATH | cut -d':' -f 1`)
declare -A SYS_ID

## SAVED CMDS ARRAY ##
declare -a CMD=(`cat $CMD_PATH | cut -d':' -f 3`); 

## HELP AND INFO MESSAGES ##
# the about message
declare MSG1="This script was designed to make Pegasus emulator configuration more manageable. \
 rather than having to configure the metadata file by hand, this script will present a list of \
 retroarch cores and emulators for a given system. "
# the help message
declare MSG2=""

# loads the retroarch platform id into an associative array
# that uses rom directory names as parameters
init_id(){

    local I
    local PLAT_ID=(`cat $CMD_PATH | cut -d':' -f 2`)

    for I in ${!DIR[*]}; do

        SYS_ID[${DIR[$I]}]="${PLAT_ID[$I]}"

    done

}

menu()
{

	local OPTS
	local SELECT
	local I
	local J

	for ((I=1; I<=$#-3; I++)); do

		J=$(($I+3))
		OPTS+=( $I "${!J}")

	done

	local MENU=(dialog --title "$2" --menu "$3" 0 0 0 )
	local SELECTIONS=$("${MENU[@]}" "${OPTS[@]}" 2>&1 >/dev/tty)
	
	for SELECT in $SELECTIONS; do

		case SELECT in

		*)
			local RET=$(($SELECT+3))
			eval "$1=${!RET}"
			;;

		esac

	done 

}

# menu function for setting a system's core or emulator. 
set_cores()
{

	echo "lol, nothing here yet"

#                P)
#					menu "PLATFORM" \
#						 "SYSTEM SELECTION" \
#						 "please select the system to configure:" \
#						 ${DIR[@]}
#					;;
#
#				C)
#					if [[ $PLATFORM != "none" ]]; then 
#						eval "local -a CORES=($(get_cores $PLATFORM))"
#						menu "CORE" \
#							"EMULATOR SELECTION" \
#							"select a default emulator for $PLATFORM:" \
#							${CORES[@]}
#						else 
#							dialog --msgbox "You have not set a system yet." 6 20 
#						fi
#					;;

}

# gets all cores for a specific platform.
# takes the directory name as a parameter.
get_cores()
{

    local SYS_NAME=$1
	local -a PLAT_CORES
	local I

    for I in ${ALL_CORES[@]}; do 

        # check whether the core is for the platform
        if [[ $(cat "${I%.so}.info" 2> /dev/null | grep "systemid") \
            == "systemid = \"${SYS_ID[$SYS_NAME]}\"" ]]; then 

			PLAT_CORES+=("$(basename $I)")

        fi

	done
    # print out whatever cores were found
	echo ${PLAT_CORES[@]}; 

}

show_cmds()
{

    local I

    for I in ${!DIR[*]}; do 
        
        if [[ "${CMD[$I]}" != '---' ]]; then
            
            # print the platform and the command being set. 
			printf "%s: %s\n" "${DIR[$I]}" "${CMD[$I]}" | sed 's/\/home\/nate\//~\//'
                    
        else
    
            # tell the user no command was found
            printf "%s: none\n" "${DIR[$I]}"
        
        fi
    
    done 

}

# set commands for each core. 
set_cmds()
{

    local I

    for I in ${!DIR[*]}; do 
        
        if [[ "${CMD[$I]}" != '---' ]]; then
            
            # print the platform and the command being set. 
            printf "%-15s %s\n" "${DIR[$I]}" "${CMD[$I]}"
            
            # make a backup of the existing file.
            cp "$MD_PATH/${DIR[$I]}/metadata.pegasus.txt" \
				"$MD_PATH/${DIR[$I]}/.metadata.pegasus.txt.bak"
            
            # set the command in metadata.pegasus.txt
            sed -i -e 's,command: .*,command: '"${CMD[$I]}"',' \
				"$MD_PATH/${DIR[$I]}/metadata.pegasus.txt"
        
        else
    
            # tell the user no command was found
            printf "%-15s\n" "${DIR[$I]}"
        
        fi
    
    done

}

init_id

# -- main menu --
while true; do

	dialog --clear \
        --title "PEGASUS FRONTEND COMMAND MANAGER" \
        --menu "please make a selection." 15 52 18 \
		S "Set an emulator for a system." \
        M "Review commands for all platforms." \
        W "Write all commands to metadata_pegasus.txt." \
        Q "Quit." 2>"${INPUT}"

        SELECTION=$(<"${INPUT}")

        case $SELECTION in


				S) 
					echo "\n" # some code will go here
					;;

				M)
					dialog --msgbox "$(show_cmds)" 0 0;  
					;;

                Q)  
					clear
					echo "later..."
					break
					;;

        esac

done

[ -f $OUTPUT ] && rm $OUTPUT
[ -f $INPUT ] && rm $INPUT
