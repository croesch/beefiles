#!/bin/bash

if [ -d "${1}" ]
then
  cd "${1}"
  git add --all .
  git commit -m "Automatic commit."
fi
