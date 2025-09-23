#!/usr/bin/bash

find . -type d -name ".git" | sort | while read gitdir; do
    repo_dir=$(dirname "$gitdir")
    (
        repo_dir=$(realpath "$repo_dir")
        cd "$repo_dir" || exit
        cnt=$(git status --porcelain | wc -l)
        if [ "$cnt" -eq 0 ]; then
            :
        else
            echo "$repo_dir : $(git remote get-url origin | sed 's/\.git$//')"
        fi
    )
done