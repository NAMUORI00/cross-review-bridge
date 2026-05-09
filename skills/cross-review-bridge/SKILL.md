---
name: cross-review-bridge
description: Use when Codex should run a human-approved cross-review loop between the local project and an external AI review surface such as ChatGPT web, ChatGPT Projects, Deep Research, Codex web, or another browser-accessible reviewer. Trigger for requests like "프로 리뷰", "프로 분석", "크로스 검증", "외부 피드백 받아와", "웹앱에 추가 질문해서 검증해", "ChatGPT Pro로 검토해", or "받은 피드백 반영". Use for project feedback, architecture review, debugging, research, UX critique, and verification handoff. Do not use for fully automatic bulk extraction from ChatGPT or for sending secrets without explicit user approval.
---

# Cross Review Bridge

## Core Rule

Keep Codex Desktop as the source of truth and executor. Treat the external reviewer as an advisory second opinion. Never apply external feedback directly without checking it against the local codebase, tests, and user intent.

Before sending project content to a web app, summarize exactly what will be sent and ask the user to approve the transmission. Do not send secrets, tokens, private credentials, customer data, or large unrelated files.

## Workflow

1. Classify the request:
   - Review: current diff, PR, or implementation feedback.
   - Analysis: architecture, maintainability, testing, product, or UX assessment.
   - Debug: failing tests, logs, reproduction steps, error traces.
   - Research: external docs, alternatives, library/API comparison, current best practice.
   - Apply: user pasted external feedback and wants Codex to turn it into code changes.

2. Collect local context:
   - Prefer `git status --short`, `git diff --stat`, and `git diff`.
   - Include relevant files only. Avoid generated folders, dependency folders, build outputs, and secrets.
   - If a UI issue is involved, use Browser for local app screenshots or DOM state when available.
   - To create a deterministic brief, run `scripts/New-CrossReviewBrief.ps1` with `-ProjectPath`, `-Mode`, `-Goal`, optional `-IncludeFiles`, and optional `-CopyToClipboard`.

3. Build a compact review brief:
   - State the project goal and current task.
   - Include changed files and the smallest useful snippets or diffs.
   - Ask for prioritized findings with concrete next steps.
   - Ask the external reviewer to mark uncertainty and avoid broad rewrites.

4. Prepare the external channel:
   - Prefer the existing ChatGPT Project when the user has one open.
   - For ChatGPT web, set the strongest appropriate mode available, such as Pro extended, only after observing the UI.
   - Use the in-app browser only when the user has logged in and the page is reachable. If authentication breaks, ask the user to complete login manually.

5. Get approval:
   - Show a short "Send summary" naming the destination and content categories.
   - Ask the user for approval before pressing send or uploading files.
   - If the user already gave explicit approval for this exact payload and destination, proceed.

6. Send and wait:
   - Paste the brief into the browser-accessible reviewer.
   - Submit only after approval.
   - Wait for completion, then read the final answer from the page.

7. Synthesize:
   - Save or summarize the external response as `external-feedback.md` or in the final answer.
   - Classify each recommendation as `apply`, `consider`, `reject`, or `needs user decision`.
   - Explain any rejected advice briefly.

8. Execute locally:
   - Apply only validated recommendations.
   - Run relevant tests or checks.
   - Report what changed and what remains uncertain.

## Browser Notes

The in-app browser is officially intended for local/public pages, and authenticated web apps can be brittle. This project has verified that the current ChatGPT Project session can be used after user login, including selecting `Pro • extended`, submitting a question, and reading the response. Treat that as a convenience path, not a guarantee.

If the page becomes `about:blank`, loses session state, or OAuth stalls:

1. Reopen the target ChatGPT Project or `https://chatgpt.com/`.
2. Ask the user to complete login manually.
3. Re-check the page title, URL, project name, and input box before sending anything.

## Prompt Shape

Use concise prompts like this:

```text
You are the external reviewer in a cross-review loop. Codex Desktop has local code access and will implement only validated recommendations.

Review goal:
[goal]

Context:
[diff / files / logs / screenshots summary]

Return:
- Critical issues first
- Concrete fixes
- Risks and assumptions
- What not to change
```

## Applying External Feedback

When the user pastes feedback:

1. Extract action items.
2. Compare them with local source and tests.
3. Reject hallucinated files, APIs, or requirements.
4. Implement the smallest safe set.
5. Verify and report.
