<!-- Audience: (1) an engineer running OpenFOAM cases on a cluster. -->
# Checkpointing


When `solver.checkpointSeconds > 0`, the script arms Slurm
`--requeue` and `--signal=B:USR1@N`. On USR1 it runs
`foamDictionary -entry stopAt -set writeNow system/controlDict`,
touches `.foam-checkpoint-requested`, waits for a clean solver exit,
and calls `scontrol requeue`. The next attempt starts from
`latestTime`. Requirements: runtime-modifiable `controlDict`, a
working `foamDictionary`, requeue permission, and a solver that
writes a usable time directory. With `checkpointSeconds: 0` the
directives, trap, and requeue call are all omitted. Failure modes:
silent no-op without `runTimeModifiable` (rejected at validation),
kill at walltime with no restart if the solver ignores `writeNow`,
and requeue loops if every attempt times out again.
