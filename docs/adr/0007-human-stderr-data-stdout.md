<!-- Audience: (3) a contributor or hiring manager reading the repo. -->
# ADR 0007: Human output on stderr, data on stdout


## Context

Scripts pipe JSON while humans read progress.

## Decision

Human lines to stderr, machine JSON to stdout; plain fallback when
not a TTY, `--no-color`, or `-o json` (no live view there).

## Consequences

`tail -f $(sluice logs ... --follow=false)` composes; live view
stays TTY-only.

## Alternatives

Mixed streams (rejected: corrupts pipelines). Rationale: TODO(owner).
