<!-- Audience: (1) an engineer running OpenFOAM cases on a cluster. -->
# Manifest concepts


The manifest is the only input contract. It names the case, the
solver, the resources, the mesh strategy, the runtime, and the
storage. Unknown YAML fields are rejected. Relative paths resolve
against the manifest file's directory, so pass `--manifest` as an
absolute path (relative paths mis-resolve today).

Loading applies defaults (`fileHandler: collated`, `mesh.strategy:
auto`, `mpi.launcher: mpirun`, `threadsPerRank: 1`, `foamBashrc` from
manifest, then `$FOAM_BASHRC`, then auto-detect, then a built-in
fallback). Validation then enforces every rule plus four cross-field
checks: controlDict application vs solver name, decomposeParDict
subdomains vs ranks, checkpointing requires `runTimeModifiable`, and
the mesh strategy needs a mesh source. Field detail lives in
[manifest reference](../reference/manifest.md).
