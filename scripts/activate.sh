#!/usr/bin/env bash
set -euo pipefail

mode_or_target="${1:-workspace}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workspace_root="$(cd "$repo_root/../.." && pwd)"

resolve_target() {
  case "$mode_or_target" in
    workspace) echo "$workspace_root" ;;
    repo|.) echo "$repo_root" ;;
    /*) echo "$mode_or_target" ;;
    *)
      echo "Unsupported target '$mode_or_target'. Use: workspace | repo | /absolute/path" >&2
      exit 2
      ;;
  esac
}

target="$(resolve_target)"
ts="$(date +%Y%m%d-%H%M%S)"
backup_root="$target/.athena-backup/$ts"

backup_if_exists() {
  local rel="$1"
  local p="$target/$rel"
  if [ -e "$p" ] || [ -L "$p" ]; then
    mkdir -p "$backup_root/$(dirname "$rel")"
    cp -a "$p" "$backup_root/$rel"
  fi
}

link_file_with_backup() {
  local src="$1"
  local rel="$2"
  backup_if_exists "$rel"
  mkdir -p "$target/$(dirname "$rel")"
  ln -sfn "$src" "$target/$rel"
}

cd "$repo_root"
store_out="$(nix build --print-out-paths .#workspace-athena)"

link_file_with_backup "$store_out/share/athena/seed.json" "seed.json"
link_file_with_backup "$store_out/share/athena/effective/registry.json" "registry/effective/registry.json"
link_file_with_backup "$store_out/share/athena/effective/profile-manifest.json" "registry/effective/profile-manifest.json"
link_file_with_backup "$store_out/share/athena/live/AGENTS.md" "AGENTS.md"
link_file_with_backup "$store_out/share/athena/live/SOUL.md" "SOUL.md"
link_file_with_backup "$store_out/share/athena/live/USER.md" "USER.md"
link_file_with_backup "$store_out/share/athena/live/ATHENA.md" "ATHENA.md"

echo "Symlink targets:"
ls -l \
  "$target/AGENTS.md" \
  "$target/SOUL.md" \
  "$target/USER.md" \
  "$target/ATHENA.md" \
  "$target/seed.json" \
  "$target/registry/effective/registry.json" \
  "$target/registry/effective/profile-manifest.json"

if [ -d "$backup_root" ]; then
  echo "Activated Athena into $target (backup: $backup_root)"
else
  echo "Activated Athena into $target (no prior files needed backup)"
fi