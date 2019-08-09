#!/bin/bash

RED='\033[0;31m'
BLUE='\033[0;34m'
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

function git_list_remote_tags() {
  target=`_target "${1}"`

  # return tags without sha1 (cut) and without peeled tags (--refs)
  git -C "${target}" ls-remote --refs --tags ${2} | cut -f 2-
}

function contains_item() {
  # https://stackoverflow.com/questions/8063228/how-do-i-check-if-a-variable-exists-in-a-list-in-bash
  [[ $1 =~ (^|[[:space:]])$2($|[[:space:]]) ]]
}

function git_tags_in_both() {
  compare_tags="$(git_list_remote_tags "${1}" "${2}")"
  for tag in `git_list_remote_tags "${1}" "${3}"`
  do
    if [[ "${compare_tags}" =~ "${tag}" ]]
    then
      echo "${tag#refs/tags/}"
    fi
  done
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

function ask_user() {
  while true
  do
    echo -e "${BLUE}${1} Solve the task first on another console and continue afterwards..${NC}"
    read -p "Can continue? (y/n) " answer

    case $answer in
     [yY]* ) echo "Going to continue.."
             break;;

     [nN]* ) return 1;;

     * )     echo "Just enter Y or N, please.";;
    esac
  done
}

function git_merge_branches() {
  RESULT_REPO=`_target "${1}"`
  MERGE_REMOTE=`basename "${2#*:}"`
  # FIXME consider the git command to fail
  for new_branch in `git_branches_not_known "${1}" "origin" "${MERGE_REMOTE}"`
  do
    git -C "${RESULT_REPO}" branch "${new_branch}" "refs/remotes/${MERGE_REMOTE}/${new_branch}" || return 1
  done

  local_branches="$(git -C "${RESULT_REPO}" for-each-ref --format="%(refname)" refs/heads/)"

  # 1. Merge all branches that exist in both repos
  for new_branch in `git_branches_in_both "${1}" "origin" "${MERGE_REMOTE}"`
  do
    if [[ ! "${new_branches}" =~ "refs/heads/${new_branch}" ]]
    then
      git -C "${RESULT_REPO}" branch "${new_branch}" "refs/remotes/origin/${new_branch}" || ask_user "Branching ${new_branch} based on 'refs/remotes/origin/${new_branch}' failed, make sure branch exists." || return 2
    fi
    git -C "${RESULT_REPO}" checkout "${new_branch}" || ask_user "Checkout failed, ensure to checkout ${new_branch}." || return 3
    git -C "${RESULT_REPO}" merge --allow-unrelated-histories --no-edit -s recursive -X patience "refs/remotes/${MERGE_REMOTE}/${new_branch}" || ask_user "Merge failed, solve conflicts now." || return 4
  done
}

function git_merge_tags() {
  RESULT_REPO=`_target "${1}"`
  origin_remote=`basename "${2#*:}"`
  merge_remote=`basename "${3#*:}"`
  for tag in `git_tags_in_both "${1}" origin "${merge_remote}"`
  do
    origin_id="$(git -C "${RESULT_REPO}" ls-remote --refs --tags origin "${tag}" | cut -f -1)"
    merge_id="$(git -C "${RESULT_REPO}" ls-remote --refs --tags "${merge_remote}" "${tag}" | cut -f -1)"
    echo "Tagging ${origin_id} as '${tag}-${origin_remote}'"
    git -C "${RESULT_REPO}" tag "${tag}-${origin_remote}" "${origin_id}" || return 1
    echo "Tagging ${merge_id} as '${tag}-${merge_remote}'"
    git -C "${RESULT_REPO}" tag "${tag}-${merge_remote}" "${merge_id}" || return 2
    echo "Merging ${tag}"
    git -C "${RESULT_REPO}" checkout "${origin_id}" || return 3
    git -C "${RESULT_REPO}" merge --allow-unrelated-histories --no-edit -s recursive -X patience "${merge_id}" || ask_user "Merge failed, solve conflicts now." || return 4
    git -C "${RESULT_REPO}" tag -f "${tag}" || return 5
  done
}

# return here if we are sourcing this script
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && return 0

WORK_DIR=`mktemp -d`

TARGET_REPO="${1}"
MERGED_REPO="${2}"

git_clone "${TARGET_REPO}" "${WORK_DIR}" || exit_on_error "Clone failed." 1
git_add_remote_and_fetch "${WORK_DIR}" "${MERGED_REPO}" || exit_on_error "Adding remote failed." 2
git_merge_branches "${WORK_DIR}" "${MERGED_REPO}" || exit_on_error "Merging branches failed." 3
git_merge_tags "${WORK_DIR}" "${TARGET_REPO}" "${MERGED_REPO}" || exit_on_error "Merging tags failed." 4
# TODO
# 4. Review and push all the changes

echo "Result can be found under ${RESULT_REPO}"
