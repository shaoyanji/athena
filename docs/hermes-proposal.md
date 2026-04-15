# Hermes Profile Proposal

## Design Principles

- Hermes is a portable agent shell. One flake, any machine, same behavior.
- The agent never handles credentials. NixOS module owns env injection.
- For secrets operations (user-requested), use sops.
- NAS symlinks/bind mounts are managed by NixOS config. Agent never touches them.
- Memory is cloud-first (SuperMemory). Nothing local to migrate.
- Workspace root is the only machine-specific value.

## Profile Definition

```nix
{
  name = "hermes";
  description = "Hermes agent — portable, on-demand AI system process";
  shell = "hermes";
  packages = [
    "workspace-athena"
    "athena-activate"
    "hermes-workspace-init"
    "python3"
    "go"
    "jq"
    "yq-go"
    "git"
    "ripgrep"
    "curl"
    "go-task"
    "age"
    "sops"
  ];
  tools = [ "git" "jq" "task" "python3" "go" "curl" "rg" ];
  skills = [
    "workspace-materialization"
    "credential-bootstrap"
    "skill-import"
  ];
  startupViews = [ "bootstrap" "workspace-check" ];
}
```

## Workspace Layout

```json
{
  "root": "/var/lib/hermes/workspace",
  "structure": {
    "share/projects/": "cloned repos, hermes-owned",
    "share/skills/": "imported skills (read-write)",
    ".hermes/skills/": "built-in skills (read-only from nix store)",
    ".hermes/memory/": "pending memory files",
    ".hermes/audio_cache/": "tts cache",
    "scripts/": "utility scripts"
  },
  "portability": {
    "machine_specific": [ "root" ],
    "portable": [ "structure", "skills" ],
    "nixos_managed": [ "env_vars", "credentials", "bind_mounts", "systemd_unit" ]
  }
}
```

## Credential Model

- Agent does NOT manage credentials
- NixOS module injects env vars into systemd unit
- For user-requested secrets operations: use sops
- No .env files in workspace — Nix produces what's needed

## Migration

```bash
# Step 1: Activate workspace skeleton
nix develop github:shaoyanji/athena#hermes --command athena-activate

# Step 2: NixOS module handles everything else
# - systemd unit
# - env vars
# - bind mounts
# - credentials

# Step 3: Memory self-restores from SuperMemory on first session
```

Three steps. No manual credential copying. No bind mount fiddling. No memory migration.
