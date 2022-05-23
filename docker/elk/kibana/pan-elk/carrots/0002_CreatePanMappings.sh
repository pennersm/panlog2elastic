ENABLED=true
[ "${ENABLED}" == "true" ] || exit 0
echo -e "\nCreating PAN-ELK Index mappings in kibana ..."

echo -e "\n   ... creating Index Component Template pan-fwcomp-headers"
curl --cacert ${HOSTLCAFILE} -u elastic:${ELASTIC_PASSWORD} -H 'Content-Type: application/json' -XPUT "https://localhost:9200/_component_template/pan-fwcomp-headers"  -d'
{
  "version": 3,
  "template": {
    "mappings": {
      "dynamic": false,
      "properties": {
        "fw_log_time" : {
          "format" : "yyyy-MM-dd'\''T'\''HH:mm:ss.SSSZZZZZ",
          "index" : true,
          "ignore_malformed" : false,
          "store" : false,
          "type" : "date",
          "doc_values" : true
        },
        "logtype" : {
          "type" : "keyword"
        },
        "serial" : {
          "type" : "keyword"
        },
        "device_name" : {
          "type" : "keyword"
        },
        "vsys" : {
          "type" : "keyword"
        },
        "imsi" : {
          "type" : "keyword"
        },
        "imei" : {
          "type" : "keyword"
        },
        "seskey" : {
          "type" : "keyword"
        },
        "session_stat" : {
          "type" : "keyword"
        },
        "devkey" : {
          "type" : "keyword"
        },
        "subkey" : {
          "type" : "keyword"
        },
        "gtpkey_dst" : {
          "type" : "keyword"
        },
        "gtpkey_src" : {
          "type" : "keyword"
        },
        "gtpkey_ue" : {
          "type" : "keyword"
        }
      }
    }
  }
}'

echo -e "\n   ... creating Index Component Template pan-fwcomp-threat"
curl --cacert ${HOSTLCAFILE} -u elastic:${ELASTIC_PASSWORD} -H 'Content-Type: application/json' -XPUT "https://localhost:9200/_component_template/pan-fwcomp-threat" -d'
{
  "version": 3,
  "template": {
    "mappings": {
      "dynamic": false,
      "properties": {
        "threat_src" : {
          "index" : true,
          "type" : "ip",
          "doc_values" : true
        },
        "threat_dst" : {
          "index" : true,
          "type" : "ip",
          "doc_values" : true
        },
        "threat_sport" : {
          "type" : "integer",
          "fields": {
            "keyword": {
              "type": "keyword"
            }
          }
        },
        "threat_dport" : {
          "type" : "integer",
          "fields": {
            "keyword": {
              "type": "keyword"
            }
          }
        },
        "threat_proto" : {
          "type" : "keyword"
        },
        "threat_direction" : {
          "type" : "keyword"
        },
        "threat_app" : {
          "type" : "keyword"
        },
        "threat_tunnel" : {
          "type" : "keyword"
        },
        "threat_threatid" : {
          "type" : "integer",
          "fields": {
            "keyword": {
              "type": "keyword"
            }
          }
        },
        "threat_severity" : {
          "type" : "keyword"
        },
        "threat_action" : {
          "type" : "keyword"
        },
        "threat_sessionid" : {
          "type" : "keyword"
        },
        "threat_subtype" : {
          "type" : "keyword"
        },
        "threat_category" : {
          "type" : "keyword"
        },
        "threat_flags" : {
          "type" : "keyword"
        },
        "threat_user_agent" : {
          "type" : "keyword"
        },
        "threat_referer" : {
          "type" : "keyword"
        },
        "threat_http_method" : {
          "type" : "keyword"
        },
        "threat_http_headers" : {
          "type" : "keyword"
        },
        "threat_filetype" : {
          "type" : "keyword"
        },
        "threat_filedigest" : {
          "type" : "keyword"
        },
        "threat_file_url": {
          "type" : "keyword"
        },
        "threat_sig_flags" : {
          "type" : "keyword"
        },
        "threat_xff" : {
          "type" : "keyword"
        },
        "threat_url_idx" : {
          "type" : "keyword"
        },
        "threat_sender": {
          "type" : "keyword"
        },
        "threat_subject" : {
          "type" : "keyword"
        },
        "threat_recipient" : {
          "type" : "keyword"
        },
        "threat_name" : {
          "type" : "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 60
            }
          }
        },
        "threat_rule" : {
          "type" : "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 80
            }
          }
        }
      }
    }
  }
}'

