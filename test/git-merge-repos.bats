#!/usr/bin/env bats

load sut
SUT="git-merge-repos.sh"

function init_git1() {
  pushd "${GIT1}" > /dev/null
  prepare_example_repo_one
  popd > /dev/null
}

function init_git2() {
  pushd "${GIT2}" > /dev/null
  prepare_example_repo_two
  popd > /dev/null
}

setup() {
  . "${SRC}/${SUT}"
  PATH="${SRC}/:$PATH"

  GIT1="${BATS_TMPDIR}/git1"
  GIT2="${BATS_TMPDIR}/git2"
  WORK="${BATS_TMPDIR}/work"

  mkdir -p "${GIT1}"
  mkdir -p "${GIT2}"
  mkdir -p "${WORK}"
}

teardown() {
  rm -fr "${GIT1}"
  rm -fr "${GIT2}"
  rm -fr "${WORK}"
  return 0
}

@test "${SUT}: clone - clones source into target" {
  init_git1

  run git_clone "${GIT1}" "${WORK}"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Cloning ${GIT1} into ${WORK}" ]]
}

@test "${SUT}: clone - returns 1 if source does not exist" {
  run git_clone "xxx" "${WORK}"

  [ "$status" -eq 1 ]
  [[ "$output" =~ "Cloning xxx into ${WORK}" ]]
}

@test "${SUT}: remote - adds merged as remote in target" {
  init_git1
  init_git2

  ln -s "${GIT1}" "${WORK}/target"
  run git_add_remote_and_fetch "${WORK}" "${GIT2}"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Adding '${GIT2}' as remote in '${WORK}/target'" ]]
  [ `git -C "${WORK}/target" remote get-url git2` = "${GIT2}" ]
}

@test "${SUT}: remote - fetches from merged repo" {
  init_git1
  init_git2

  ln -s "${GIT1}" "${WORK}/target"
  run git_add_remote_and_fetch "${WORK}" "${GIT2}"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Fetching from 'git2'" ]]
  [[ `git -C "${WORK}/target" for-each-ref --format='%(refname)' refs/remotes/git2` =~ "git2/master" ]]
  [[ `git -C "${WORK}/target" for-each-ref --format='%(refname)' refs/remotes/git2` =~ "git2/dev" ]]
  [[ `git -C "${WORK}/target" for-each-ref --format='%(refname)' refs/remotes/git2` =~ "git2/only-in-two" ]]
}

@test "${SUT}: remote - returns 1 if repo does not exist" {
  run git_add_remote_and_fetch "xxx" "${GIT2}"

  [ "$status" -eq 1 ]
}

@test "${SUT}: branches - returns all branches of the remote" {
  init_git1
  init_git2

  git clone -q "${GIT1}" "${WORK}/target"
  git -C "${WORK}/target" remote add git2 "${GIT2}"
  git -C "${WORK}/target" fetch -q git2 2> /dev/null

  run git_list_remote_branches "${WORK}" "git2"

  [[ "$output" =~ "master" ]]
  [[ "$output" =~ "dev" ]]
  [[ "$output" =~ "only-in-two" ]]
  [[ ! "$output" =~ "only-in-one" ]]

  run git_list_remote_branches "${WORK}" "origin"

  [[ "$output" =~ "master" ]]
  [[ "$output" =~ "dev" ]]
  [[ ! "$output" =~ "only-in-two" ]]
  [[ "$output" =~ "only-in-one" ]]
}

@test "${SUT}: branches in both - should list all branches in both" {
  init_git1
  init_git2

  git clone -q "${GIT1}" "${WORK}/target"
  git -C "${WORK}/target" remote add git2 "${GIT2}"
  git -C "${WORK}/target" fetch -q git2 2> /dev/null

  run git_branches_in_both "${WORK}" "origin" "git2"

  [[ "$output" =~ "master" ]]
  [[ "$output" =~ "dev" ]]
  [[ ! "$output" =~ "only-in-two" ]]
  [[ ! "$output" =~ "only-in-one" ]]
}

@test "${SUT}: branches not known - should list all branches only second remote" {
  init_git1
  init_git2

  git clone -q "${GIT1}" "${WORK}/target"
  git -C "${WORK}/target" remote add git2 "${GIT2}"
  git -C "${WORK}/target" fetch -q git2 2> /dev/null

  run git_branches_not_known "${WORK}" "origin" "git2"

  [[ ! "$output" =~ "master" ]]
  [[ ! "$output" =~ "dev" ]]
  [[ "$output" =~ "only-in-two" ]]
  [[ ! "$output" =~ "only-in-one" ]]
}

