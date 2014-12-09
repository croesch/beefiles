#!/bin/bash

if [ $# -ne 1 ]; then
    echo "ERROR - Usage: $0 workspace-dir"
    echo "(where 'workspace-dir' is the path to the code root [default package]i)"
else
    ls -p "$1" | while read dir;
    do
        if [ -d "$1$dir" ]; then
            package=`echo "$dir" | sed "s/\//;/"`;
            package_abs=`echo "$1$dir"`;
            for file in $(ls $package_abs*.java)
            do
                sed -i "1 ipackage $package" $file
            done
        else
            echo "$dir is in default package - nothing to do"
        fi

    done;
fi

