ENABLED=true
[ "${ENABLED}" == "true" ] || exit 0

echo -e "\nCreating ILM for basic logstream ..."
echo "   ... creating Index Lifecycle Policy pan-ilm-fwlogstream"
curl --cacert ${HOSTLCAFILE} -u elastic:${ELASTIC_PASSWORD} -H 'Content-Type: application/json' -XPUT "https://localhost:9200/_ilm/policy/pan-ilm-fwlogstream" -d'
{
  "policy" : {
    "phases" : {
      "warm" : {
        "min_age" : "24h",
        "actions" : {
          "allocate" : {
            "number_of_replicas" : 0,
            "include" : { },
            "exclude" : { },
            "require" : { }
          },
          "set_priority" : {
            "priority" : 50
          }
        }
      },
      "hot" : {
        "min_age" : "0ms",
        "actions" : {
          "rollover" : {
            "max_size" : "200gb",
            "max_primary_shard_size" : "200gb",
            "max_age" : "24h"
          },
          "set_priority" : {
            "priority" : 100
          }
        }
      },
      "delete" : {
        "min_age" : "168h",
        "actions" : {
          "delete" : {
            "delete_searchable_snapshot" : false
          }
        }
      }
    }
  }
}'