@test "${SUT}: contains - returns true if list contains item" {
  x="refs/remotes/origin/HEAD"$'\n'"refs/remotes/origin/dev"$'\n'"refs/remotes/origin/master"$'\n'"refs/remotes/origin/only-in-one"

  run contains_item "$x" "refs/remotes/origin/dev"
  [ "$status" -eq 0 ]

  run contains_item "$x" "refs/remotes/unknown/dev"
  [ "$status" -eq 1 ]

  run contains_item "$x" "refs/remotes/origin/not-in-list"
  [ "$status" -eq 1 ]
}

@test "${SUT}: tags - returns all tags of the remote" {
  init_git1
  init_git2

  git clone -q "${GIT1}" "${WORK}/target"
  git -C "${WORK}/target" remote add git2 "${GIT2}"
  git -C "${WORK}/target" fetch -q git2 2> /dev/null

  run git_list_remote_tags "${WORK}" "git2"

  [[ ! "$output" =~ "tag-one" ]]
  [[ "$output" =~ "tag-two" ]]
  [[ "$output" =~ "tag-three" ]]

  run git_list_remote_tags "${WORK}" "origin"

  [[ "$output" =~ "tag-one" ]]
  [[ "$output" =~ "tag-two" ]]
  [[ ! "$output" =~ "tag-three" ]]
}

@test "${SUT}: tags in both - should list all tags in both" {
  init_git1
  init_git2

  git clone -q "${GIT1}" "${WORK}/target"
  git -C "${WORK}/target" remote add git2 "${GIT2}"
  git -C "${WORK}/target" fetch -q git2 2> /dev/null

  run git_tags_in_both "${WORK}" "origin" "git2"

  [[ ! "$output" =~ "tag-one" ]]
  [[ "$output" =~ "tag-two" ]]
  [[ ! "$output" =~ "tag-three" ]]
}

@test "${SUT}: merge branches - should add all unique branches" {
  init_git1
  init_git2

  git clone -q "${GIT1}" "${WORK}/target"
  git -C "${WORK}/target" remote add git2 "${GIT2}"
  git -C "${WORK}/target" fetch -q git2 2> /dev/null

  run git_merge_branches "${WORK}" "${GIT2}"

  [[ "$status" -eq 0 ]]

  branches="$(git -C "${WORK}/target" for-each-ref --format="%(refname)" refs/heads/)"

  [[ "${branches}" =~ "only-in-two" ]]

  git -C "${WORK}/target" checkout -q only-in-two
  files_on_branch="$(git -C "${WORK}/target" ls-files)"

  [ "${files_on_branch}" = "five"$'\n'"twenty/two" ]
}

@test "${SUT}: merge branches - should merge all duplicate branches" {
  init_git1
  init_git2

  git clone -q "${GIT1}" "${WORK}/target"
  git -C "${WORK}/target" remote add git2 "${GIT2}"
  git -C "${WORK}/target" fetch -q git2 2> /dev/null

  run git_merge_branches "${WORK}" "${GIT2}"

  [[ "$status" -eq 0 ]]

  branches="$(git -C "${WORK}/target" for-each-ref --format="%(refname)" refs/heads/)"

  [[ "${branches}" =~ "dev" ]]
  [[ "${branches}" =~ "master" ]]

  git -C "${WORK}/target" checkout -q dev
  files_on_branch="$(git -C "${WORK}/target" ls-files)"

  [ "${files_on_branch}" = "one"$'\n'"ten/three"$'\n'"twenty/four"$'\n'"twenty/two" ]

  git -C "${WORK}/target" checkout -q master
  files_on_branch="$(git -C "${WORK}/target" ls-files)"

  [ "${files_on_branch}" = "one"$'\n'"twenty/three"$'\n'"twenty/two"$'\n'"two" ]
}

@test "${SUT}: merge branches - should skip branching branches that already exist locally" {
  init_git1
  init_git2

  git clone -q "${GIT1}" "${WORK}/target"
  git -C "${WORK}/target" remote add git2 "${GIT2}"
  git -C "${WORK}/target" fetch -q git2 2> /dev/null
  # make sure branch exists locally
  git -C "${WORK}/target" checkout -b master refs/remotes/origin/master

  run git_merge_branches "${WORK}" "${GIT2}"

  [ "$status" -eq 0 ]

  git -C "${WORK}/target" checkout -q master
  files_on_branch="$(git -C "${WORK}/target" ls-files)"

  [ "${files_on_branch}" = "one"$'\n'"twenty/three"$'\n'"twenty/two"$'\n'"two" ]
}

