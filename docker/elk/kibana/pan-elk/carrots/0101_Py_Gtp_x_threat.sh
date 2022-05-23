ENABLED=true
[ "${ENABLED}" == "true" ] || exit 0
echo -e "\nAdd Python script to correlate GTP x Threat Index ..."

echo "   ... placing python script in pan-elk directory"
# add quick mechanism in the python script to daemonise it
# and exit if it see running instances
# start the script as cron job on the host every 5 min
# it is clear that long term we want to add a container to run this script
# but for now prio is to have a simpler docker file

echo "   ... creating Index mapping pan-x-gtp-threat"
curl --cacert ${HOSTLCAFILE} -u elastic:${ELASTIC_PASSWORD} -H 'Content-Type: application/json' -XPUT "https://localhost:9200/_index_template/pan-x-gtp-threat" -d'
{
  "index_patterns": [ "pan-x-gtp-threat-*" ],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "index.lifecycle.name": "pan-ilm-x-threat",
      "index.lifecycle.rollover_alias": "pan-x-gtp-threat"
    },
    "mappings": {
      "properties": {
        "threat_fw_log_time": {
         "format" : "yyyy-MM-dd'\''T'\''HH:mm:ss.SSSZZZZZ",
          "index" : true,
          "ignore_malformed" : false,
          "store" : false,
          "type" : "date",
          "doc_values" : true
        },
        "gtp_seskey": {
          "type": "keyword"
        }
      }
    },
    "aliases": {
      "pan-x-gtp-threat":{
        "is_write_index": "true"
      }
    }
  },
  "composed_of": [ "pan-fwcomp-headers", "pan-fwcomp-gtp", "pan-fwcomp-threat" ],
  "version": 3
}'

echo "   ... creating ILM pan-ilm-x-threat"
curl --cacert ${HOSTLCAFILE} -u elastic:${ELASTIC_PASSWORD} -H 'Content-Type: application/json' -XPUT "https://localhost:9200/_ilm/policy/pan-ilm-x-threat" -d'
{
  "policy" : {
    "phases" : {
      "warm" : {
        "min_age" : "7d",
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
        "min_age" : "42d",
        "actions" : {
          "delete" : {
            "delete_searchable_snapshot" : false
          }
        }
      }
    }
  }
}'
