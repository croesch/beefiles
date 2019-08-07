#!/bin/bash

RED='\033[0;31m'
NC='\033[0m' # No Color

function git_clone() {
  target="${2}/target"
  echo "Cloning ${1} into ${target}"
  git clone -q "${1}" "${target}" || return 1
}

function exit_on_error() {
  rm -fr "${WORK_DIR}"
  echo -e "${RED}${1}${NC}"
  exit "${2}"
}

# return here if we are sourcing this script
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && return 0

WORK_DIR=`mktemp -d`

git_clone ${1} ${WORK_DIR} || exit_on_error "Clone failed." 1
echo "Result can be found under ${WORK_DIR}"