@test "${SUT}: merge tags - should merge all duplicate tags" {
  init_git1
  init_git2

  git clone -q "${GIT1}" "${WORK}/target"
  git -C "${WORK}/target" remote add git2 "${GIT2}"
  git -C "${WORK}/target" fetch -q git2 2> /dev/null

  git1_id="$(git -C "${WORK}/target" ls-remote --refs --tags origin "tag-two" | cut -f -1)"
  git2_id="$(git -C "${WORK}/target" ls-remote --refs --tags git2 "tag-two" | cut -f -1)"

  run git_merge_tags "${WORK}" "${GIT1}" "${GIT2}"

  [[ "$status" -eq 0 ]]
  [[ "${output}" =~ "Tagging ${git1_id} as 'tag-two-git1'" ]]
  [[ "${output}" =~ "Tagging ${git2_id} as 'tag-two-git2'" ]]

  tags="$(git -C "${WORK}/target" tag -l)"

  [[ "${tags}" =~ "tag-two" ]]
  [[ "${tags}" =~ "tag-two-git1" ]]
  [[ "${tags}" =~ "tag-two-git2" ]]

  git -C "${WORK}/target" checkout -q tag-two
  files_in_tag="$(git -C "${WORK}/target" ls-files)"

  [ "${files_in_tag}" = "five"$'\n'"one"$'\n'"ten/four"$'\n'"twenty/two" ]

  [ "$(git -C "${WORK}/target" show-ref -s tag-two-git1)" = "${git1_id}" ]
  [ "$(git -C "${WORK}/target" show-ref -s tag-two-git2)" = "${git2_id}" ]
}

@test "${SUT}: merge tags - should create unique tag if new tag exists in origin" {
  init_git1
  init_git2

  # create tag so that creating unique tag will create conflict
  git -C "${GIT1}" tag tag-two-git1 master

  git clone -q "${GIT1}" "${WORK}/target"
  git -C "${WORK}/target" remote add git2 "${GIT2}"
  git -C "${WORK}/target" fetch -q git2 2> /dev/null

  git1_id="$(git -C "${WORK}/target" ls-remote --refs --tags origin "tag-two" | cut -f -1)"
  conflict_id="$(git -C "${WORK}/target" ls-remote --refs --tags origin "tag-two-git1" | cut -f -1)"
  git2_id="$(git -C "${WORK}/target" ls-remote --refs --tags git2 "tag-two" | cut -f -1)"

  run git_merge_tags "${WORK}" "${GIT1}" "${GIT2}"

  [[ "$status" -eq 0 ]]
  [[ "${output}" =~ "Tagging ${git1_id} as 'tag-two-git1-1'" ]]
  [[ "${output}" =~ "Tag 'tag-two-git1' exists already" ]]
  [[ "${output}" =~ "Tagging ${git2_id} as 'tag-two-git2'" ]]

  tags="$(git -C "${WORK}/target" tag -l)"

  [[ "${tags}" =~ "tag-two" ]]
  [[ "${tags}" =~ "tag-two-git1" ]]
  [[ "${tags}" =~ "tag-two-git1-1" ]]
  [[ "${tags}" =~ "tag-two-git2" ]]

  [ "$(git -C "${WORK}/target" show-ref -s tag-two-git1-1)" = "${git1_id}" ]
  [ "$(git -C "${WORK}/target" show-ref -s tag-two-git1)" = "${conflict_id}" ]
  [ "$(git -C "${WORK}/target" show-ref -s tag-two-git2)" = "${git2_id}" ]
}

@test "${SUT}: merge tags - should create unique tag if new tag exists in merge repo" {
  init_git1
  init_git2

  # create tag so that creating unique tag will create conflict
  git -C "${GIT2}" tag tag-two-git2 master

  git clone -q "${GIT1}" "${WORK}/target"
  git -C "${WORK}/target" remote add git2 "${GIT2}"
  git -C "${WORK}/target" fetch -q git2 2> /dev/null

  git1_id="$(git -C "${WORK}/target" ls-remote --refs --tags origin "tag-two" | cut -f -1)"
  conflict_id="$(git -C "${WORK}/target" ls-remote --refs --tags git2 "tag-two-git2" | cut -f -1)"
  git2_id="$(git -C "${WORK}/target" ls-remote --refs --tags git2 "tag-two" | cut -f -1)"

  run git_merge_tags "${WORK}" "${GIT1}" "${GIT2}"

  [[ "$status" -eq 0 ]]
  [[ "${output}" =~ "Tagging ${git1_id} as 'tag-two-git1'" ]]
  [[ "${output}" =~ "Tag 'tag-two-git2' exists already" ]]
  [[ "${output}" =~ "Tagging ${git2_id} as 'tag-two-git2-1'" ]]

  tags="$(git -C "${WORK}/target" tag -l)"

  [[ "${tags}" =~ "tag-two" ]]
  [[ "${tags}" =~ "tag-two-git1" ]]
  [[ "${tags}" =~ "tag-two-git2-1" ]]
  [[ "${tags}" =~ "tag-two-git2" ]]

  [ "$(git -C "${WORK}/target" show-ref -s tag-two-git1)" = "${git1_id}" ]
  [ "$(git -C "${WORK}/target" show-ref -s tag-two-git2)" = "${conflict_id}" ]
  [ "$(git -C "${WORK}/target" show-ref -s tag-two-git2-1)" = "${git2_id}" ]
}

