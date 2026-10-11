<!-- Audience: (3) a contributor or hiring manager reading the repo. -->
# ADR 0002: SQLite with WAL as the local store


## Context

One service instance tracks local job state across restarts.

## Decision

SQLite in WAL mode, single connection, `jobs` table. Postgres is
the documented path for multiple replicas.

## Consequences

Zero-dependency local truth; no multi-writer story, no leases.

## Alternatives

Postgres now (rejected: operational weight for a local workflow).
Rationale: TODO(owner) beyond the code comments.
