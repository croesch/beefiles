#!/bin/bash

LOGNAME=maven-housekeeping.log
LOGFILE="/var/log/${LOGNAME}"
TMPLOG="/tmp/${LOGNAME}"
MAX_LOG_SIZE=1000000

AGE=31

mv ${LOGFILE} ${TMPLOG}
tail -n ${MAX_LOG_SIZE} ${TMPLOG} > ${LOGFILE}

date >> ${LOGFILE}
echo "------------------------------------------------------------------------" >> ${LOGFILE}
find "${M2_REPO}" -name '*jar' -atime +${AGE} -exec rm -rfv {} \; >> ${LOGFILE}
find "${M2_REPO}" -name '*swf' -atime +${AGE} -exec rm -rfv {} \; >> ${LOGFILE}
find "${M2_REPO}" -name '*swc' -atime +${AGE} -exec rm -rfv {} \; >> ${LOGFILE}
echo >> ${LOGFILE}
