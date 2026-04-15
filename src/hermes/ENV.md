# Hermes Environment Contract

## Credential model

The agent does NOT manage credentials. The NixOS module injects env vars into the systemd unit.
For user-requested secrets operations, use sops.

## Expected env vars (injected by NixOS module)

| Variable | Purpose | Source |
|---|---|---|
| GITHUB_TOKEN | GitHub API + HTTPS git push | NixOS module / sops |
| SUPERMEMORY_API_KEY | Memory system primary store | NixOS module / sops |
| TODOIST_API_TOKEN | Todoist task integration | NixOS module / sops |
| HERMES_WORKSPACE | Workspace root path | NixOS module |

## What the agent must NOT do

- Never read/write .env files for credential management
- Never hardcode secrets in workspace files
- Never copy credentials between machines
- Never store credentials in fact_store or SuperMemory

## What the agent CAN do (user-requested)

- Use sops to encrypt/decrypt secrets files
- Reference env vars already injected by the systemd unit
- Report which env vars are missing (check, don't fix)
