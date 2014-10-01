#!/bin/bash

COLOR="\033[1;33m"
GREEN="\033[1;32m"
RED="\033[1;31m"
NO_COLOR="\033[0m"

for repo in $(ls -1)
do
  if [ -d $repo/.git ]
  then
    cd $repo
    printf "%-50s" $repo
    echo -ne "[${COLOR}pulling${NO_COLOR}]"
    pullOut=$(git pull --rebase 2>&1)
    result=$?
    echo -en "\b\b\b\b\b\b\b\b"
    if [ $result == 0 ]
    then
      echo -e "  ${GREEN}ok!${NO_COLOR}  ]"
    else
      echo -e " ${RED}ERROR${NO_COLOR} ]"
    fi
    echo "$pullOut" | sed -e "s/^/\t/g"
    cd ..
  fi
done
