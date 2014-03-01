#!/bin/bash

NOT_IN="origin/master"
SOURCE="origin/master"

if [ "$#" -lt 2 ]
then
  echo "wrong usage see source.."
  exit 1;
else
  NOT_IN="${1}"
  SOURCE="${2}"
fi

echo "Porting from ${SOURCE} \wo ${NOT_IN} ..."
echo "----"

for commit in `git log --reverse ${SOURCE} --not ${NOT_IN} "$@" --pretty=format:%H`
do
  echo "cherry picking --> $commit"
  git cherry-pick $commit
  if [ $? -eq 0 ]
  then
    echo "  ..successful."
  else
    read -p "Press [ENTER] key if you have resolved the conflicts and to continue mass cherry picking ..."
  fi
done

