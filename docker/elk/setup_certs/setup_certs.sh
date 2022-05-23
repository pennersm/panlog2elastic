#!/bin/bash
# @Author: mpenners
# @Date:   2022-05-06T17:47:21+02:00
# @Filename: setup_certs.sh
# @Last modified by:   mpenners
# @Last modified time: 2022-05-09T21:11:55+02:00
#-----------------------------------------------------
echo "$(date '+%F-%H:%M:%S.%N' ) $(uname -a)"
echo "$(date '+%F-%H:%M:%S.%N' ) $(whoami) running $(basename $0) from $(pwd)"
NOW=$(date '+%F-%H%M%S')
ENVFILE="setup_certs/.env"
INSTCFG="${CERT_ROOT}/instances.yml"
#-----------------------------------------------------
if [ ! -x "${ENVFILE}" ]
then
  echo -e "\nCan not find x-able ENVFILE: \"${ENVFILE}\""
  exit 1
fi
. ${ENVFILE}
#-----------------------------------------------------
echo -e "\nHandling user and file permissions ..."
# might be we can remove this not yet clear to me
# current understanding: the numerical uid is mapped-through to the volume
# and will use same uid on the container hence I create that dir and user
for DIRS in ${ES_HOME} ${LS_HOME} ${KIBANA_HOME}
do
  [ -d ${DIRS} ] || mkdir ${DIRS}
  chown -R ${ELKUID}:${ELKUID} ${DIRS}
  chmod u+rwx ${DIRS}
  echo "   ... $(ls -ldn ${DIRS})"
done
#-----------------------------------------------------
echo -e "\nHandling volume status ..."
if [ -d "${CERT_ROOT}" ] && [ ! -w "${CERT_ROOT}" ]
then
  echo "   ... CERT_ROOT exists but seems to have odd permissions - exiting"
  exit 5
fi
if [ ! -d "${CERT_ROOT}" ]
then
  rc="$(mkdir -p ${CERT_ROOT} > /dev/null 2>&1)$?"
  if [ "${rc}" == "0" ]
  then
    echo "   ... starting in fresh CERT_ROOT directory"
  else
    echo "   ... no CERT_ROOT nor can I create it - exiting"
    exit 5
  fi
