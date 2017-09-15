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
  target="${PATH_TO_PICTURES}/${yeartaken}/${datetaken}/"
  mkdir -p "${target}"
  echo -n "."
  rsync --remove-source-files "${file}" "${target}"
  echo -n "."
  jpegoptim -q "${target}${filename}"
  # temporary fix for file rights
  chmod g+rw "${target}${filename}"
  echo "done."
done

find "${CAMERA}/DCIM/" -type f -iregex .*\.arw |
while read file
do
  echo -n "${file} "
  filename=$(basename "${file}")
  target="${PATH_TO_RAWS}/"
  echo -n "."
  rsync --remove-source-files "${file}" "${target}"
  echo -n "."
  # temporary fix for file rights
  chmod g+rw "${target}${filename}"
  echo "done."
done

find "${CAMERA}/MP_ROOT/" -type f -iregex .*\.mp4 |
while read file
do
  echo -n "${file} "
  datetaken=$(exiftool -s3 '-CreateDate' -d '%Y-%m-%d' "${file}")
  yeartaken=$(exiftool -s3 '-CreateDate' -d '%Y' "${file}")
  filename=$(basename "${file}")
  target="${PATH_TO_PICTURES}/${yeartaken}/${datetaken}/videos/"
  mkdir -p "${target}"
  echo -n "."
  rsync --remove-source-files "${file}" "${target}"
  # temporary fix for file rights
  chmod g+rw "${target}${filename}"
  echo "done."
done

find "${CAMERA}/MP_ROOT/" -type f -iregex .*\.thm |
while read file
do
  echo -n "${file} "
  rm "${file}"
  echo "removed."
done

