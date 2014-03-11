#!/bin/bash

for repo in `find / -type d -name .git 2> /dev/null`
do
  repoConfig="${repo}/config"
  if grep "\[user\]" "${repoConfig}" > /dev/null; then
    echo "${repoonfig}" already contains user!!!
  else
    cat ~/.gitconfig_user >> "${repoConfig}"
  fi
done
