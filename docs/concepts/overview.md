<!-- Audience: (1) an engineer running OpenFOAM cases on a cluster. -->
# Overview


Sluice sits between your case and Slurm. You give it a manifest and a
case directory. It checks both, freezes a cached copy, makes a private
run copy, records the job, submits to Slurm, and watches the result.

OpenFOAM runs the simulation. Slurm schedules it. Sluice connects the
two and keeps the workflow repeatable. It never hides cluster details
you need for debugging: the exact batch script stays in the run
directory.

One idea per object: the manifest describes, the cache freezes, the
run directory mutates, the database remembers, Slurm decides.
