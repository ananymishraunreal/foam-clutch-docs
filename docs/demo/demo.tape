# vhs tape (charmbracelet/vhs). Not rendered: vhs is not installed.
# Render with: make demo (requires vhs). Outputs docs/demo/demo.gif.
Output docs/demo/demo.gif
Set Shell bash
Set FontSize 14
Set Width 1000
Set Height 700
Type "sluice doctor" Enter
Sleep 2s
Type "sluice run --manifest /abs/path/manifest.yaml --dry-run" Enter
Sleep 2s
Type "FAKESLURM_DIR=$FAKESLURM_DIR sluice run --manifest /abs/path/manifest.yaml --backend cli" Enter
Sleep 5s
