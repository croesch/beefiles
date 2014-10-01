#!/bin/bash

. ~/.git-prompt
GIT_PS1_SHOWUPSTREAM="verbose"
GIT_PS1_SHOWDIRTYSTATE="true"

COLOR="\033[0;35m"
NO_COLOR="\033[0m"

for repo in $(ls -1)
do
  if [ -d $repo/.git ]
  then
    cd $repo
    printf "%-50s" $repo
    __git_ps1 "$COLOR[%s]$NO_COLOR"
    echo
    cd ..
  fi
done
