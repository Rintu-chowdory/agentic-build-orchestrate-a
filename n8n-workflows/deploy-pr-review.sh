#!/bin/bash
# Deploy PR Review Agent to local n8n (run on Kali, next to pr-review-agent.json)
set -e
API="http://localhost:5678/api/v1"
KEY="${N8N_API_KEY:?export N8N_API_KEY first}"
AGKEY="$(cat /tmp/agent_api_key.txt)"
WF="${1:-pr-review-agent.json}"

# inject the agent API key (avoids CLI variable masking of secrets)
python3 - "$AGKEY" "$WF" << 'PY'
import json, sys
agkey, f = sys.argv[1], sys.argv[2]
w = json.load(open(f))
for n in w['nodes']:
    for p in n.get('parameters', {}).get('headerParameters', {}).get('parameters', []):
        if p['name'] == 'X-API-Key':
            p['value'] = agkey
json.dump(w, open('/tmp/pr-review-agent-deploy.json', 'w'), indent=2)
PY

NEW_ID=$(curl -s -X POST "$API/workflows" -H "X-N8N-API-KEY: $KEY" \
  -H "Content-Type: application/json" --data-binary @/tmp/pr-review-agent-deploy.json | jq -r .id)
echo "created workflow: $NEW_ID"
curl -s -X POST "$API/workflows/$NEW_ID/activate" -H "X-N8N-API-KEY: $KEY" | jq -r '"active: " + (.active|tostring)'
echo "Done — open a PR on agentic-build-orchestrate-a to see the review comment."
