<!-- Audience: (1) an engineer running OpenFOAM cases on a cluster. -->
# Example cluster setup


This is one example, not a requirement. Adjust every path.

- OpenFOAM environment: `/opt/openfoam12/etc/bashrc`, identical on
  every node, or set `runtime.foamBashrc` / `$FOAM_BASHRC`.
- MPI: OpenMPI `mpirun`, or `srun` with a matching PMIx.
- Worked cases: `heavySimple` (`foamRun` + `incompressibleFluid`)
  and `heavyBuoyant` (`foamRun` + `fluid`), 2 nodes x 4 tasks,
  checkpoint 600 s, `blockMesh` strategy.
- Logs per run: `<case>/.foam-runs/<local-id>/log.solver`,
  `slurm-<slurm-id>.out`, `slurm-<slurm-id>.err`, plus the exact
  `sluice.sbatch` Slurm executed (resubmit it to reproduce).
