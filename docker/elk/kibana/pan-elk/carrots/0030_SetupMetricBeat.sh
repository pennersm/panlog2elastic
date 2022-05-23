ENABLED=X
[ "${ENABLED}" == "true" ] || exit0

echo "   ... Setup metricbeat for es-cluster self monitoring"
#C=$(openssl x509 -fingerprint -sha256 -in /usr/share/elasticsearch/config/certs/ca/ca.crt|grep Fingerprint=|cut -d'=' -f2|tr -d ':'|tr -d ' ' )
