#!/bin/bash
echo "printing..."
for ((i=32;i<=126;i++))
do
    printf "%03d: \\$(printf %03o "$i")\n" "$i"
done
