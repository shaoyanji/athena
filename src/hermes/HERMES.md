# Hermes

Hermes is a portable AI agent process — on-demand, machine-agnostic, workspace-rooted.

Current phase: portable identity and registry hardening.

Current truth:

- Hermes runs as a systemd process, not a container. Container approach produced large Nix closures.
- Canonical portable source is `github:shaoyanji/athena#hermes`
- Workspace root is the only machine-specific value. Everything else is projected from the flake.
- Memory is cloud-first (SuperMemory). Local fact_store is a decision registry, not a knowledge base.
- Credentials are NixOS module-owned. The agent never manages secrets directly.
- Skills are imported via task infrastructure with dotenv credential injection.
- The agent learns from experience. Trust scores on facts improve with feedback.

## Portability contract

A fresh machine gets hermes with:

```
nix develop github:shaoyanji/athena#hermes
```

The NixOS module handles: systemd unit, env vars, bind mounts, credentials.
Memory self-restores from SuperMemory on first session.
Skills/projects bind-mounted from NAS. No manual file copying.

## Registry mental model

Fact store is a decision registry, not a knowledge base.
Every stored fact must have a consequence: DO this, DON'T do this, or USE this path.
Facts without actionable consequences are noise — delete them.

Read order: fact_store (RAM-like) → if empty → SuperMemory.
Write order: SuperMemory first (source of truth), then fact_store if confirmed.
