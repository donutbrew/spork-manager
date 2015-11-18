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
# Version 0.1, 2015-11-18
# Author: Clint Paden
# Usage : spork <new/start/end/cleanup> <spork name> <number of concurrent threads / max>
 
declare -f spork 

spork_count () {
	( 	
		unset count
		exec {count}< $sporkdir/$2.curr
		flock -e $count
		thiscount=$(cat $sporkdir/$2.curr)

		if [ $1 == "add" ]; then
			echo $((++thiscount)) > $sporkdir/$2.curr
		elif [ $1 == "sub" ]; then
			echo $((--thiscount)) > $sporkdir/$2.curr
		elif [ $1 == "read" ]; then
			echo $thiscount
		elif [ $1 == "cap" ]; then
#			total=$($sporkdir/$2.total
			if [  $thiscount -ge $total ]; then echo true; else echo false; fi
		elif [ $1 == "addgo" ]; then
			if [ $thiscount -lt $total ]; then
			echo $((++thiscount)) > $sporkdir/$2.curr
			echo false
			else echo true
			fi
		else
			echo "Counting error" && exit 34535 >&2
		fi
	)
}

spork () {
#	set -x

	case $1 in
		new) 
			if [ ! -n "${spork_init+1}" ] || [ $spork_init -ne 1 ]; then 
				sporkdir=$(mktemp -d ~/.spork.XXXXX) && chmod 700 $sporkdir && spork_init=1
#				rm ~/.spork.test -r; mkdir ~/.spork.test; sporkdir="$HOME/.spork.test" && chmod 700 $sporkdir && spork_init=1#this line is for testing
									
			fi
			if [ "$3" == "max" ] ; then 

				#BSD
				if [[ $(uname) =~ [Bb][Ss][Dd] || $(uname) =~ [Dd]arwin ]]; then
					totalcpu=$(sysctl -a | egrep -i 'hw.machine|hw.model|hw.ncpu'|cut -f2 -d ' ')
				#Linux
				elif [[ $(uname) =~ [Ll]inux ]]; then
					totalcpu=$(grep -c ^processor /proc/cpuinfo)
				else
					echo "Error: System type not detected. You may not use \"max\"." >&2
				fi
				
				echo $totalcpu > $sporkdir/$2.total
				echo 0 > $sporkdir/$2.curr
			else 
				echo $3 > $sporkdir/$2.total
				echo 0 > $sporkdir/$2.curr
			fi
			;;
		next)	
			if [ ! -e $sporkdir/$2.total ] ; then 
				echo "Unknown Fork $2" >&2
			else
				total=$(cat $sporkdir/$2.total)
				while [ "$(spork_count addgo $2)" == "true" ]; do 
					sleep 5s
				done
				echo "%%% Curr is $(cat sporkdir/$2.curr)" >&2

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
				rm -rf $sporkdir
				spork_init=0
			else
				curr=$(cat $sporkdir/$2.curr)
				if [ $curr -gt 0 ]; then echo "SporkManager warning: Cleaning up spork before empty." >&2 ; fi
				rm $sporkdir/$2.curr $sporkdir/$2.total
				#if [ ! "ls -A $sporkdir" ]; then rmdir $sporkdir && echo "Cleaning up after spork" ; fi
			fi
			;;
		*)	
			echo "Spork-Manager Error: Command $1 not valid" && exit 1
			;;
		esac
}



