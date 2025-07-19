#!/bin/bash

# Cloudflare API credentials
API_TOKEN="Uqv4L7uUeMKhfLRKOY5dDYOL9FSH4UXuERjtdr-q"
ZONE_NAME="richknowles.com"
RECORDS=("aj" "alisajones")
RECORD_IP="150.136.116.164"
CF_API="https://api.cloudflare.com/client/v4"

# Get Zone ID
ZONE_ID=$(curl -s -X GET "$CF_API/zones?name=$ZONE_NAME" \
  -H "Authorization: Bearer $API_TOKEN" \
  -H "Content-Type: application/json" | jq -r '.result[0].id')

if [[ -z "$ZONE_ID" || "$ZONE_ID" == "null" ]]; then
  echo "❌ Failed to retrieve Zone ID for $ZONE_NAME"
  exit 1
fi

echo "✅ Zone ID for $ZONE_NAME: $ZONE_ID"

# Loop through and create/update records
for NAME in "${RECORDS[@]}"; do
  echo "🚀 Processing record: $NAME.$ZONE_NAME → $RECORD_IP"
  
  # Check if record exists
  RECORD_ID=$(curl -s -X GET "$CF_API/zones/$ZONE_ID/dns_records?type=A&name=$NAME.$ZONE_NAME" \
    -H "Authorization: Bearer $API_TOKEN" \
    -H "Content-Type: application/json" | jq -r '.result[0].id')

  if [[ "$RECORD_ID" == "null" ]]; then
    # Create record
    curl -s -X POST "$CF_API/zones/$ZONE_ID/dns_records" \
      -H "Authorization: Bearer $API_TOKEN" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"A\",\"name\":\"$NAME\",\"content\":\"$RECORD_IP\",\"ttl\":1,\"proxied\":false}" \
      | jq .
    echo "✅ Created $NAME.$ZONE_NAME"
  else
    # Update record
    curl -s -X PUT "$CF_API/zones/$ZONE_ID/dns_records/$RECORD_ID" \
      -H "Authorization: Bearer $API_TOKEN" \
      -H "Content-Type: application/json" \
      --data "{\"type\":\"A\",\"name\":\"$NAME\",\"content\":\"$RECORD_IP\",\"ttl\":1,\"proxied\":false}" \
      | jq .
    echo "✅ Updated $NAME.$ZONE_NAME"
  fi
done
