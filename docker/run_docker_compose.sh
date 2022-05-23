#!/bin/bash
# @Author: mpenners
# @Date:   2022-04-08T09:40:53+02:00
# @Filename: run_docker_compose.sh
# @Last modified by:   mpenners
# @Last modified time: 2022-05-10T13:29:44+02:00
# ============================================================================================
echo "$(date '+%F-%H:%M:%S.%N' ) $(uname -a)"
echo "$(date '+%F-%H:%M:%S.%N' ) $(whoami) running $(basename $0) from $(pwd)"
NOW=$(date '+%F-%H%M%S')
MYLOG="./dockercup.log"
# ============================================================================================
echo -e "\n Sourcing docker-compose env file ..." | tee -a ${MYLOG} 2>&1
ENVFILE="./.env"
. ${ENVFILE}; rc=$?

if [ "${rc}" -eq "0" ]
then
  echo "   ... $(ls -l ${ENVFILE})"| tee -a ${MYLOG} 2>&1
else
  echo -e "\n\n problem to set env - check file ${ENVFILE} - exiting"| tee -a ${MYLOG} 2>&1
  exit ${rc}
fi

# ---------------------------------------------------------------------------------------------
echo -e "\nFetch public IP of ES instance again ..."| tee -a ${MYLOG} 2>&1
PUBIP="$(curl checkip.amazonaws.com 2>/dev/null)"
EC2HN="$(dig +short -x ${PUBIP} 2>/dev/null)"; EC2HN="${EC2HN::-1}"
( [ -z "${PUBIP}" ] || [ -z "${EC2HN}" ] ) && echo "ERROR: Can not determine public IP and hostname"
export PUBIP
sudo sed -i "i2 ${PUBIP}  ${EC2HN::-1}" /etc/hosts
export KIBANA_PUBURL="http://${EC2HN}:${KIBANA_PORT}/pan-elk"
if [ "$(grep "KIBANA_PUBURL=" ${ENVFILE} >/dev/null 2>&1)$?" != "0" ]; then
  sed -i -e "$a KIBANA_PUBURL=\"${KIBANA_PUBURL}\"" $ENVFILE
fi
echo "   ... kibana will be reachable under following URL"| tee -a ${MYLOG} 2>&1
echo "${KIBANA_PUBURL}"| tee -a ${MYLOG} 2>&1
sed -i -e "$a kibana will be reachable under :\n ${KIBANA_PUBURL}" $HOME/.bashrc
# ---------------------------------------------------------------------------------------------
echo -e "\nSetting kernel parameters ..."| tee -a ${MYLOG} 2>&1
set_kparm () {
  par=$(echo $1|cut -d'=' -f 1|tr -d ' ')
  val=$(echo $1|cut -d'=' -f 2|tr -d ' ')
  rc="$(sudo sysctl ${par} >/dev/null 2>&1)$?"
  if [ "${rc}" == "0" ]; then
    sudo sed -i -e "$a ${par}=${val}" /etc/sysctl.conf
    act="$(sudo sysctl -w vm.max_map_count=262144 >/dev/null 2>&1)$?"
    if [ "${act}" == "0" ]; then
        echo "   ... $(sudo sysctl vm.max_map_count)"| tee -a ${MYLOG} 2>&1
    else
      echo -e "\n\n Problem setting kernel parameter ${par} !"| tee -a ${MYLOG} 2>&1
    fi
  else
    echo "   ... can not sysctl this parameter : ${par}"| tee -a ${MYLOG} 2>&1
  fi
}
set_kparm vm.max_map_count=262144
#set_kparm LimitNOFILE=65535
#set_kparm LimitNPROC=4096
# ---------------------------------------------------------------------------------------------
echo -e "\nPrepare setup pan-elk after containers are up ..."| tee -a ${MYLOG} 2>&1
WAITLOG="${HOME}/wait_for_kibana.log"
nohup ${HOME}/elk/kibana/pan-elk/0000_WaitForKibana.sh > ${WAITLOG} 2>&1 &
echo "   ... started 000_WaitForKibana.sh"| tee -a ${MYLOG} 2>&1
jobs| tee -a ${MYLOG} 2>&1
# ---------------------------------------------------------------------------------------------
# ---------------------------------------------------------------------------------------------
echo -e "\nSet host UID and GID for ELK volumes ..."| tee -a ${MYLOG} 2>&1
# docker copies file permissions from the host to the container verbatim
# https://medium.com/@nielssj/docker-volumes-and-file-system-permissions-772c1aee23ca
if [ "$(getent passwd ${ELKUID} >/dev/null)$?" != "0" ]
then
  if [ "$(useradd -u ${ELKUID} elk >/dev/null 2>&1)$?" != " 0" ] || [ "$(groupadd -g ${ELKUID} elk >/dev/null 2>&1)$?" != "0" ]
  then
    echo -e "\n\n  cant ensure UID ${ELKUID} on host for volume mounts of containers - exiting"| tee -a ${MYLOG} 2>&1
    exit 5
  fi
