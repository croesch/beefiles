#!/bin/bash

for repo in $(ls -1)
do
  if [ -d $repo/.git ]
  then
    cd $repo
    echo $repo
    echo "---"
    eval "${1}"
    echo
    cd ..
  fi
done
