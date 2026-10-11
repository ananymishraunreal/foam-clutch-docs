<!-- Audience: (1) an engineer running OpenFOAM cases on a cluster. -->
# Cache and run directories


The cache key is a SHA-256 over relative file names and contents of
the canonical inputs plus `case.include` tops. Same inputs reuse
`<cacheDir>/<sha256>/`. The run directory `<runDir>/<local-job-id>/`
is a copy of that cache. Separation matters: the checkpoint handler
edits `system/controlDict` and the solver writes logs and time
directories, so the shared cache must stay immutable. Only `0/`,
`0.orig/`, `constant/`, `system/`, plus explicit `case.include` tops
are staged; docs, logs, and `.foam-*` state never affect the hash.
