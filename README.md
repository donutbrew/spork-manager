This is a simple function to count and manage processes in bash. A crappy homage to Parallel::ForkManager. Yes, anybody could have done it--I know I have several times--so I figured it would be best to standardize.

To use, you have to either source spork-manager.sh or copy and paste the spork function at the top of your script.

Usage: spork <new/start/end/cleanup> <spork name> <number of concurrent threads / max>

Commands: 
	new - starts a new spork with a defined number of slots. 
	next - iterates spork
	finish - ends that iteration
	wait - suspends the script until the named spork is finished
	cleanup - removes instances of the named spork. This is automatically done by finish
		  when the count reaches 0, but this is here nonetheless. Using "all" as a 
		  name removes all trace of all sporks.

Example:

	for i in bad*.txt; do 
            spork new MYSPORK max 
          	(       spork next MYSPORK
			grep -v "donutbrew" $i > scrub_$i
			rm -f $i
			spork end MYSPORK
		) &
		
	done
	spork wait MYSPORK

Note that the spork has to be  created outside a subshell, but the next, the code, and the finish func must be contained in a subshell and should be backgrounded (a limitation of shell). This means that any variables changed will not propogate to the main script. I might think of a way to do that later, but fo now, treat it like a subshell. 

To do:
1. Decide whether to impose a global maximum based on available cores.
2. Stuff and thangs...
