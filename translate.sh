#!/bin/bash

INPUT="$1"
OUTPUT="zenon_modulo/$(basename $INPUT .p).dk"
if zenon_modulo -itptp -modulo -modulo-heuri -odk -max-time 120s -max-size 2G $INPUT > $OUTPUT 
then 
	echo 'Proof found'
    gzip $OUTPUT
else 
	echo 'Unable to find a proof'
    rm $OUTPUT
fi