fi
echo "   ... using UID ${ELKUID} from host $(hostname)"| tee -a ${MYLOG} 2>&1
getent passwd ${ELKUID} |tee -a $MYLOG 2>&1
echo "   ... using GID ${ELKUID} from host $(hostname)"| tee -a ${MYLOG} 2>&1
getent group ${ELKUID} |tee -a $MYLOG 2>&1
#----
HOSTLOGIN="$(getent passwd ${ELKUID}|cut -d':' -f 1)"
ROOTLOGIN="$(getent passwd 0 |cut -d':' -f 1)"
HOSTGROUP="$(getent group ${ELKUID}|cut -d':' -f 1)"
ROOTGROUP="$(getent group 0 |cut -d':' -f 1)"
if [ "$(getent group ${ELKUID}|cut -d':' -f 3)" != "${ELKUID}" ]
then
  echo "   WARNING: primary GID and UID for ${HOSTLOGIN} on $(hostname) are mixed nums"| tee -a ${MYLOG} 2>&1
fi
if [ "$(usermod -a -G ${HOSTGROUP},${ROOTGROUP} ${HOSTLOGIN} >/dev/null 2>&1)$?" != "0" ]
then
  echo "   WARNING: try add ${HOSTLOGIN} on $(hostname) into group ${ROOTGROUP} returned non-zero"| tee -a ${MYLOG} 2>&1
fi
if [ "$(usermod -a -G ${ROOTGROUP},${HOSTGROUP} ${ROOTLOGIN} >/dev/null 2>&1)$?" != "0" ]
then
  echo "   WARNING: try add ${ROOTLOGIN} on $(hostname) into group ${HOSTGROUP} returned non-zero"| tee -a ${MYLOG} 2>&1
fi
echo "   ...OS login and group memberships are now as follows"| tee -a ${MYLOG} 2>&1
id ${ELKUID}| tee -a ${MYLOG} 2>&1
# ---------------------------------------------------------------------------------------------
echo -e "\nEvaluating var interpolations in config files on volumes ..."| tee -a ${MYLOG} 2>&1
# NOTE that files used in this step are fully hardcoded and manual
# checking of successful variable substitution seems advisable
unset FILE2FIX
FILE2FIX[0]="${EC2HOME}/elk/elasticsearch/es01/config/elasticsearch.yml"
FILE2FIX[1]="${EC2HOME}/elk/elasticsearch/es02/config/elasticsearch.yml"
FILE2FIX[2]="${EC2HOME}/elk/elasticsearch/es03/config/elasticsearch.yml"
FILE2FIX[3]="${EC2HOME}/elk/logstash/ls01/config/jvm.options"
FILE2FIX[4]="${EC2HOME}/elk/elasticsearch/es03/config/jvm.options"
FILE2FIX[5]="${EC2HOME}/elk/elasticsearch/es01/config/jvm.options"
FILE2FIX[6]="${EC2HOME}/elk/elasticsearch/es02/config/jvm.options"
FILE2FIX[7]="${EC2HOME}/elk/kibana/kibana01/config/kibana.yml"
for FILE in ${FILE2FIX[@]}
do
  echo -e "\n\n\n   ... evaling $(ls -l ${FILE})"| tee -a ${MYLOG} 2>&1
  if [ -w ${FILE} ]
  then
    (. ${ENVFILE} && eval "echo \"$(cat ${FILE})\"") > out.tmp
    sync && mv out.tmp ${FILE} && sync
    echo -e "--------------------------------------------------\n"| tee -a ${MYLOG} 2>&1
    ls -l ${FILE} |tee -a $MYLOG 2>&1| tee -a ${MYLOG} 2>&1
    cat ${FILE} |tee -a $MYLOG 2>&1| tee -a ${MYLOG} 2>&1
  else
    echo -e "\n\nNo writeable file found: ${FILE} - exiting"| tee -a ${MYLOG} 2>&1
    exit 5
  fi
