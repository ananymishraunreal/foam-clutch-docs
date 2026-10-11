<!-- Audience: (3) a contributor or hiring manager reading the repo. -->
# ADR 0005: Reject code-loading directives in preflight


## Context

OpenFOAM dictionaries can compile and run code.

## Decision

Blocklist `#codeStream`, `#calc`, `codedFixedValue`,
`codedMixed`, `libs` in input dictionaries plus escaping symlinks.

## Consequences

Cheap fail-fast; not a sandbox (see security doc).

## Alternatives

Allow-list of safe directives per solver (future work).
Rationale: TODO(owner) for the exact five tokens.
