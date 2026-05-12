# Manifest Schema

`000_MANIFEST.md` should include:

- package name, generation time, mode, goal, project path
- read order
- included files table: package path, source path, size, category, safety status
- skipped files table: source path, reason
- git context availability, including staged and unstaged diff files
- safety notes
- next step for the external reviewer

The manifest is human-readable Markdown by design. Do not require external tools to parse it.
