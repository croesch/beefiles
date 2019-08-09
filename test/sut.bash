#!/bin/bash

SRC="${BATS_TEST_DIRNAME}/../src"

# This creates a git repo with the following result
# A--B master
# |\
# | C dev
# |\
# | D only-in-one
# | ^
# | tag-one
#  \
#   E tag-two
function prepare_example_repo_one() {
  echo "1" > one
  echo "2" > two
  echo "3" > three
  mkdir ten
  echo "13" > ten/three
  echo "14" > ten/four

  git init -q
  git add one
  git commit -qm "Add one."

  git branch dev
  git branch only-in-one
  git add two
  git commit -qm "Add two."
  git tag tag-one

  git checkout -q dev
  git add ten/three
  git commit -qm "Add ten-three."

  git checkout -q only-in-one
  git add three
  git commit -qm "Add three."

  git checkout -q HEAD~1
  git add ten/four
  git commit -qm "Add ten-four."
  git tag tag-two

  git checkout -q only-in-one
}

# This creates a git repo with the following result
# tag-three
# v
# A--B master
# |\
# | C dev
#  \
#   D only-in-two
#   ^
#   tag-two
function prepare_example_repo_two() {
  mkdir twenty
  echo "22" > twenty/two
  echo "23" > twenty/three
  echo "24" > twenty/four
  echo "5" > five

  git init -q
  git add twenty/two
  git commit -qm "Add twenty-two."
  git tag tag-three

  git branch dev
  git branch only-in-two
  git add twenty/three
  git commit -qm "Add twenty-three."
  git tag tag-two

  git checkout -q dev
  git add twenty/four
  git commit -qm "Add twenty-four."

  git checkout -q only-in-two
  git add five
  git commit -qm "Add five."
}
