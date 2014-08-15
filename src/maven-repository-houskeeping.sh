#!/bin/bash

LOGNAME=maven-housekeeping.log
LOGFILE="/var/log/${LOGNAME}"
TMPLOG="/tmp/${LOGNAME}"
MAX_LOG_SIZE=1000000

AGE=31

if [ "$#" -eq 1 ]
then
  LOGFILE="${1}"
fi

if [ -f "${LOGFILE}" ]
then
  mv ${LOGFILE} ${TMPLOG}
  tail -n ${MAX_LOG_SIZE} ${TMPLOG} > ${LOGFILE}
fi

date >> ${LOGFILE}
echo "------------------------------------------------------------------------" >> ${LOGFILE}

if [ -z "${M2_REPO}" ]
then
  M2_REPO=$(mvn help:evaluate -Dexpression=settings.localRepository | grep -v '[INFO]' | grep -v 'Download')
  echo "M2_REPO was not set, set it to '$M2_REPO'" >> ${LOGFILE}
fi

find "${M2_REPO}" -name '*jar' -atime +${AGE} -exec rm -rfv {} \; >> ${LOGFILE}
find "${M2_REPO}" -name '*swf' -atime +${AGE} -exec rm -rfv {} \; >> ${LOGFILE}
find "${M2_REPO}" -name '*swc' -atime +${AGE} -exec rm -rfv {} \; >> ${LOGFILE}
echo >> ${LOGFILE}
