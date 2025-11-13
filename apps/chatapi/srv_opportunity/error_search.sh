#!/bin/bash

# Usage:
# ./error_search.sh "openflex-request_2025_10" "68f8e82b49e300.14742459" 500 "2025-10-21T00:00:00.000Z" "2025-10-24T00:00:00.000Z"

index="$1"
request_id="$2"
status_code="$3"
start_day="$4"
end_day="$5"

url="http://10.1.2.200:5601/internal/bsearch"

# Construction du JSON dynamique
read -r -d '' body <<EOF
{
  "batch": [
    {
      "options": {
        "strategy": "ese"
      },
      "request": {
        "params": {
          "body": {
            "_source": true,
            "fields": [
              {
                "field": "*",
                "include_unmapped": "true"
              },
              {
                "field": "timestamp",
                "format": "date_time"
              }
            ],
            "query": {
              "bool": {
                "filter": [
                  {
                    "range": {
                      "timestamp": {
                        "format": "strict_date_optional_time",
                        "gte": "${start_day}",
                        "lte": "${end_day}"
                      }
                    }
                  },
                  {
                    "match_phrase": {
                      "request_id": "${request_id}"
                    }
                  },
                  {
                    "match_phrase": {
                      "status_code": ${status_code}
                    }
                  }
                ],
                "must": [],
                "must_not": [],
                "should": []
              }
            },
            "runtime_mappings": {},
            "stored_fields": ["*"],
            "version": true
          },
          "index": "${index}"
        }
      }
    }
  ]
}
EOF

echo "----------- Envoi de la requête POST : -----------"
echo "$body" | jq . || echo "$body"

# Exécution du POST vers Kibana
response=$(curl -s -X POST "$url" \
  -H "Host: 10.1.2.200:5601" \
  -H "User-Agent: Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:144.0) Gecko/20100101 Firefox/144.0" \
  -H "Accept: */*" \
  -H "Accept-Language: fr,fr-FR;q=0.8,en-US;q=0.5,en;q=0.3" \
  -H "Accept-Encoding: deflate" \
  -H "Referer: http://10.1.2.200:5601/app/discover" \
  -H "Content-Type: application/json" \
  -H "kbn-version: 7.16.2" \
  -H "Origin: http://10.1.2.200:5601" \
  -H "Connection: keep-alive" \
  -H "Pragma: no-cache" \
  -H "Cache-Control: no-cache" \
  -d "$body")

# Vérification du code retour
if [ $? -ne 0 ]; then
  echo "Erreur lors de l'appel HTTP."
  exit 1
fi

echo "----------- Réponse : -----------"
echo "$response" | jq . || echo "$response"