done
# ---------------------------------------------------------------------------------------------
# when restarting elastic under docker-compose you may find keystores
# left in the bind mounted directories along with the config you have
# prepared there. keystore, cert and datafile must all match
echo -e "\nHandling elasticsearch keystore ..."| tee -a ${MYLOG} 2>&1
KSTORES=( $(find ./elk -type f -name "elasticsearch.keystore" 2>/dev/null) )
x=0
if [ "${#KSTORES[@]}" == "0" ]; then
  echo "   ... no keystores found - starting from scratch!"| tee -a ${MYLOG} 2>&1
else
  if [[ ${BACKUP_KEYSTORE} =~ ^[Tt]{1}rue$ ]]; then
    for i in ${KSTORES[@]}; do mv ${i} ${i}.${NOW} 2>/dev/null; done
    echo "   ... backups of keystore files created in bind-mount directories"| tee -a ${MYLOG} 2>&1
    find ./elk -type f -name "elasticsearch.keystore.${NOW}"| tee -a ${MYLOG} 2>&1
  fi
  if [[ ${DELETE_KEYSTORE} =~ ^[Tt]{1}rue$ ]]; then
    for i in ${KSTORES[@]}; do rm -f ${i} 2>/dev/null; done
    LEFTOVER=( $(find ./elk -type f -name "elasticsearch.keystore" 2>/dev/null) )
    if [ "${#LEFTFOVER[@]}" != "0" ]; then
      echo  "   WARNING: Could not delete all old keystore files - check mounts and file perms"| tee -a ${MYLOG} 2>&1
      find ./elk -type f -name "elasticsearch.keystore" -printf "%p:\t%u:%g\t%m\n"| tee -a ${MYLOG} 2>&1
    fi
  fi
  x=$(( ${KSTORES[@]} - ${#LEFTFOVER[@]} ))
  echo "   ... ${#KSTORES[@]} keystores found backup is ${BACKUP_KEYSTORE} and deleted ${x}"| tee -a ${MYLOG} 2>&1
fi
# ---------------------------------------------------------------------------------------------
echo -e "\nSet File permissions for config files on volumes ..."| tee -a ${MYLOG} 2>&1
chown -R ${ELKUID}:${ELKUID} ./elk
echo "   ... owner of ELK files here is user ${HOSTLOGIN}"| tee -a ${MYLOG} 2>&1
echo "   ... final permissions on directories with bind-mounts"| tee -a ${MYLOG} 2>&1
find ./elk -printf "%p:\t%u:%g\t%m\n"| tee -a ${MYLOG} 2>&1
# ---------------------------------------------------------------------------------------------
echo -e "\nRunning docker-compose up"
#docker-compose -f docker-compose.yml up setupdummy es01 kibana01 ls01 | tee -a ${MYLOG} 2>&1
#rc="$(docker-compose -f docker-compose.yml up | tee -a ${MYLOG} 2>&1)$?"
#[ "${rc}" = "0" ] || echo "docker-compose up had errors - exiting with ${rc}"
rc=0; echo "your turn"
