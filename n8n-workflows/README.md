# n8n Agentic Workflow Stack

Five n8n workflows that give this repository an autonomous agent layer.
All workflows run on a self-hosted n8n instance and watch this repo
(`Rintu-chowdory/agentic-build-orchestrate-a`).

## Workflows

| File | Name | n8n ID | What it does |
|---|---|---|---|
| `chat-agent-github-tools.json` | My workflow (rebuilt) | `zO1DqIcTEVzfkuY5` | Chat agent (Groq `openai/gpt-oss-120b`) with Calculator, SerpApi web search, and GitHub tools: list issues, create issues, comment, list PRs |
| `auto-fix-v2.json` | GitHub Auto-Fix Agent | `Nh0HnaOIn0N9VvgG` | Issue opened → Claude returns `{filePath, fileContent}` → creates `fix/auto-N` branch → commits the fix → opens a PR |
| `issue-triage.json` | Issue Triage | `RAwPhBQwTyI05XVl` | New issue → keyword classification (bug / documentation / enhancement / question) → adds label + triage comment |
| `pr-review-agent.json` | PR Review Agent | *(new)* | PR opened → fetches the diff → `security_audit_agent` reviews it → posts a structured review comment (verdict + tagged findings) on the PR |
| `ci-watchdog.json` | CI Watchdog | `8fe66SVI9fpH8end` | GitHub Actions run fails → comments on the PR if one exists, otherwise opens an issue with the failing run link |

## Flow

```
        issue opened
              │
              ▼
     ┌── Issue Triage ──► label + comment
              │
              ▼
     └── Auto-Fix Agent ──► fix/auto-N branch ──► PR
                                     │
                       (Actions run on the PR)
                                     │
                              failure? ──► CI Watchdog ──► PR comment / issue

        PR opened
              │
              ▼
     └── PR Review Agent ──► diff ──► security_audit_agent ──► review comment
```

## Restore / redeploy

```bash
API="http://localhost:5678/api/v1"
KEY="your-n8n-api-key"

# create a workflow from JSON
NEW_ID=$(curl -s -X POST "$API/workflows" -H "X-N8N-API-KEY: $KEY" \
  -H "Content-Type: application/json" --data-binary @auto-fix-v2.json | jq -r .id)

# activate it
curl -s -X POST "$API/workflows/$NEW_ID/activate" -H "X-N8N-API-KEY: $KEY"
```

To **update** an existing workflow (keeps its ID and webhook): deactivate →
`PUT /api/v1/workflows/<id>` with the JSON → activate.

## Credentials needed (n8n instance)

- **GitHub account** (API token with repo scope) — used by triggers, tools, and HTTP nodes
- **Groq account** (chat model)
- **SerpApi account** (web search)
- **Header Auth** with Anthropic API key (Auto-Fix Agent's Claude call)

The chat agent's Groq credential ID is injected at deploy time, so this JSON
contains a placeholder — re-select the credential after import if deploying to
a different instance.
