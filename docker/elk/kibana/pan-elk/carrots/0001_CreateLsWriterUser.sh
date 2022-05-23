ENABLED=true
[ "${ENABLED}" == "true" ] || exit 0

echo -e "\nCreating logstash users in kibana ..."

echo -e "\n   ... creating role logstash_writer:"
curl --cacert ${HOSTLCAFILE} -u elastic:${ELASTIC_PASSWORD} -H 'Content-Type: application/json' -XPOST "https://localhost:9200/_security/role/logstash_writer"  -d'
{
    "cluster": [
      "monitor",
      "manage_index_templates",
      "manage_security",
      "manage_api_key",
      "manage_own_api_key"
    ],
    "indices": [
      {
        "names": [
          "logstash*",
          "pan*"
        ],
        "privileges": [
          "write",
          "create_index",
          "create",
          "delete",
          "manage",
          "manage_ilm"
        ],
        "field_security": {
          "grant": [
            "*"
          ]
        }
      }
    ],
    "run_as": [],
    "metadata": {},
    "transient_metadata": {
      "enabled": true
    }
}'
echo -e "\n   ... creating role logstash_reader"
curl --cacert ${HOSTLCAFILE} -u elastic:${ELASTIC_PASSWORD} -H 'Content-Type: application/json' -XPOST "https://localhost:9200/_security/role/logstash_reader" -d'
{
  "cluster": [ "manage_logstash_pipelines" ]
}'
echo -e \n "   ... creating user logstash_pan-fwlog for LS transferring"

curl --cacert ${HOSTLCAFILE} -u elastic:${ELASTIC_PASSWORD} -H 'Content-Type: application/json' -XPOST "https://localhost:9200/_security/user/logstash_pan-fwlog" -d'
{
  "password": "2801mpeHAHAHA",
  "roles": [ "logstash_writer","logstash_reader","logstash_admin" ],
  "full_name": "The pan-elastic Logstash User"
}'

echo -e "\n   ... ensure to enable logstash_system user"
curl --cacert ${HOSTLCAFILE} -u elastic:${ELASTIC_PASSWORD} -H 'Content-Type: application/json' -XPUT "https://localhost:9200/_security/user/logstash_system/_enable"
echo -e "\n   ... set password for logstash_system user"
curl --cacert ${HOSTLCAFILE} -u elastic:${ELASTIC_PASSWORD} -H 'Content-Type: application/json' -XPOST "https://localhost:9200/_security/user/logstash_system/_password" -d'
{
  "password" : "2801mpeHAHAHA"
}'
