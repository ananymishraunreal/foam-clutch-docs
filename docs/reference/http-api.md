<!-- Audience: (2) a cluster admin deciding whether to trust it. -->
# HTTP API reference


From `cmd/sluice/main.go` (`serveWithConfig`). Captured responses
from a running `serve`:

```bash
sluice serve --addr :8080 --db sluice.db
```

| Endpoint | Auth | Captured response |
|---|---|---|
| `GET /healthz` | none | `ok` (200) |
| `GET /readyz` | none | `ready` (200) or `db not ready` (503) |
| `GET /metrics` | none | Prometheus text (see [metrics](metrics.md)) |
| `GET /jobs[?state=]` | Bearer iff `SLUICE_API_TOKEN` set | `[]` (200); `unauthorized` (401 without token) |
| `GET /version` | none | `{"version":"audit"}` (200) |

Verified: without token `/jobs` returns 200; with
`SLUICE_API_TOKEN=secret` it returns 401 bare and 200 with
`Authorization: Bearer secret`. Timeouts: read-header 5 s, read and
write 15 s, idle 60 s; SIGTERM drains 10 s. There is no submit or
cancel endpoint: the service is read-only by design.
