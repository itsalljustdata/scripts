#!/bin/bash

repo="mainroads.py.monorepo"
startingPath=$(realpath .)
dcFolder=$(find "$startingPath" -path "*/$repo/*" -type d -name ".devcontainer" -print -quit)

files=$(find "$dcFolder" -maxdepth 1 -type f -not -name "devcontainer.json" -mtime -1 -printf "%f\n" | sort -u)



for file in $files; do
    echo "Copying $file"
    $(dirname $0)/cpAcrossDevcontainers.sh "$repo" "$file"
done