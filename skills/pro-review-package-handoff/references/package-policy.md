# Package Policy

## Include Strategy

Prefer the smallest package that preserves review context:

1. `000_*` instructions and manifest.
2. Git context: status, diff stat, focused diff, recent commits.
3. Codex work summary: task, assumptions, changed areas, verification already run, known gaps.
4. Approved changed files and named files.
5. Approved artifacts: PDFs, HTML, figures, screenshots, logs, test outputs, review letters, decision docs, evidence tables, claim-support matrices, audit notes.

Do not include a whole repository unless the user explicitly requests it and approves the risk.

## Exclude Strategy

Always exclude by default:

- `.git`, `.svn`, `.hg`
- `.env`, `.env.*`, private keys, certificates, credential stores
- `node_modules`, `.venv`, `venv`, build, dist, coverage, caches
- files with names suggesting secrets, tokens, credentials, passwords, or auth state
- package output folders such as `.codex-pro-review-packages`

If a text file contains secret-like patterns, include only a redacted copy and mark it in the manifest. Sensitive path names such as `.env`, private keys, tokens, and credential files are still skipped.

Large text files up to the package size limit are scanned before inclusion. Binary screenshots, PDFs, and office documents cannot be reliably secret-scanned, so approval review is mandatory.

## Approval Summary

Before creating or uploading a ZIP, show:

- destination
- package mode and goal
- included file paths
- skipped paths and reasons
- whether git diff/context files will be included
- whether staged diff/context files will be included
- any uncertainty about sensitive content

Proceed only after the user approves.

By default, generated package metadata uses only the project folder name. Include local absolute paths only when the user explicitly opts in.

## Manual Upload Fallback

If the browser cannot upload, provide:

```text
Upload this ZIP to ChatGPT Pro:
<absolute zip path>

Then paste or reference 000_REVIEW_PROMPT.md and ask it to read 000_READ_ME_FIRST.txt first.
```
