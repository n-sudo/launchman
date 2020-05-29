#!/bin/bash  

IFS=$'\n'

INPUT=/tmp/menu.sh.$$
OUTPUT=/tmp/output.sh.$$

trap "rm $OUTPUT; rm $INPUT; exit" SIGHUP SIGINT SIGTERM

## VARS ##
declare ROM_PATH="/home/$USER/Games/roms"
declare CMD_PATH="/home/$USER/Games/emulator_files/cores.txt"
declare LR_PATH="/home/$USER/.config/retroarch"
declare -a ALL_CORES=$(ls "$LR_PATH"/cores/*.so);
declare -a DIR=(`cat $CMD_PATH | cut -d':' -f 1`)
declare -A SYS_ID
declare -a CMD=(`cat $CMD_PATH | cut -d':' -f 3`); 

## HELP AND INFO MESSAGES ##
# the about message
declare MSG1="This script was designed to make Pegasus emulator configuration more manageable. \
 rather than having to configure the metadata file by hand, this script will present a list of \
 retroarch cores and emulators for a given system. "
# the help message
declare MSG2="no cores were found for this platform. this happens from time to time. Would you \
like to enter a custom command instead? "

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

	local MENU=(dialog --title "$2" --cancel-label "Back" --menu "$3" 0 0 0 )
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

	local PLATFORM="none"
	local CORE="none"
	local game_specific=$1

	menu "PLATFORM" \
		 "SYSTEM SELECTION" \
		 "please select the system to configure:" \
		 ${DIR[@]}

	if [[ $PLATFORM != "none" ]]; then

		if [[ $game_specific -ne 0 ]]; then

			GAMES=($(ls $ROM_PATH/$PLATFORM))

			echo ${GAMES[@]}

			sleep 3

			local GAME="none"

			menu "GAME" \
				 "GAME SELECTION" \
				 "please select the game to configure:" \
				 ${GAMES[@]}

		fi
		
		eval "local -a CORES=($(get_cores $PLATFORM))"

		if [[ ${#CORES[@]} -gt 0 ]]; then 

			menu "CORE" \
				"EMULATOR SELECTION" \
				"select a default emulator for $PLATFORM:" \
				${CORES[@]}

		else 
	
			dialog --yesno $MSG2 6 30 
	
		fi

	fi
	
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

get_cmds()
{

    local I

    for I in ${!DIR[*]}; do 
        
        if [[ "${CMD[$I]}" != '---' ]]; then
            
            # print the platform and the command being set. 
			printf "%s: %s\n" "${DIR[$I]}" "${CMD[$I]}" | sed 's/\/home\/'$USER'\//~\//'
                    
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
            cp "$ROM_PATH/${DIR[$I]}/metadata.pegasus.txt" \
				"$ROM_PATH/${DIR[$I]}/.metadata.pegasus.txt.bak"
            
            # set the command in metadata.pegasus.txt
            sed -i -e 's,command: .*,command: '"${CMD[$I]}"',' \
				"$ROM_PATH/${DIR[$I]}/metadata.pegasus.txt"
        
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
		D "Set the default emulator for a system." \
		G "Set an emulator for a specific game." \
        M "Review commands for all platforms." \
        W "Write all commands to metadata_pegasus.txt." \
        Q "Quit." 2>"${INPUT}"

        SELECTION=$(<"${INPUT}")

        case $SELECTION in

				D) 
					set_cores 0
					;;

				G)
					set_cores 1
					;;

				M)
					dialog --msgbox "$(get_cmds)" 0 0;  
					;;

                Q)  
					clear
					echo "have a nice day..."
					break
					;;

        esac

done

[ -f $OUTPUT ] && rm $OUTPUT
[ -f $INPUT ] && rm $INPUT
