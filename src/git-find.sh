#!/bin/bash

case $# in
  1)  
    "${0}" "refs/remotes/origin" "$1"
    ;;
  2)
    for branch in `git for-each-ref --format="%(refname)" $1`; do
      found=`git ls-tree -r --name-only $branch | grep "$2"`
      if [ $? -eq 0 ]; then
        echo "${branch#$1/}: ($found)"
      fi  
    done
    ;;
  *)
    echo "Usage:"
    echo "  ${0} regex"
    echo "    (where refs/remotes/origin will be searched)"
    echo "  ${0} namespace regex"
    ;;
esac