else
  echo "   ... found existing CERT_ROOT : $(ls -ld ${CERT_ROOT}) "
  echo "   ... check whats in that dir  :"
  EXCERTS=( $(find ${CERT_ROOT}/ -mindepth 1 -exec readlink -f {} \;) )
  if [ "${#EXCERTS[@]}" == "0" ]
  then
    echo "   ... existing CERT_ROOT is empty!"
    EXCA="empty"
  else
    EXCA="noempty"
    for i in $(seq 0 ${#EXCERTS[@]})
    do
      echo ${EXCERTS[$i]}
    done
  fi
fi
if [ "${EXCA}" == "noempty" ]
then
  if [ -x "${CERT_ROOT}" ] && [[ ${BACKUP_CERTS} =~ ^[Tt]{1}rue$ ]]
  then
    echo "   ... trying to backup existing CERT_ROOT into $(pwd)"
    ARCHNAME=$(echo ${CERT_ROOT}| sed -s 's/\//-/g' )
    tar -cvf certsbackup-${ARCHNAME}-${NOW}.tar ${CERT_ROOT}/
    sleep 1 && sync
    tar -tf certsbackup-${ARCHNAME}-${NOW}.tar
  fi
  if [ -x "${CERT_ROOT}" ] && [[ ${DELETE_CERTS} =~ ^[Tt]{1}rue$ ]]
  then
    echo "   ... trying to delete old certificates in ${CERT_ROOT}"
    find ${CERT_ROOT}/ -type d -exec rm -rf {} \;
  fi
fi
#-----------------------------------------------------
echo -e "\nChecking CA ..."
if [ -f "${CERT_ROOT}/ca.zip" ]; then
  echo "   ... using existing ca:"; ls -la ${CERT_ROOT}/ca.zip;
else
  echo "   ... creating CA in directory ${CERT_ROOT}";
  ${ES_HOME}/bin/elasticsearch-certutil ca --silent --pem -out ${CERT_ROOT}/ca.zip;
fi;
sleep 1 && sync && unzip ${CERT_ROOT}/ca.zip -d ${CERT_ROOT};
echo "   ... CA certs: "; ls -la ${CERT_ROOT}/ca/
#---------------------------------------------------------
echo -e "\nCreating instance config ..."
if [ -f "${INSTCFG}" ];
then
  rc="$(rm -f ${INSTCFG})$?"
  echo "   ... found old config - rm it exited with status ${rc}"
  if [ "${rc}" != "0" ] && [ -f "${INSTCFG}" ]
  then
    echo "found existing instance config and can not remove it."
    echo "make sure to have CERT path wiped or fix the volume - exiting"
  fi
else
  echo "   ... creating list of new cluster certs";
  echo "instances:" > ${INSTCFG}
  for i in $(seq -f "%02g" 1 ${ESINSTS})
  do
    echo -ne "  - name: es${i}\n    dns:\n    - es${i}\n    - localhost\n    ip:\n    - 127.0.0.1\n" >> ${INSTCFG}
  done
  for i in $(seq -f "%02g" 1 ${KIINTS})
  do
    echo -ne "  - name: kibana${i}\n    dns:\n    - kibana${i}\n    - localhost\n    ip:\n    - 127.0.0.1\n" >> ${INSTCFG}
  done
  for i in $(seq -f "%02g" 1 ${LSINTS})
  do
    echo -ne "  - name: ls${i}\n    dns:\n    - ls${i}\n    - localhost\n    ip:\n    - 127.0.0.1\n" >> ${INSTCFG}
  done
  sleep 1 && sync
  ls -l ${INSTCFG}; cat ${INSTCFG}
fi
#-------------------------------------------------------------------
echo -e "\nMaking Certs out of instance config ..."
${ES_HOME}/bin/elasticsearch-certutil cert --silent --pem -out ${CERT_ROOT}/certs.zip --in ${INSTCFG} --ca-cert ${CERT_ROOT}/ca/ca.crt --ca-key ${CERT_ROOT}/ca/ca.key;
sleep 1 && sync;
echo "   ... created cert.zip: " ; find ${CERT_ROOT};
unzip ${CERT_ROOT}/certs.zip -d ${CERT_ROOT};
echo "   ... unzipped certs directory: ";
find ${CERT_ROOT}/ -printf "%p:\t%u:%g\t%m\n" ;
echo "   ... trying to clean zipfiles";
rm ${CERT_ROOT}/ca.zip 2>/dev/null;
rm ${CERT_ROOT}/certs.zip 2>/dev/null;
#---------------------------------------------------------------------
echo -e "\nPrepare volume directory structure ..." ;
es_instances=( $(cat ${INSTCFG} |grep "\- name: es"|cut -d':' -f 2|sed -e 's/^[ \t]*//') ) ;
echo "   ... es instances: ${es_instances[@]}"
mkdir -p ${ES_HOME}/config/certs
for inst in $(seq -f "%02g" 1 ${ESINSTS})
do
  cp -r ${CERT_ROOT}/es${inst} ${ES_HOME}/config/certs/
done
cp -r ${CERT_ROOT}/ca ${ES_HOME}/config/certs/
chown -R ${ELKUID}:${ELKUID} ${ES_HOME}
find ${ES_HOME}/config/certs/ -type f -name "*.crt" -exec chmod 750 {} \;
find ${ES_HOME}/config/certs/ -type f -name "*.key" -exec chmod 650 {} \;
sleep 1 && sync
find ${ES_HOME}/config/certs/ -type f -printf "%p:\t%u:%g\t%m\n"
#-- -- -- -- -- -- --
ls_instances=( $(cat ${INSTCFG} |grep "\- name: ls"|cut -d':' -f 2|sed -e 's/^[ \t]*//') ) ;
echo "   ... ls instances: ${ls_instances[@]}"
mkdir -p ${LS_HOME}/config/certs
for inst in $(seq -f "%02g" 1 ${LSINSTS})
do
  cp -r ${CERT_ROOT}/ls${inst} ${LS_HOME}/config/certs/
done
cp -r ${CERT_ROOT}/ca ${LS_HOME}/config/certs/
chown -R ${ELKUID}:root ${LS_HOME}/config/certs/
find ${LS_HOME}/config/certs/ -type f -name "*.crt" -exec chmod 750 {} \;
find ${LS_HOME}/config/certs/ -type f -name "*.key" -exec chmod 650 {} \;
sleep 1 && sync
find ${LS_HOME}/config/certs/ -type f -printf "%p:\t%u:%g\t%m\n"
#-- -- -- -- -- -- --
kibana_instances=( $(cat ${INSTCFG} |grep "\- name: kibana"|cut -d':' -f 2|sed -e 's/^[ \t]*//') ) ;
echo "   ... kibana instances: ${kibana_instances[@]}"
mkdir -p ${KIBANA_HOME}/config/certs
for inst in $(seq -f "%02g" 1 ${KIINSTS})
do
  cp -r ${CERT_ROOT}/ls${inst} ${KIBANA_HOME}/config/certs/
done
cp -r ${CERT_ROOT}/ca ${KIBANA_HOME}/config/certs/
chown -R ${ELKUID}:root ${KIBANA_HOME}/config/certs/
find ${KIBANA_HOME}/config/certs/ -type f -name "*.crt" -exec chmod 750 {} \;
find ${KIBANA_HOME}/config/certs/ -type f -name "*.key" -exec chmod 650 {} \;
sleep 1 && sync
find ${KIBANA_HOME}/config/certs/ -type f -printf "%p:\t%u:%g\t%m\n"
#---------------------------------------------------------------------
echo -e "\nSetting Credentials and fix permissions"
echo "   ... waiting for Elasticsearch availability (5sec loops)";
until curl -s --cacert ${CERT_ROOT}/ca/ca.crt https://es01:9200 | grep -q "missing authentication credentials"; do sleep 5; done;
echo "   ... set Elasticsearch password"
echo -e "\nSetting kibana_system password";
until curl -s -X POST --cacert ${CERT_ROOT}/ca/ca.crt -u elastic:${ELASTIC_PASSWORD} -H "Content-Type: application/json" https://es01:9200/_security/user/kibana_system/_password -d "{\"password\":\"${KIBANA_PASSWORD}\"}" | grep -q "^{}"; do sleep 10; done;
echo -e "\nAll done!";
exit 0
