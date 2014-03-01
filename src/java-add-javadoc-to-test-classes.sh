#!/bin/bash

testClassDirectory=""

if [ "$#" -eq 1 ]
then
  testClassDirectory="${1}"
elif
  echo "Wrong usage!"
  echo "Argument 1 must be base directory of test classes, e.g. project/src/test/java"
  exit 1
fi

for file in `find "${testClassDirectory}" -type f -name *.java`
do
  perl -i -p -e 'undef $/; s/\n\r?\npublic class Test([a-zA-Z]+) /\n\n\/** Provides tests for {\@link \1}. *\/\npublic class Test\1 /m' "${file}"
done
