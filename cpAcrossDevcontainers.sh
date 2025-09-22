#!/usr/bin/bash
repo=$1
fileName=$2

if [ -z "$repo" ] || [ -z "$fileName" ]; then
    echo "Usage: $0 <source_repo> <source_fileName>"
    exit 1
fi

startingPath=$(realpath .)

dcFolder=$(find "$startingPath" -path "*/$repo/*" -type d -name ".devcontainer" -print -quit)
cpFile=$(find $dcFolder -type f -name "$fileName" -print -quit)
fileToFolder=$(realpath --relative-to="$dcFolder" "$cpFile")
extraPath=$(dirname $fileToFolder)
if [ ! -z "$extraPath" ]; then
    extraPath="/$extraPath"
fi

if [ ! -f $cpFile ]; then
    echo "Source file ($cpFile) not found!"
    exit 1
fi

copyDests=($(find "$startingPath" -type d -not -path "$dcFolder" -name ".devcontainer" -print))
lsFiles="$cpFile "
destPaths=()

for dest in "${copyDests[@]}"; do
    dest+=$extraPath
    destPaths+=("$dest")
    if [ -f "$dest/$fileName" ]; then
        lsFiles+="$dest/$fileName "
    fi
done

pip install --exists-action i --break-system-packages --quiet --disable-pip-version-check --user tabulate

function centre () {
    local str="$1"
    local len="$2"
    local strLen=${#str}
    local spaces=$(( (len - strLen) / 2 ))
    printf "%${spaces}s%s\n" "" "$str"
}

function do_ls {
    local lsFiles="$1"
    local title="$2"
    local showSrc="$3"

    tmpFile=$(mktemp)
    ls --color=never --si --time-style=+"%Y-%m-%d~%H:%M" -l $lsFiles | column --json --table --table-name files --table-columns "access,links,owner,grp,size,date,name" | jq '.' > "$tmpFile"

    lineLen=$(python3 << EOF
import json
import sys
from pathlib import Path
from tabulate import tabulate

tmpFile = Path("$tmpFile")
srcFile = "$cpFile"
data = json.loads(tmpFile.read_text())['files']
keys = ['name','date','size']
for ix, d in enumerate(data):
    dd = {key: d[key] for key in keys}
    dd['date'] = d['date'].replace('~',' ')
    dd['name'] = dd['name'].replace('/./','/')
    dd['isSrc'] = '*' if d['name'] == srcFile else ''
    data[ix] = dd

kwargs = dict (
    tabular_data = data,
    headers={key: key.replace('_',' ').title() for key in keys},
    tablefmt="github",
    disable_numparse=False,
    # colalign=[a for a in alignDict.values()],
)

output  = tabulate(**kwargs)
lineLen = len(output.splitlines()[0])
print (lineLen)
output += "\n\n"
tmpFile.write_text(output)

EOF
)

    if [ "$showSrc" = "true" ]; then
        centre "Source File" $lineLen
        grep -e "^| Name" -e "^$" -e "^|-" -e "^| ${cpFile} " $tmpFile
    fi
    centre "$title" $lineLen
    grep -v -e "^| ${cpFile} "  $tmpFile
    }

do_ls "$lsFiles" "Destination Files" "true"

changes=0
lsFiles=""
for dest in "${destPaths[@]}"; do
    rs=$(rsync --itemize-changes --checksum --times --one-file-system --mkpath "$cpFile" "$dest")
    if [ ! -z "$rs" ]; then
        if [ $changes -eq 0 ]; then
            echo "Copying to:"
        fi
        echo "$dest"
        changes=$((changes+1))
        lsFiles+="$dest/$fileName "
    fi
done
echo ""
if [ $changes -eq 0 ]; then
    echo "* No changes made"
else
    str="Copied file"
    if [ $changes -gt 1 ]; then
        str+="s ($changes)"
    fi
    do_ls "$lsFiles" "$str" "false"
fi