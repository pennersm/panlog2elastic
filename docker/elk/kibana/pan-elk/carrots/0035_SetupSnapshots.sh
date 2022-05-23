ENABLED=X
[ "${ENABLED}" == "true" ] || exit0
echo "   ... registering snapshots repo"
#curl --cacert ${HOSTLCAFILE} -u elastic:${ELASTIC_PASSWORD} -H 'Content-Type: application/json' -XPUT "127.0.0.1:9200/_cluster/settings?flat_settings=true&pretty" -d'
#{
#  "transient": {
#    "path.repo": "/usr/share/elasticsearch/snapshots" 
#  }
#}'
