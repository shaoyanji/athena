# Athena Architecture

Athena isolates the clean workspace seed from the chaotic root surface.

Handwritten markdown stays small and descriptive.
Canonical registry and task logic belongs in Nix.
YAML, JSON, and Taskfile outputs are compatibility views that should later be emitted from Nix-authored definitions.

Weak models degrade when startup depends on recursive discovery across large trees.
Athena instead aims for compact startup views that make the intended surface explicit.
