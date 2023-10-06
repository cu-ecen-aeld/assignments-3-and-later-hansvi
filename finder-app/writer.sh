#!/bin/bash

if [ $# -ne 2 ]
then
	echo "Usage: $0 <writefile> <writestr>"
	exit 1
fi

filepath=`dirname "$1"`
writefile="$1"

writestr="$2"

mkdir -p "$filepath"
if [ $? -ne 0 ]
then
	echo "Could not create path: \"$filepath\""
	exit 1
fi

echo "$writestr" > "$writefile"
if [ $? -ne 0 ]
then
	echo "Could not create file: \"$writefile\""
	exit 1
fi
