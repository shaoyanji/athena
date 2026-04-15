# Athena

Athena is a portable workspace control plane for local context, startup views, profile surfaces, and operator-legible live workspace materialization.

Current phase: live-plane hardening.

Current truth:

- authored structure lives primarily in Nix and small markdown control docs
- canonical portable source is `github:shaoyanji/athena`
- generated artifacts and workspace-root links are projections for compatibility and live control-surface materialization
- Athena now has a real live control-plane path
- the repo is not yet a full wider-system runtime replacement
- the next threshold is to define and implement a real startup/bootstrap contract plus non-stub profile/package/tool/skill registry surfaces