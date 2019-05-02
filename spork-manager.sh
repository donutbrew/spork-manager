################################################################################
# spork-manager: a bash parallelizer
# 	http://github.com/donubrew/spork-manager
#	Please source this fileinto your scripts. You could paste it, I guess.
#
# Commands:
#        new <handle> <slots> : starts a new spork with a defined # of slots.
#        next <handle>        : iterates spork
#        finish <handle>      : ends that iteration
#        wait <handle>        : suspends the script until the named spork is 
#                               finished
#        cleanup <handle>     : removes instances of the named spork. This is 
#                               automatically done by wait after it is done
#                               waiting. Using "all" as a handle removes all 
#                               trace of all sporks.
#
# Version 0.2.1, 2019-04-30
# Author: Clint Paden
# Usage : spork <new/start/end/cleanup> <spork name> <number of concurrent threads / max>

declare -f spork
declare sporkdir
spork_init=0
spork_debug=1
set -x

spork_count () {
	
	[ $spork_init -eq 0 ] 	 && echo "SporkManager Error: Trying to modify a non-existant spork: $2." >&2
	[ -f $sporkdir/$2.curr ] || echo "SporkManager Error: $sporkdir/$2.curr not found! This is bad." >&2
	( 	
		cat $sporkdir/$2.curr >> testfile; echo "---" >> testfile
		
		flock -x 3 || { [ $spork_debug ] && echo "Unable to get a lock on $sporkdir/$2.curr" ; }
		local thiscount=$(<$sporkdir/$2.curr)
		local total=$(<$sporkdir/$2.total)
		[ $spork_debug ] && echo "thiscount is $thiscount" >&2
		case $1 in
			sub)
				[ $thiscount -lt 1 ] && echo "SporkManager Error: lowering count below 1--something is wrong." >&2
				echo $((--thiscount)) >&3 
				;;

			read)
				echo $thiscount
				;;

			cap)
				if [  $thiscount -ge $total ]; then echo true; else echo false; fi
				;;

			add)
				if [ $thiscount -lt $total ]; then
					echo $((++thiscount)) >&3 
					return 0  #return success
				else 
					return 1  #return failure
				fi
				;;
			*) 
				echo "Counting error" && exit 34535 >&2
				;;
		
		esac
	) 3<>$sporkdir/$2.curr
}

spork () {
#	set -x

	case $1 in
		new) 
			if [ $spork_init -ne 1 ]; then 
				sporkdir=$(mktemp -d) && spork_init=1 && [ $spork_debug ] && echo "sporkdir is on $HOSTNAME at $sporkdir"
				# sporkdir=$(mktemp -d ~/.spork.XXXXX) && chmod 700 $sporkdir && spork_init=1
									
			fi
			if [ -f $2.total ]; then
				echo "Fork $2 already declared! Fatal error" >&2
				exit 1
			fi
			if [ "$3" == "max" ] ; then 

				#BSD
				if [[ $(uname) =~ [Bb][Ss][Dd] || $(uname) =~ [Dd]arwin ]]; then
					totalcpu=$(sysctl -a | egrep -i 'hw.machine|hw.model|hw.ncpu'|cut -f2 -d ' ')
				#Linux
				elif [[ $(uname) =~ [Ll]inux ]]; then
					totalcpu=$(grep -c ^processor /proc/cpuinfo)
				else
					echo "Error: System type not detected. You may not use \"max\". Setting to 1 for now." >&2
					totalcpu=1
				fi
				
				echo $totalcpu > $sporkdir/$2.total
				echo 0 > $sporkdir/$2.curr
			else 
				echo $3 > $sporkdir/$2.total
				echo 0 > $sporkdir/$2.curr
			fi
			;;
		next)	
			if [ ! -f $sporkdir/$2.total ] ; then 
				echo "Unknown Fork $2" >&2
			else
				# total=$(cat $sporkdir/$2.total)
				while ! $(spork_count add $2); do 
					sleep 5s
				done
				[ $spork_debug ] && echo "%%% Curr is $(cat $sporkdir/$2.curr)" >&2  

			fi
				
			;;
		finish) 
			total=$(cat $sporkdir/$2.total)
			if [ ! -e $sporkdir/$2.total ] ; then
            	echo "Unknown Fork $2" >&2
            else
				spork_count sub $2
			fi

			;;

		wait)	sleep 2s
			while [ -e $sporkdir/$2.curr ] && [ $(spork_count read $2) -gt 0 ]; do
				sleep 1s;
			done
			spork cleanup $2
			
			;;
		cleanup)
			if [ $2 == "all" ] ; then 
				# rm -rf $sporkdir
				spork_init=0
			else
				curr=$(cat $sporkdir/$2.curr)
				if [ $curr -gt 0 ]; then 
					echo "SporkManager warning: Cleaning up spork before empty. Waiting on $2..." >&2
					spork wait $2
					echo "SporkManager: $2 finished. Cleaning up now." >&2
				fi
				rm $sporkdir/$2.curr $sporkdir/$2.total 	&& [ $spork_debug ] && echo "Removing count files $sporkdir/$2.curr , $sporkdir/$2.total" >&2
				rmdir $sporkdir 							&& [ $spork_debug ] && echo "Cleaning up after spork"  >&2
			fi
			;;
		*)	
			echo "Spork-Manager Error: Command $1 not valid" >&2 && exit 1
			;;
		esac
}



