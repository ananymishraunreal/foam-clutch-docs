<!-- Audience: (1) an engineer running OpenFOAM cases on a cluster. -->
# Preflight


Preflight rejects bad cases before they spend queue time. It requires
`system/` and `constant/` plus `0/` or `0.orig/`. It walks only those
input directories and rejects two things: symlinks escaping the case,
and known code-loading directives (`#codeStream`, `#calc`,
`codedFixedValue`, `codedMixed`, `libs`). Docs and scripts elsewhere
are not scanned. Optionally it runs `foamDictionary` and `checkMesh`;
their failures become findings. Preflight is a first boundary, not a
sandbox: see [security](../security.md).
