<!-- Audience: (3) a contributor or hiring manager reading the repo. -->
# Architecture


## Pipeline

```mermaid
flowchart TD
    M[manifest.yaml + case] --> V[manifest load + validate]
    V --> P[preflight + service checks]
    P --> S[stage: cache hit or miss]
    S --> D[store Create STAGED]
    D --> R[render batch script]
    R --> Q[submit: QUEUED + Slurm ID]
    Q --> W[supervisor poll]
    W --> T[DONE / FAILED / CANCELLED]
```

## Local state machine

```mermaid
stateDiagram-v2
    [*] --> STAGED
    STAGED --> QUEUED
    QUEUED --> RUNNING
    RUNNING --> REQUEUED
    REQUEUED --> RUNNING
    RUNNING --> DONE
    RUNNING --> FAILED
    RUNNING --> CANCELLED
    QUEUED --> UNKNOWN
    RUNNING --> UNKNOWN
```

## `run` sequence

```mermaid
sequenceDiagram
    participant CLI
    participant Service
    participant Stage
    participant Store
    participant Sched as Scheduler
    participant Sup as Supervisor
    CLI->>Service: Validate(manifest)
    Service->>Stage: Stage(case)
    Stage-->>Service: hash + path
    Service->>Store: Create(STAGED)
    Service->>Store: UpdatePaths(run, cache)
    Service->>Sched: Submit(spec)
    Sched-->>Service: slurmID
    Service->>Store: UpdateState(QUEUED)
    CLI->>Sup: Watch(id, slurmID)
    Sup->>Sched: State(slurmID)
    Sup->>Store: UpdateState(...)
```

The CLI progress observer prints one timestamped stderr line per
completed stage; the live view forwards the same events to the TTY.

## Package map

`cmd/sluice` (Cobra commands, human output on stderr, data on
stdout) -> `internal/service` (orchestration + script render) ->
`manifest`, `preflight`, `stage`, `store`, `scheduler` or root
`client.go` (REST), `supervisor`, `telemetry`. `internal/brand`
holds every product name. `internal/doctor` checks the environment.
`internal/ui` holds banner, tables, and the live view.

## Data model

`jobs(id, name, state, manifest_path, case_hash, run_path,
cache_path, slurm_id, error, updated_at)`, indexes on `updated_at`
and `state`. SQLite WAL, single connection.

## Crash semantics (verified in code)

- Die after `Create(STAGED)` but before submit: a `STAGED` row with
  no Slurm job. Nothing reconciles it today: it stays `STAGED`
  until an operator deletes or resubmits.
- Die after Slurm accepted but before the `QUEUED` update: the job
  runs on the cluster with no local record of its Slurm ID. Nothing
  reconciles it today.
- Die during watch: the row keeps its last state; re-running
  `status --refresh` or `watch` resumes polling that job.
- Not reconciled on restart: orphan `STAGED` rows, submit/update
  races, and outbox events (there is no outbox). See
  [roadmap](roadmap.md).
