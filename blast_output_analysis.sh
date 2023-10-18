#!/bin/bash

if [[ -z "$1" ]]; then 
	echo "You must provide a sequence alignment"
	exit 1
fi

# list accession numbers

awk 'BEGIN {FS="|"} {if($1 == "gi") print $4}' "$1";

