#!/bin/bash
#-----------------------------------------------------
echo "$(date '+%F-%H:%M:%S.%N' ) $(uname -a)"
echo "$(date '+%F-%H:%M:%S.%N' ) $(whoami) running $(basename $0) from $(pwd)"
NOW=$(date '+%F-%H%M%S')
#-----------------------------------------------------
CARDIR="${HOME}/elk/kibana/pan-elk/carrots/"
[ ! -d "${CARDIR}" ] && echo "WARNING: Can not see directory ${CARDIR}"
if [ -z "${ELASTIC_PASSWORD}" ] || [ -z "${LOGSTASH_PASSWORD}" ] || [ -z "${HOSTLCAFILE}" ]
then
  echo -n "\n\nERROR: passwords and or CA file not in env - exiting\n\n"
  exit 5
fi


echo -e "/nCollecting carrots ... "
CARROTS=( $(find ${CARDIR} -name '[0-9][0-9][0-9][0-9]_*'|sort) )
echo "   ... found ${#CARROTS[@]} items"
echo -e "\n--------------------------------------------------------------------\n"
for order in $(seq 0 ${#CARROTS[@]})
do
  [ -f ${CARROTS[${order}]} ] && chmod u+x ${CARROTS[${order}]}
  echo "feeding carrot : ${CARROTS[${order}]}"
  ${CARROTS[${order}]}
  echo -e "\n\nCarrot ${CARROTS[${order}]} exited with $?"
  echo -e "--------------------------------------------------------------------\n\n"
done
echo "   ... all done!"
unset ELASTIC_PASSWORD
exit 0
