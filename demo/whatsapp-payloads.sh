#!/usr/bin/env bash
# Simulated Meta WhatsApp webhook payloads for demoing WF1 (Inbound Message Handler)
# without registering a real Meta webhook.
#
# Usage:
#   ./demo/whatsapp-payloads.sh book        # "I want a haircut tomorrow at 2pm"
#   ./demo/whatsapp-payloads.sh slot 1      # reply "1" to pick the first offered slot
#   ./demo/whatsapp-payloads.sh cancel      # "Cancel my appointment"
#   ./demo/whatsapp-payloads.sh ask         # "How much does a haircut cost?"
#   ./demo/whatsapp-payloads.sh text "..."  # arbitrary message
#
# NOTE: the webhook uses header auth bound to the "Meta WhatsApp Access Token"
# n8n credential — AUTH below must match that credential's current value.

set -euo pipefail

N8N_WEBHOOK_URL="${N8N_WEBHOOK_URL:?Set N8N_WEBHOOK_URL, e.g. https://<your-n8n>/webhook/whatsapp-inbound}"
FROM="${FROM:-254712413243}"
NAME="${NAME:-Brian}"
AUTH="${AUTH:?Set AUTH to the Meta token header value, e.g. 'Bearer EAAG...'}"

send() {
  local text="$1"
  curl -s -X POST "$N8N_WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -H "Authorization: $AUTH" \
    -d "$(cat <<EOF
{
  "object": "whatsapp_business_account",
  "entry": [{
    "id": "0",
    "changes": [{
      "field": "messages",
      "value": {
        "messaging_product": "whatsapp",
        "metadata": { "display_phone_number": "254700000000", "phone_number_id": "1208744585658537" },
        "contacts": [{ "profile": { "name": "$NAME" }, "wa_id": "$FROM" }],
        "messages": [{
          "from": "$FROM",
          "id": "wamid.demo.$(date +%s)",
          "timestamp": "$(date +%s)",
          "type": "text",
          "text": { "body": "$text" }
        }]
      }
    }]
  }]
}
EOF
)"
  echo
}

case "${1:-book}" in
  book)   send "I want a haircut tomorrow at 2pm" ;;
  slot)   send "${2:-1}" ;;
  cancel) send "Cancel my appointment" ;;
  ask)    send "How much does a haircut cost?" ;;
  text)   send "${2:?Provide message text}" ;;
  *)      echo "Unknown command: $1" >&2; exit 1 ;;
esac
