---
name: external-feedback-integrator
description: Use when Codex receives feedback from ChatGPT Pro, an external reviewer, review package ZIP results, browser-based critique, manuscript review, code review, audit feedback, or pasted advisory comments and should validate, classify, and selectively apply it. Trigger for requests like "외부 피드백 반영", "Pro 리뷰 피드백 적용해줘", "받은 피드백을 apply/consider/reject로 분류해줘", "GPT Pro 답변 참고해서 고칠 것만 고쳐줘", or "리뷰 결과를 로컬 코드/문서와 대조해줘". Treat external feedback as advisory, reject hallucinations, and verify locally before claiming changes.
---

# External Feedback Integrator

## Core Rule

External feedback is advisory. Do not apply it directly. Compare every recommendation against local files, tests, artifacts, and user intent before changing anything.

Classify each item as:

- `apply`: supported by local evidence and worth implementing now
- `consider`: plausible but not necessary for the current task
- `reject`: wrong, hallucinated, unsafe, out of scope, or unsupported
- `needs user decision`: valid but changes product/research direction, scope, risk, or tradeoffs

## Workflow

1. Capture feedback:
   - Use pasted text, a saved ChatGPT response, or `external-feedback.md`.
   - If needed, run `scripts/Convert-ExternalFeedback.ps1` to create a classification worksheet.

2. Extract action items:
   - bugs/regressions
   - missing tests or evidence
   - manuscript/document edits
   - overclaim or unsupported claims
   - artifact QA: tables, figures, equations, captions, references, screenshots, logs
   - security/privacy concerns

3. Verify locally:
   - Inspect referenced files and diffs.
   - Reject invented files, APIs, commands, citations, claims, or test results.
   - Check whether the feedback fits the user's actual goal.

4. Decide:
   - Build a concise table with classification, rationale, and planned action.
   - Ask the user before applying `needs user decision` items.

5. Apply:
   - Implement only validated `apply` items.
   - Keep diffs minimal.
   - Do not perform broad rewrites because an external reviewer suggested them.

6. Verify:
   - Run relevant tests, builds, render checks, or artifact inspections.
   - Report applied, considered, rejected, and deferred items.

## Script

Create a worksheet from a feedback file:

```powershell
.\skills\external-feedback-integrator\scripts\Convert-ExternalFeedback.ps1 `
  -ProjectPath . `
  -FeedbackPath .\external-feedback.md
```

Read `references/feedback-classification.md` for classification policy. Read `references/application-policy.md` before applying changes that affect scope, claims, security, or research conclusions.