echo "   ... creating Index Component Template pan-fwcomp-gtp"
curl --cacert ${HOSTLCAFILE} -u elastic:${ELASTIC_PASSWORD} -H 'Content-Type: application/json' -XPUT "https://localhost:9200/_component_template/pan-fwcomp-gtp" -d'
{
  "version": 3,
  "template": {
    "mappings": {
      "dynamic": false,
      "properties": {
        "gtp_src" : {
          "index" : true,
          "type" : "ip",
          "doc_values" : true
        },
        "gtp_dst" : {
          "index" : true,
          "type" : "ip",
          "doc_values" : true
        },
        "gtp_end_ip_addr" : {
          "index" : true,
          "type" : "ip",
          "doc_values" : true
        },
        "gtp_event_type" : {
          "type" : "keyword"
        },
        "gtp_proto" : {
          "type" : "keyword"
        },
        "gtp_cause_code" : {
          "type" : "keyword"
        },
        "gtp_severity" : {
          "type" : "keyword"
        },
        "gtp_sport" : {
          "type" : "integer",
          "fields": {
            "keyword": {
              "type": "keyword"
            }
          }
        },
        "gtp_mcc" : {
          "type" : "keyword"
        },
        "gtp_tunnel" : {
          "type" : "keyword"
        },
        "gtp_mnc" : {
          "type" : "keyword"
        },
        "gtp_cell_id" : {
          "type" : "keyword"
        },
        "gtp_teid1" : {
          "type" : "keyword"
        },
        "gtp_sessionid" : {
          "type" : "keyword"
        },
        "gtp_msisdn" : {
          "type" : "keyword"
        },
        "gtp_teid2" : {
          "type" : "keyword"
        },
        "gtp_area_code" : {
          "type" : "keyword"
        },
        "gtp_dport" : {
          "type" : "integer",
          "fields": {
            "keyword": {
              "type": "keyword"
            }
          }
        },
        "gtp_event_code" : {
          "type" : "keyword"
        },
        "gtp_rat" : {
          "type" : "keyword"
        },
        "gtp_action" : {
          "type" : "keyword"
        },
        "gtp_msg_type" : {
          "type" : "keyword"
        },
        "gtp_app" : {
          "type" : "keyword"
        },
        "gtp_interface" : {
          "type" : "keyword"
        },
        "gtp_apn" : {
          "type" : "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 80
            }
          }
        },
        "gtp_rule" : {
          "type" : "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 80
            }
          }
        }
      }
    }
  }
}'

