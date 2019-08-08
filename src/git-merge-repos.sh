#!/bin/bash

RED='\033[0;31m'
NC='\033[0m' # No Color

function _target() {
  echo "${1}/target"
}

function git_clone() {
  target=`_target "${2}"`
  echo "Cloning ${1} into ${target}"
  git clone -q "${1}" "${target}" || return 1
}

function exit_on_error() {
  rm -fr "${WORK_DIR}"
  echo -e "${RED}${1}${NC}"
  exit "${2}"
}

function git_add_remote_and_fetch() {
  target=`_target "${1}"`
  # Remove everything until : (ssh) and afterwards use the last part
  origin=`basename "${2#*:}"`
  echo "Adding '${2}' as remote in '${target}'"
  git -C "${target}" remote add "${origin}" "${2}" || return 1

  echo "Fetching from '${origin}'"
  git -C "${target}" fetch "${origin}" || return 2
}

function git_list_remote_branches() {
  target=`_target "${1}"`

  git -C "${target}" for-each-ref --format="%(refname)" refs/remotes/${2}
}

function contains_item() {
  # https://stackoverflow.com/questions/8063228/how-do-i-check-if-a-variable-exists-in-a-list-in-bash
  [[ $1 =~ (^|[[:space:]])$2($|[[:space:]]) ]]
}

function git_branches_in_both() {
  compare_branches="$(git_list_remote_branches "${1}" "${2}")"
  for branch in `git_list_remote_branches "${1}" "${3}"`
  do
    branch="${branch#refs/remotes/${3}/}"
    if [[ "${compare_branches}" =~ "refs/remotes/${2}/${branch}" ]]
    then
      echo "${branch}"
    fi
  done
}

function git_branches_not_known() {
  compare_branches="$(git_list_remote_branches "${1}" "${2}")"
  for branch in `git_list_remote_branches "${1}" "${3}"`
  do
    branch="${branch#refs/remotes/${3}/}"
    if [[ ! "${compare_branches}" =~ "refs/remotes/${2}/${branch}" ]]
    then
      echo "${branch}"
    fi
  done
}

# return here if we are sourcing this script
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && return 0

WORK_DIR=`mktemp -d`

TARGET_REPO="${1}"
MERGED_REPO="${2}"

git_clone "${TARGET_REPO}" "${WORK_DIR}" || exit_on_error "Clone failed." 1
git_add_remote_and_fetch "${WORK_DIR}" "${MERGED_REPO}" || exit_on_error "Adding remote failed." 2
RESULT_REPO=`_target "${WORK_DIR}"`
MERGE_REMOTE=`basename "${MERGED_REPO#*:}"`
# FIXME consider the git command to fail
for new_branch in `git_branches_not_known "${WORK_DIR}" "origin" "${MERGE_REMOTE}"`
do
  # FIXME consider the git command to fail
  git -C "${RESULT_REPO}" branch "${new_branch}" "refs/remotes/${MERGE_REMOTE}/${new_branch}"
done
# TODO
# 1. Merge all branches that exist in both repos
# 2. Create unique tags for tags that exist in both repos
# 3. Create merge commits for tags that exist in both repos and move the old ones
# 4. Review and push all the changes

echo "Result can be found under ${RESULT_REPO}"
