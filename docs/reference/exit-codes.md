<!-- Audience: (3) a contributor or hiring manager reading the repo. -->
# Exit codes


From `cmd/sluice/root.go` (`exitOK`, `exitJob`, `exitUsage`,
`exitEnvironment`):

| Code | Meaning | Examples |
|---:|---|---|
| 0 | success | run DONE, validate pass, `--help` |
| 1 | job or run failed | terminal FAILED/CANCELLED |
| 2 | usage or validation error | bad flags, invalid manifest, preflight findings |
| 3 | environment problem | `doctor` failure, missing Slurm tools |
| 130 | interrupted before submission | Ctrl-C while staging (live run) |
