#!/bin/bash

installationTarget="${HOME}/bin"

function linkBee {
  rawBee="${PWD}/${1}"
  bee="${1/src\//}"
  bee="${bee/\.sh/}"
  installedBee="${2}/${bee}"

  if [ -e "${installedBee}" ]
  then
    if [ -L "${installedBee}" ]
    then
      unlink "${installedBee}"
    else
      mv "${installedBee}"{,.bak}
    fi
  fi

  ln -sf "${rawBee}" "${installedBee}"
}

if [ ! -d "${installationTarget}" ]
then
  echo -n "Creating installation target directory.."
  mkdir -p "${installationTarget}"
  echo "done."
fi

for bee in src/*.sh
do
  linkBee "${bee}" "${installationTarget}"
done

