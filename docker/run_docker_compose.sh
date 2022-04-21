# @Author: mpenners
# @Date:   2022-04-08T09:40:53+02:00
# @Filename: run_docker_compose.sh
# @Last modified by:   mpenners
# @Last modified time: 2022-04-08T10:53:48+02:00
echo "... setting kernel parameters"
rc=0
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
rc ="$(sysctl -w vm.max_map_count=262144 >/dev/null 2>&1)$?"
[ "${rc}" = "0" ] || { echo "problem setting kernel parameters - exiting" ; exit ${rc} ; }

echo "... creating docker network"
rc="$(docker network create elastic >/dev/null 2>&1)$?"
[ "${rc}" = "0" ] || { echo "can not create docker network - exiting" ; exit ${rc} ; }

echo "... running docker-compose up"
rc="$(docker-compose up -d >> dockercup.log 2>&1)$?"
[ "${rc}" = "0" ] || echo "docker-compose up had errors - exiting with ${rc}"
