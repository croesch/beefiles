#!/usr/bin/env bats

load sut
SUT="git-merge-repos.sh"

setup() {
  . "${SRC}/${SUT}"
  PATH="${SRC}/:$PATH"

  GIT1="${BATS_TMPDIR}/git1"
  GIT2="${BATS_TMPDIR}/git2"
  WORK="${BATS_TMPDIR}/work"

  mkdir -p "${GIT1}"
  mkdir -p "${GIT2}"
  mkdir -p "${WORK}"

  pushd "${GIT1}" > /dev/null
  echo "1" > one
  echo "2" > two
  echo "3" > three
  mkdir ten
  echo "13" > ten/three

  git init -q
  git add one
  git commit -qm "Add one."

  git branch dev
  git branch only-in-one
  git add two
  git commit -qm "Add two."

  git checkout -q dev
  git add ten
  git commit -qm "Add ten-three."

  git checkout -q only-in-one
  git add three
  git commit -qm "Add three."

  popd > /dev/null

  pushd "${GIT2}" > /dev/null
  mkdir twenty
  echo "22" > twenty/two
  echo "23" > twenty/three
  echo "24" > twenty/four
  echo "5" > five

  git init -q
  git add twenty/two
  git commit -qm "Add twenty-two."

  git branch dev
  git branch only-in-two
  git add twenty/three
  git commit -qm "Add twenty-three."

  git checkout -q dev
  git add twenty/four
  git commit -qm "Add twenty-four."

  git checkout -q only-in-two
  git add five
  git commit -qm "Add five."

  popd > /dev/null
}

teardown() {
  rm -fr "${GIT1}"
  rm -fr "${GIT2}"
  rm -fr "${WORK}"
  return 0
}

@test "${SUT}: clone - clones source into target" {
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
  ln -s "${GIT1}" "${WORK}/target"
  run git_add_remote_and_fetch "${WORK}" "${GIT2}"

  [ "$status" -eq 0 ]
  [[ "$output" =~ "Adding '${GIT2}' as remote in '${WORK}/target'" ]]
  [ `git -C "${WORK}/target" remote get-url git2` = "${GIT2}" ]
}

@test "${SUT}: remote - fetches from merged repo" {
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
  skip "tags not yet considered"
}
