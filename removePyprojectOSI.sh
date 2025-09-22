#!/bin/bash

theString="License :: OSI Approved :: "
files=$(find . -name "pyproject.toml" -exec grep -l "$theString" {} +)
for file in $files; do
    file=$(realpath "$file")
    echo "Processing $file"
    # Remove the line containing "License :: OSI Approved :: "
    sed -i "/$theString/d" "$file"
done
