#!/bin/bash

for file in $(find . -name \*pom.xml)
do
  echo $file
  echo "----"
  maven-unify-properties-for-dependency-versions -f $file | sed 's/^/  /'
done
