#!/bin/sh

TMPDIR="$(mktemp -d)"
TMPFILE="${TMPDIR}/$$.tmp"
gpg -o "${TMPFILE}" -d "${1}"
evince $TMPFILE
rm -r "${TMPDIR}"