echo "   ... creating Index Component Template pan-fwcomp-traffic"
curl --cacert ${HOSTLCAFILE} -u elastic:${ELASTIC_PASSWORD} -H 'Content-Type: application/json' -XPUT "https://localhost:9200/_component_template/pan-fwcomp-traffic" -d'
{
  "version": 3,
  "template": {
    "mappings": {
      "dynamic": false,
      "properties": {
        "traffic_src" : {
          "index" : true,
          "type" : "ip",
          "doc_values" : true
        },
        "traffic_dst" : {
          "index" : true,
          "type" : "ip",
          "doc_values" : true
        },
        "traffic_sport" : {
          "type" : "integer",
          "fields": {
            "keyword": {
              "type": "keyword"
            }
          }
        },
        "traffic_dport" : {
          "type" : "integer",
          "fields": {
            "keyword": {
              "type": "keyword"
            }
          }
        },
        "traffic_proto" : {
          "type" : "keyword"
        },
        "traffic_tunnel" : {
          "type" : "keyword"
        },
        "traffic_app" : {
          "type" : "keyword"
        },
        "traffic_sessionid" : {
          "type" : "keyword"
        },
        "traffic_action" : {
          "type" : "keyword"
        },
        "traffic_subtype" : {
          "type" : "keyword"
        },
        "traffic_session_end_reason" : {
          "type" : "keyword"
        },
        "traffic_pkts" : {
          "type" : "keyword"
        },
        "traffic_pkts_received" : {
          "type" : "keyword"
        },
        "traffic_pkts_sent" : {
          "type" : "keyword"
        },
        "traffic_bytes" : {
          "type" : "keyword"
        },
        "traffic_bytes_received" : {
          "type" : "keyword"
        },
        "traffic_bytes_sent" : {
          "type" : "keyword"
        },
        "traffic_flags" : {
          "type" : "keyword"
        },
        "traffic_rule" : {
          "type" : "text",
          "fields": {
            "keyword": {
              "type": "keyword",
              "ignore_above": 80
            }
          }
        }
      }
    }
  }
}'


echo "   ... creating Index Template pan-fwlog-threat"
curl --cacert ${HOSTLCAFILE} -u elastic:${ELASTIC_PASSWORD} -H 'Content-Type: application/json' -XPUT "https://localhost:9200/_index_template/pan-fwlog-threat" -d'
{
  "index_patterns": [ "pan-fwlog-threat-*" ],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "index.lifecycle.name": "pan-ilm-fwlogstream",
      "index.lifecycle.rollover_alias": "pan-fwlog-threat"
    },
    "aliases": {
      "pan-fwlog-threat":{
        "is_write_index": "true"
      }
    }
  },
  "composed_of": [ "pan-fwcomp-headers", "pan-fwcomp-threat" ],
  "version": 3
}'

echo "   ... creating Index Template pan-fwlog-gtp"
curl --cacert ${HOSTLCAFILE} -u elastic:${ELASTIC_PASSWORD} -H 'Content-Type: application/json' -XPUT "https://localhost:9200/_index_template/pan-fwlog-gtp" -d'
{
  "index_patterns": [ "pan-fwlog-gtp-*" ],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "index.lifecycle.name": "pan-ilm-fwlogstream",
      "index.lifecycle.rollover_alias": "pan-fwlog-gtp"
    },
    "aliases": {
      "pan-fwlog-gtp":{
        "is_write_index": "true"
      }
    }
  },
  "composed_of": [ "pan-fwcomp-headers", "pan-fwcomp-gtp" ],
  "version": 3
}'


echo "   ... creating Index Template pan-fwlog-traffic"
curl --cacert ${HOSTLCAFILE} -u elastic:${ELASTIC_PASSWORD} -H 'Content-Type: application/json' -XPUT "https://localhost:9200/_index_template/pan-fwlog-traffic" -d'
{
  "index_patterns": [ "pan-fwlog-traffic-*" ],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "index.lifecycle.name": "pan-ilm-fwlogstream",
      "index.lifecycle.rollover_alias": "pan-fwlog-traffic"
    },
    "aliases": {
      "pan-fwlog-traffic":{
        "is_write_index": "true"
      }
    }
  },
  "composed_of": [ "pan-fwcomp-headers", "pan-fwcomp-traffic" ],
  "version": 3

}'

echo "   ... creating kibana data view for pan*"
curl --cacert ${HOSTLCAFILE} -u elastic:${ELASTIC_PASSWORD} -H 'kbn-xsrf:true' -H 'Content-Type: application/json' -XPOST "127.0.0.1:5601/api/data_views/data_view" -d'
{
  "data_view": {
    "title": "pan*",
    "timeFieldName": "fw_log_time",
    "allowNoIndex": false,
    "id": "0001"
  }
}'
