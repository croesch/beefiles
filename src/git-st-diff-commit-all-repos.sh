#!/bin/bash

for repo in $(git-st-for-all-repos | grep \* | awk '{print $1;}')
do
  cd $repo
  git diff && read -p "Are you sure you want to commit and push the changes? [repo=$repo] (yN)?" -n 1 -r
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    git commit -am "${1}"
    git pull
    git push origin HEAD:refs/heads/master
  fi
  cd ..
done
