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

  pushd "${GIT1}"
  echo "1" > one
  echo "2" > two
  echo "3" > three
  mkdir ten
  echo "13" > ten/three

  git init
  git add one
  git commit -m "Add one."

  git branch dev
  git branch only-in-one
  git add two
  git commit -m "Add two."

  git checkout dev
  git add ten
  git commit -m "Add ten-three."

  git checkout only-in-one
  git add three
  git commit -m "Add three."

  popd

  pushd "${GIT2}"
  mkdir twenty
  echo "22" > twenty/two
  echo "23" > twenty/three
  echo "24" > twenty/four
  echo "5" > five

  git init
  git add twenty/two
  git commit -m "Add twenty-two."

  git branch dev
  git branch only-in-two
  git add twenty/three
  git commit -m "Add twenty-three."

  git checkout dev
  git add twenty/four
  git commit -m "Add twenty-four."

  git checkout only-in-two
  git add five
  git commit -m "Add five."

  popd
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
