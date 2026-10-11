<!-- Audience: (1) an engineer running OpenFOAM cases on a cluster. -->
# Parameter sweeps


Today you script sweeps yourself: submit once per parameter set with
a separate manifest or generated case directory. Identical inputs
share a cache entry, so repeated meshes cost one staging. Each
submission gets its own run directory and Slurm job. There is no
built-in sweep runner, matrix expansion, or result index. Those are
roadmap items: see [roadmap](../roadmap.md).
