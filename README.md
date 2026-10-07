# foam-clutch documentation

Standalone documentation for the foam-clutch project
(source: `/home/shared/foam-clutch`).
The repo's top-level `README.md` is the quick-start; these files are the
full reference.

| File | What it answers |
|---|---|
| `architecture.md` | How does foam-clutch work? Pipeline, components, state machines, backends, checkpoint protocol, failure modes. |
| `case-files.md` | What must / may / must-not be inside my OpenFOAM case folder to run through foam-clutch? Worked heavySimple and heavyBuoyant examples plus a new-case checklist. |
| `repository.md` | What does every single file in the repo do? Directory by directory, file by file. |

Conventions used across these docs:

- `<case>` means the OpenFOAM case directory (e.g.
  `/home/shared/openfoam/heavySimple`).
- `<runDir>` means one isolated per-job directory:
  `<case>/.foam-runs/<local-job-id>/`.
- `ranks` always means `resources.nodes × resources.tasksPerNode`.
- Code references look like `internal/service/service.go:261` (file:line,
  relative to the repo root).
