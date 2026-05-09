# Cross Review Bridge

`cross-review-bridge` is a Codex skill for running a human-approved cross-review loop between a local Codex Desktop workspace and an external AI review surface such as ChatGPT web, ChatGPT Projects, Deep Research, Codex web, or another browser-accessible reviewer.

It keeps Codex Desktop as the source of truth and executor. External feedback is treated as advisory, then verified locally before code changes are applied.

## What It Does

- Builds compact review briefs from local project context.
- Supports review, analysis, debugging, and research handoffs.
- Redacts common secret patterns before generating the brief.
- Uses a human approval gate before sending project content to an external web app.
- Helps Codex classify external feedback as `apply`, `consider`, `reject`, or `needs user decision`.

## Install

After this repo is published, install the skill with Codex's skill installer from:

```text
https://github.com/NAMUORI00/cross-review-bridge/tree/main/skills/cross-review-bridge
```

In Codex, you can ask:

```text
Use $skill-installer to install https://github.com/NAMUORI00/cross-review-bridge/tree/main/skills/cross-review-bridge
```

Or run the installer script directly:

```powershell
python $env:USERPROFILE\.codex\skills\.system\skill-installer\scripts\install-skill-from-github.py --repo NAMUORI00/cross-review-bridge --path skills/cross-review-bridge
```

Restart Codex after installing a new skill.

## Usage

Example prompts:

```text
Use $cross-review-bridge to cross-check this project through ChatGPT web.
```

```text
프로 리뷰
```

```text
크로스 검증
```

```text
외부 피드백 반영
```

The skill will prepare a brief, identify the destination, summarize what will be sent, and ask for approval before submitting anything to an external reviewer.

## Local Brief Generation

The bundled PowerShell script can generate a review brief directly:

```powershell
.\skills\cross-review-bridge\scripts\New-CrossReviewBrief.ps1 -ProjectPath . -Mode Review -Goal "Review the current changes"
```

With included files:

```powershell
.\skills\cross-review-bridge\scripts\New-CrossReviewBrief.ps1 -ProjectPath . -Mode Debug -Goal "Investigate failing tests" -IncludeFiles src\app.ts,tests\app.test.ts
```

Copy the brief to the clipboard:

```powershell
.\skills\cross-review-bridge\scripts\New-CrossReviewBrief.ps1 -ProjectPath . -Mode Analysis -Goal "Assess architecture" -CopyToClipboard
```

## Safety Model

This skill is intentionally semi-automatic:

- User login happens manually in the browser.
- Project content is summarized before transmission.
- External web app submission requires explicit approval.
- External feedback is checked against local files and tests before implementation.

Do not use this skill for bulk automated extraction from ChatGPT or for sending secrets, credentials, customer data, or unrelated private files.

## Repository Layout

```text
skills/cross-review-bridge/
  SKILL.md
  agents/openai.yaml
  references/
  scripts/
```

## License

MIT

