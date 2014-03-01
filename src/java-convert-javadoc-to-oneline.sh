#!/bin/bash

classDirectory=""

if [ "$#" -eq 1 ]
then
  classDirectory="${1}"
elif
  echo "Wrong usage!"
  echo "Argument 1 must be base directory of source files, e.g. project/src/main/java"
  exit 1
fi

for file in `find "${classDirectory}" -type f -name *.java`
do
  perl -i -p -e 'undef $/; s/\/\*\*[ \t]*\r?\n {0,3}\* ([^\r\n*]{1,111}) *\r?\n *\*\/*\//\/** \1 *\//g' $file
done
