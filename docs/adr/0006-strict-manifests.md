<!-- Audience: (3) a contributor or hiring manager reading the repo. -->
# ADR 0006: Strict manifests that reject unknown fields


## Context

Silent typos (`taskPerNode`) waste queue allocations.

## Decision

Strict YAML decoding (`KnownFields`) plus validation of every
field and cross-field rules.

## Consequences

Typos fail fast; schema changes need version bumps.

## Alternatives

Lenient parsing with warnings (rejected). Rationale: TODO(owner).
