#!/bin/bash

set -x
source spork-manager.sh
rm outfile
mkdir ~/spork
spork new mys 10 2>&1 > main.start
ord=0
for ((i=0; i < 43; i++)); do
(	spork next mys 2> $i.next
	echo $ord $t
	# if [ $i -eq 7 ]; then sleep 5s; fi
	./sub.sh
	echo $ord Counting $i >> outfile
	spork finish mys 2> $i.finish
	)  &
	((ord++))
done
echo waiting
spork wait mys 2> main.finish
# sleep 30s
echo done
