#!/bin/bash

GREEN="\033[1;32m"
RED="\033[1;31m"
NO_COLOR="\033[0m"

echo "Removing all branches beginning with 'change' for all repos in $(pwd)"
echo

for repo in $(ls -1)
do
  if [ -d "${repo}/.git" ]
  then
    pushd "${repo}" &> /dev/null

    deleted=0

    for branch in $(git branch | cut -c3- | egrep "^change")
    do
      output="$(git branch -D ${branch} 2>&1)"
      result=$?
      if [ $result == 0 ]
      then
        echo -ne "${GREEN}"
        deleted=$((deleted+1))
      else
        echo -ne "${RED}"
      fi

      echo -n "${repo} - ${output}"
      echo -e "${NO_COLOR}"
    done

    if [[ "${deleted}" > 0 ]]
    then
      git gc
    fi

    popd &> /dev/null
  fi
done

echo
echo "done :)"
