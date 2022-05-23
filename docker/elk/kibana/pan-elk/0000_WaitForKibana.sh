#!/bin/bash
#-----------------------------------------------------
echo "$(date '+%F-%H:%M:%S.%N' ) $(uname -a)"
echo "$(date '+%F-%H:%M:%S.%N' ) $(whoami) running $(basename $0) from $(pwd)"
NOW=$(date '+%F-%H%M%S')
#-----------------------------------------------------
# ============================================================================================
echo -e "\nSourcing docker-compose env file ..."
ENVFILE="$HOME/.env"
. ${ENVFILE}; rc=$?

if [ "${rc}" -eq "0" ]
then
  echo "   ... $(ls -l ${ENVFILE})"
else
  echo -e "\n\n problem to set env - check file ${ENVFILE} - exiting"
  exit ${rc}
fi
# ---------------------------------------------------------------------------------------------
echo -e "\nFetching CA Certificate from running Kibana container ..."
KBCACRTFILE="${KIBANA_HOME}/config/certs/ca/ca.crt"
HOSTLCAFILE="$HOME/elk/setup_certs/current_ca.crt"
rc="x"
unset KBCONTAINER; sec=0
while [ "$(docker ps 2>/dev/null|grep kibana:${STACK_VERSION})" == "" ]
do
  echo "   ...waiting for kibana container to show up [ ${sec} seconds ]"
  sleep 30
  (( sec=$sec+30 ))
done
sleep 5
KBCONTAINER=( "$(docker ps 2>/dev/null|grep "kibana:${STACK_VERSION}" |cut -d' ' -f 1|tr -d ' ')" )
if [ ! -z "$(echo ${KBCONTAINER[0]})" ]
then
  rc=1; while [ "${rc}" != "0" ]
  do
    sleep 5
    rc="$(docker cp ${KBCONTAINER}:${KBCACRTFILE} ${HOSTLCAFILE} >/dev/null 2>&1)$?"
    echo "   ... waiting to copy CA cert from kibana container"
  done
  sync
fi
[ "${rc}" == "0" ] && UPDCA="yes"
# ---------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------
if [ "${UPDCA}" == "yes" ]
then
  echo -e "\nFixing host CA for ease of curl ..."
  sudo cp ${HOSTLCAFILE} /usr/local/share/ca-certificates && sync
  sudo update-ca-certificates
else
  echo "Can not get CA certificate from running kibana container - exiting"
  echo "Note that curl might while some TLS servers might not eat"
  echo "a self-signed cert if it is not in their host trust store"
  exit 5
fi
# ---------------------------------------------------------------------------------------------
echo -e "\nWaiting for Kibana Service ..."
rc1=1;rc2=1
while [ "$(echo ${rc1}${rc2})" != "00" ];
do
  echo "   ... trying connectivity to ES until good or SIG - every 10 sec"
  curl -I --cacert ${HOSTLCAFILE} https://localhost:9200 -u elastic:${ELASTIC_PASSWORD} >/dev/null; rc1=$?
  curl --cacert ${HOSTLCAFILE} https://localhost:9200 -u elastic:${ELASTIC_PASSWORD} > /dev/null; rc2=$?
  sleep 10
  if [ "$(echo ${rc1}${rc2})" == "00" ]
  then
  echo -e "---------------------------------------------------------------------------/n/n/n"
    echo "   ...connectivity looks good now, releasing to exit!"
    curl -I --cacert ${HOSTLCAFILE} https://localhost:9200 -u elastic:${ELASTIC_PASSWORD}
    curl --cacert ${HOSTLCAFILE} https://localhost:9200 -u elastic:${ELASTIC_PASSWORD}
  fi
done
echo -e "\nHanding over to feed-pan-elk with carrots ..."
chmod 755 "${HOME}/elk/kibana/pan-elk/feed-pan-elk.sh"
export ELASTIC_PASSWORD
export LOGSTASH_PASSWORD
export HOSTLCAFILE
${HOME}/elk/kibana/pan-elk/feed-pan-elk.sh
echo "feed-pan-elk returned with exit :$?"
