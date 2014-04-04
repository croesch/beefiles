#!/bin/bash

for repo in `find / -type d -name .git 2> /dev/null`
do
  echo -n "Adding user to ${repo}.. "
  repoConfig="${repo}/config"
  if grep "\[user\]" "${repoConfig}" > /dev/null; then
    echo "already contains user!!!"
  else
    cat ~/.gitconfig_user >> "${repoConfig}"
    echo "done."
  fi
done
