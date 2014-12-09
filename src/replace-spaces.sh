#!/bin/bash

rename() {
    ls -p "$1" | while read dir;
    do
        src=`echo "$1$dir"`;
        target=`echo "$dir" | sed -r 's/[ -_]+/-/g' | tr '[:upper:]' '[:lower:]'`;
        target=`echo "$1$target"`;
        if [ -d "$src" ]
        then
            move "$src" "$target";
            rename "$target";
        else
            move "$src" "$target";
        fi

    done;
}

move() {
    if [ "$1" != "$2" ]
    then
        echo "Renaming '$1' to '$2'";
        mv "$1" "$2";
    fi
}

rename "$1"