@test "${SUT}: merge tags - should create unique tag with next free integer" {
  init_git1
  init_git2

  # create tag so that creating unique tag will create conflict
  git -C "${GIT1}" tag tag-two-git1 master
  git -C "${GIT1}" tag tag-two-git1-1 master
  git -C "${GIT1}" tag tag-two-git1-2 master
  git -C "${GIT1}" tag tag-two-git1-3 master

  git clone -q "${GIT1}" "${WORK}/target"
  git -C "${WORK}/target" remote add git2 "${GIT2}"
  git -C "${WORK}/target" fetch -q git2 2> /dev/null

  git1_id="$(git -C "${WORK}/target" ls-remote --refs --tags origin "tag-two" | cut -f -1)"
  conflict_id="$(git -C "${WORK}/target" ls-remote --refs --tags origin "tag-two-git1" | cut -f -1)"
  git2_id="$(git -C "${WORK}/target" ls-remote --refs --tags git2 "tag-two" | cut -f -1)"

  run git_merge_tags "${WORK}" "${GIT1}" "${GIT2}"

  [[ "$status" -eq 0 ]]
  [[ "${output}" =~ "Tagging ${git1_id} as 'tag-two-git1-4'" ]]
  [[ "${output}" =~ "Tag 'tag-two-git1' exists already" ]]
  [[ "${output}" =~ "Tag 'tag-two-git1-1' exists already" ]]
  [[ "${output}" =~ "Tag 'tag-two-git1-2' exists already" ]]
  [[ "${output}" =~ "Tag 'tag-two-git1-3' exists already" ]]
  [[ "${output}" =~ "Tagging ${git2_id} as 'tag-two-git2'" ]]

  tags="$(git -C "${WORK}/target" tag -l)"

  [[ "${tags}" =~ "tag-two" ]]
  [[ "${tags}" =~ "tag-two-git1" ]]
  [[ "${tags}" =~ "tag-two-git1-1" ]]
  [[ "${tags}" =~ "tag-two-git1-2" ]]
  [[ "${tags}" =~ "tag-two-git1-3" ]]
  [[ "${tags}" =~ "tag-two-git1-4" ]]
  [[ "${tags}" =~ "tag-two-git2" ]]

  [ "$(git -C "${WORK}/target" show-ref -s tag-two-git1)" = "${conflict_id}" ]
  [ "$(git -C "${WORK}/target" show-ref -s tag-two-git1-1)" = "${conflict_id}" ]
  [ "$(git -C "${WORK}/target" show-ref -s tag-two-git1-2)" = "${conflict_id}" ]
  [ "$(git -C "${WORK}/target" show-ref -s tag-two-git1-3)" = "${conflict_id}" ]
  [ "$(git -C "${WORK}/target" show-ref -s tag-two-git1-4)" = "${git1_id}" ]
  [ "$(git -C "${WORK}/target" show-ref -s tag-two-git2)" = "${git2_id}" ]
}

@test "${SUT}: merge tags - should add all unique tags" {
  init_git1
  init_git2

  git clone -q "${GIT1}" "${WORK}/target"
  git -C "${WORK}/target" remote add git2 "${GIT2}"
  git -C "${WORK}/target" fetch -q git2 2> /dev/null

  git2_tag_three_id="$(git -C "${WORK}/target" ls-remote --refs --tags git2 "tag-three" | cut -f -1)"

  run git_merge_tags "${WORK}" "${GIT1}" "${GIT2}"

  [[ "$status" -eq 0 ]]

  tags="$(git -C "${WORK}/target" tag -l)"

  [[ "${tags}" =~ "tag-three" ]]
  [ "$(git -C "${WORK}/target" show-ref -s tag-three)" = "${git2_tag_three_id}" ]
}
