#!/bin/bash

if [ "$#" -lt 1 ]
then
  echo "Wrong usage.."
  exit 1
fi

if [ -f ~/.bash_env ]; then
    source ~/.bash_env
fi

__move_file_to_destination () {
  rsync --remove-source-files "${1}" "${2}"
  echo -n "."
}

__collect_pictures () {
  find "${1}" -type f -iregex .*\.jpe?g |
  while read file
  do
    echo -n "${file} "
    datetaken=$(exiftool -s3 '-CreateDate' -d '%Y-%m-%d' "${file}")
    yeartaken=$(exiftool -s3 '-CreateDate' -d '%Y' "${file}")
    filename=$(basename "${file}")
    target="${PATH_TO_PICTURES}/${yeartaken}/${datetaken}/"
    mkdir -p "${target}"
    echo -n "."
    __move_file_to_destination "${file}" "${target}"
    jpegoptim -q "${target}${filename}"
    # temporary fix for file rights
    chmod g+rw "${target}${filename}"
    echo "done."
  done
}

__collect_raws () {
  find "${1}" -type f -iregex .*\.arw |
  while read file
  do
    echo -n "${file} "
    filename=$(basename "${file}")
    target="${PATH_TO_RAWS}/"
    echo -n "."
    __move_file_to_destination "${file}" "${target}"
    # temporary fix for file rights
    chmod g+rw "${target}${filename}"
    echo "done."
  done
}

__collect_movies () {
  find "${1}" -type f -iregex ".*\.\(mts\|mp4\)" |
  while read file
  do
    echo -n "${file} "
    datetaken=$(exiftool -s3 '-CreateDate' -d '%Y-%m-%d' "${file}")
    yeartaken=$(exiftool -s3 '-CreateDate' -d '%Y' "${file}")
    filename=$(basename "${file}")
    target="${PATH_TO_PICTURES}/${yeartaken}/${datetaken}/videos/"
    mkdir -p "${target}"
    echo -n "."
    __move_file_to_destination "${file}" "${target}"
    # temporary fix for file rights
    chmod g+rw "${target}${filename}"
    echo "done."
  done
}

__delete_thumbnails () {
  find "${1}" -type f -iregex ".*\.\(thm\|cpi\)" |
  while read file
  do
    echo -n "${file} "
    rm "${file}"
    echo "removed."
  done
}

while getopts ":c:d:" opt; do
  case $opt in
    c)
      DIRECTORY="${OPTARG}"
      __collect_pictures "${DIRECTORY}/DCIM/"
      __collect_raws "${DIRECTORY}/DCIM/"
      __collect_movies "${DIRECTORY}/MP_ROOT/"
      __delete_thumbnails "${DIRECTORY}/MP_ROOT/"
      __collect_movies "${DIRECTORY}/PRIVATE/"
      __delete_thumbnails "${DIRECTORY}/PRIVATE/"
      ;;
    d)
      DIRECTORY="${OPTARG}"
      __collect_pictures "${DIRECTORY}"
      __collect_raws "${DIRECTORY}"
      __collect_movies "${DIRECTORY}"
      __delete_thumbnails "${DIRECTORY}"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done
