---
name: pro-review-package-handoff
description: Use when Codex should package the current work, code changes, documents, artifacts, logs, screenshots, PDFs, HTML, figures, review letters, evidence tables, or audit material into a self-contained ZIP for ChatGPT Pro or another external reviewer. Trigger for requests like "Pro 리뷰용 ZIP 만들어줘", "GPT Pro에 줄 패키지 만들어줘", "ZIP만 올려도 리뷰 가능하게 묶어줘", "코덱스가 작업한 내용 전체를 외부 검토용으로 패키징해줘", "논문 PDF/HTML/figure/review를 묶어줘", or "거절위험/개선도 검토 패키지 만들어줘". Always show the file list and get user approval before creating or uploading a package. Never include secrets or credentials.
---

# Pro Review Package Handoff

## Core Rule

Create a compact, self-contained review package that lets an external reviewer understand what Codex Desktop did and what feedback is needed from the ZIP alone. Keep Codex Desktop as the source of truth. External feedback is advisory and must later be checked locally, preferably with `$external-feedback-integrator`.

Do not send or package secrets. Before creating a transferable ZIP, show the proposed file list and ask the user to approve it.

## When To Use

Use this skill for broad external review packages, not only research manuscripts:

- code changes, diffs, tests, logs, screenshots, and design notes
- papers, reviews, response letters, figures, HTML/PDF exports, and evidence tables
- audit material, claim support matrices, QA reports, and decision documents
- any Codex Desktop work where ChatGPT Pro should review context through an uploaded ZIP

Use `$cross-review-bridge` after this skill when the user wants Codex to upload the ZIP through ChatGPT web in the Codex Desktop in-app browser.

## Required ZIP Top-Level Files

Every package must contain these files at ZIP root:

- `000_READ_ME_FIRST.txt`
- `000_REVIEW_PROMPT.md`
- `000_MANIFEST.md`

The package script also creates:

- `000_CODEX_WORK_SUMMARY.md`
- `context/` with git status, diff stat, diff patch, recent commits, and task notes when available
- categorized `source/`, `artifacts/`, and `evidence/` folders for approved files

## Workflow

1. Identify the work scope:
   - current user goal and Codex task history
   - git status, changed files, diff, recent commits
   - tests, logs, screenshots, generated outputs, and relevant source files
   - PDFs, HTML, figures, review/decision docs, evidence tables, claim support matrices, and audit docs when present

2. Run a dry run:
   - Use `scripts/New-ProReviewPackage.ps1 -ProjectPath <repo> -Mode <mode> -Goal <goal> -DryRun`.
   - Add `-IncludeDiscoveredArtifacts` when the user expects non-code artifacts to be proposed.
   - Add `-IncludeFiles` for exact paths the user named.

3. Ask for approval:
   - Show the proposed included files and skipped files.
   - State the destination, usually "ChatGPT Pro web upload".
   - Do not create, upload, or transmit the ZIP until the user approves the list.

4. Create the package:
   - Run the same script without `-DryRun` after approval.
   - Prefer a focused `-IncludeFiles` list for sensitive repositories.
   - Use `-IncludeDiscoveredArtifacts` only when approved.

5. Hand off:
   - If browser upload works, use `$cross-review-bridge` to upload the ZIP and paste `000_REVIEW_PROMPT.md`.
   - If browser upload is blocked, give the ZIP path and a short manual upload instruction.

6. After feedback:
   - Use `$external-feedback-integrator` to classify and validate feedback before applying changes.

## Modes

- `General`: broad product, document, code, or artifact review.
- `CodeReview`: code correctness, regression, tests, security/privacy, maintainability.
- `Research`: research artifact, evidence, claim support, manuscript, figure, and review-risk package.
- `Manuscript`: paper improvement, prior review response, rejection-risk, figure/table/reference QA.
- `DecisionResponse`: prior decision/review letter response and reviewer concern closure.
- `Audit`: evidence, provenance, reproducibility, compliance, and claim-support audit.

## Safety Rules

- Never include `.env`, private keys, API keys, tokens, credentials, auth files, or customer/private personal data unless the user explicitly identifies specific files and confirms the risk.
- Default-exclude dependency folders, build outputs, caches, generated bulk folders, and VCS internals.
- If a selected text file appears to contain secret-like content, skip it and report the skip.
- Keep packages compact. Prefer diffs, summaries, and selected files over whole repositories.
- The external reviewer must mark unsupported or uncertain claims instead of filling gaps.
- The review prompt must prohibit overclaiming and broad rewrites without evidence.
- The package records only the project folder name by default. Use `-IncludeAbsoluteProjectPath` only when the user explicitly wants local absolute paths in the ZIP.

## Script

```powershell
.\skills\pro-review-package-handoff\scripts\New-ProReviewPackage.ps1 `
  -ProjectPath . `
  -Mode CodeReview `
  -Goal "Review Codex Desktop's current implementation for regressions" `
  -DryRun
```

After approval:

```powershell
.\skills\pro-review-package-handoff\scripts\New-ProReviewPackage.ps1 `
  -ProjectPath . `
  -Mode CodeReview `
  -Goal "Review Codex Desktop's current implementation for regressions" `
  -IncludeDiscoveredArtifacts
```

The script can be run directly, but the skill workflow still requires approval before using the resulting ZIP externally.

Read `references/package-policy.md` before packaging sensitive or large projects. Read `references/prompt-templates.md` when editing review prompt wording.
