<!-- Audience: (1) an engineer running OpenFOAM cases on a cluster. -->
# Manifest reference


Derived from `internal/manifest/manifest.go` types and `Validate`.
If a field below disagrees with that file, the file wins: update
this doc. Legacy `apiVersion: foam-clutch/v1alpha1` loads with a
one-line stderr deprecation warning; `sluice init` writes
`sluice/v1alpha1`. Unknown fields are rejected (`KnownFields`).

<!-- verify:manifest -->

```yaml
apiVersion: sluice/v1alpha1   # required; this or foam-clutch/v1alpha1
name: myCase                  # required; no newlines; Slurm + local name
case:
  path: ./case                # required; absolute after resolving
                              # against the manifest dir
  include: []                 # optional; case-relative tops, must exist,
                              # not canonical inputs, not artefacts
resources:
  partition: ""               # optional; empty = cluster default
  account: ""                 # optional
  nodes: 1                    # required, > 0
  tasksPerNode: 1             # required, > 0
  timeLimitMinutes: 60        # required, > 0
  sbatchExtra: []             # optional; --key[=value], never repeats
                              # managed opts (job-name, partition, nodes,
                              # ntasks, time, output, error, signal,
                              # exclusive, hint, requeue)
solver:
  name: simpleFoam            # required; bare executable, any solver
  arguments: []               # optional; no newlines
  container: ""               # optional; absolute image path or empty
  fileHandler: collated       # default collated; collated|uncollated|none
  checkpointSeconds: 0        # default 0; >= 0 and < walltime seconds
mesh:
  strategy: auto              # default auto; auto|blockMesh|custom|none
  commands: []                # required iff strategy custom; one command
                              # per line, no empty lines
post:
  reconstruct: false          # optional; reconstructPar after clean solve
  commands: []                # optional; non-empty single lines
runtime:
  foamBashrc: /opt/openfoam12/etc/bashrc  # default chain: manifest >
                              # $FOAM_BASHRC > auto-detect > built-in;
                              # must be absolute
  threadsPerRank: 1           # default 1; > 0
  mpi:
    launcher: mpirun          # default mpirun; mpirun|srun
    flavour: ""               # "", pmix, pmi2, openmpi (srun --mpi)
    extraArgs: []             # optional; no newlines
storage:
  cacheDir: ./.foam-cache     # default <manifest-dir>/.foam-cache
  runDir: ./.foam-runs        # default <manifest-dir>/.foam-runs
```

Cross-field rules (`internal/service/service.go`): controlDict
`application` equals `solver.name`, except `application foamRun`
needs manifest solver `foamRun` plus any `solver <model>;` line;
parallel runs need `decomposeParDict numberOfSubdomains` equal to
`nodes x tasksPerNode` (skipped when ranks = 1 or strategy `none`);
`checkpointSeconds > 0` needs `runTimeModifiable true`; `blockMesh`
needs `system/blockMeshDict`, `auto` needs `constant/polyMesh/points`
or `blockMeshDict`.
