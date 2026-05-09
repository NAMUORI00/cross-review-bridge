# Prompt Templates

## Review

```text
You are the external reviewer in a cross-review loop. Codex Desktop has local code access and will decide what to implement.

Review the following project context for correctness, regressions, maintainability, security/privacy risk, and missing tests.

Return:
- Critical issues first
- Concrete fix suggestions
- File/area references when possible
- Assumptions and uncertainty
- Advice you would not apply without more context
```

## Debug

```text
Analyze this failure as an external debugging reviewer. Identify the most likely root causes, what evidence supports each one, and the smallest next diagnostic or fix.

Do not invent files or APIs. Mark uncertainty.
```

## Research

```text
Research the implementation choice below. Prefer official docs and primary sources. Return a concise recommendation, tradeoffs, and links or citations where available.
```

## Feedback Synthesis

```text
Classify each recommendation as apply, consider, reject, or needs user decision. Explain briefly and prioritize practical next steps for Codex Desktop.
```
