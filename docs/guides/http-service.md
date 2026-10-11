<!-- Audience: (2) a cluster admin deciding whether to trust it. -->
# HTTP service


```bash
sluice serve --addr :8080 --db sluice.db
```

Endpoints: `GET /healthz`, `GET /readyz` (checks the DB),
`GET /metrics` (Prometheus text), `GET /jobs[?state=]`
(JSON array), `GET /version`. Set `SLUICE_API_TOKEN` to require
`Authorization: Bearer <token>` on `/jobs`. The service is
read-only: it exposes no submit or cancel endpoint. Do not put it on
a shared network without authentication in front. Detail and captured
responses: [http-api](../reference/http-api.md).
