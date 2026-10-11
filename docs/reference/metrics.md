<!-- Audience: (2) a cluster admin deciding whether to trust it. -->
# Metrics reference


From `internal/telemetry/metrics.go` (prefix `sluice_`). All type
counter, no labels. Captured from a live `serve` (all zero at start):

```text
sluice_submissions_total 0
sluice_preflight_failures_total 0
sluice_stage_cache_hits_total 0
sluice_stage_cache_misses_total 0
sluice_requeues_total 0
sluice_jobs_done_total 0
sluice_jobs_failed_total 0
sluice_jobs_cancelled_total 0
sluice_watch_errors_total 0
```

Each line is exposed with `# HELP` / `# TYPE` headers at
`GET /metrics` (`Content-Type: text/plain; version=0.0.4`).
