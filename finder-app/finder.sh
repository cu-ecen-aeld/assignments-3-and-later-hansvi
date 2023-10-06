#!/bin/bash

if [ $# -ne 2 ]
then
	echo "Usage: $0 <filesdir> <searchstr>"
	exit 1
fi

filesdir="$1"
searchstr="$2"

if [  ! -d "$filesdir" ]
then
	echo "The first argument needs to be a directory"
	exit 1
fi

filecount=`find "$filesdir" -type f | wc -l`
linecount=`grep -r "$searchstr" "$filesdir" | wc -l`

echo "The number of files are $filecount and the number of matching lines are $linecount"
