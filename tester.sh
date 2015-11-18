#!/bin/bash


source spork-manager.sh

rm outfile
spork new mys 10 2>&1
for ((i=0; i < 50; i++)); do
(	spork next mys 2> $i.next
	sleep 5s
	if [ $i -eq 7 ]; then sleep 5s; fi
	echo Counting $i >> outfile
	spork finish mys 2> $i.finish
	)  &

done
echo waiting
spork wait mys 2> finish
echo done
