#!/bin/bash
# used by tester.sh to be able to easily tell how many copies are running at once in `ps`

t=$((RANDOM%9))
sleep ${t}s
