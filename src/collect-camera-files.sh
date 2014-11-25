#!/bin/bash

if [ "$#" -lt 1 ]
then
  echo "Wrong usage.."
  exit 1
else
  CAMERA="${1}"
fi

find "${CAMERA}/DCIM/" -type f -iregex .*\.jpe?g |
while read file
do
  echo -n "${file} "
  datetaken=$(exiftool -s3 '-CreateDate' -d '%Y-%m-%d' "${file}")
  yeartaken=$(exiftool -s3 '-CreateDate' -d '%Y' "${file}")
  filename=$(basename "${file}")
  target="${HOME}/Pictures/${yeartaken}/${datetaken}/"
  mkdir -p "${target}"
  echo -n "."
  rsync -a --remove-source-files "${file}" "${target}"
  echo -n "."
  jpegoptim -q "${target}${filename}"
  echo "done."
done

find "${CAMERA}/MP_ROOT/" -type f -iregex .*\.mp4 |
while read file
do
  echo -n "${file} "
  datetaken=$(exiftool -s3 '-CreateDate' -d '%Y-%m-%d' "${file}")
  yeartaken=$(exiftool -s3 '-CreateDate' -d '%Y' "${file}")
  filename=$(basename "${file}")
  target="${HOME}/Pictures/${yeartaken}/${datetaken}/videos/"
  mkdir -p "${target}"
  echo -n "."
  rsync -a --remove-source-files "${file}" "${target}"
  echo "done."
done

find "${CAMERA}/MP_ROOT/" -type f -iregex .*\.thm |
while read file
do
  echo -n "${file} "
  rm "${file}"
  echo "removed."
done

