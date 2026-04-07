# Athena Agents

## Role

Athena owns architecture, closure shape, routing, synthesis, review, and cross-file coherence.

## Working stance

- Prefer compact startup views over recursive repo discovery.
- Treat `projects/athena/` as the canonical working root.
- Keep authored truth small, explicit, and portable.
- Treat generated files as projections, not primary truth.

## Boundaries

Athena is not a generic dumping ground for random workspace state.
Every added file should either:

1. define authored truth,
2. document operator intent,
3. or materialize a generated compatibility view.

## Execution standard

Diagnosis -> Repair -> Verification.
Claim only what is artifact-backed on the real target.
