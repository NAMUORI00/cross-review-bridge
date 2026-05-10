# Cross Review Bridge

`cross-review-bridge` is a Codex skill for running a browser-first, human-approved cross-review loop between a local Codex Desktop workspace and ChatGPT web in the Codex Desktop in-app browser.

It keeps Codex Desktop as the source of truth and executor. ChatGPT web feedback is treated as advisory, then verified locally before code changes are applied.

## Positioning

This is not a generic ChatGPT GUI handoff skill. It is a Codex Desktop in-app browser cross-review bridge.

If you already use a local `chatgpt-gui-handoff` style workflow, treat that as a sibling pattern:

- `chatgpt-gui-handoff`: hands prompts to ChatGPT through a dedicated Chrome profile or ChatGPT desktop app.
- `cross-review-bridge`: uses the Codex Desktop in-app browser / browser-use path so Codex can stay inside the desktop app, select visible ChatGPT web modes, submit after approval, and read the visible response.

The long-term shape can support transport adapters such as `in-app-browser`, `chrome-profile`, `chatgpt-desktop`, `manual-copy`, and explicit `api` mode. Today this plugin defaults to `in-app-browser` and disables API-backed review unless the user explicitly requests API mode.

## What It Does

- Builds compact review briefs from local project context.
- Supports review, analysis, debugging, and research handoffs.
- Redacts common secret patterns before generating the brief.
- Uses the Codex Desktop in-app browser to work through ChatGPT web by default.
- Uses a human approval gate before sending project content to ChatGPT web.
- Helps Codex classify external feedback as `apply`, `consider`, `reject`, or `needs user decision`.

## Browser-First, No API By Default

This plugin is intentionally not an OpenAI API wrapper. For normal use it should not call the OpenAI API, Responses API, Chat Completions API, SDK scripts, or any API-backed reviewer.

Default flow:

1. Codex Desktop builds a local brief.
2. Codex Desktop opens or reuses ChatGPT web in the in-app browser.
3. The user logs in manually if needed.
4. Codex selects the visible ChatGPT mode, such as `Pro • 확장`, only after observing the web UI.
5. Codex asks before submitting project content.
6. Codex reads the visible web response and verifies it locally.

API mode is only allowed when the user explicitly asks for API mode.

## Install In Codex Desktop

This repository is packaged as an official-style Codex plugin with a `.codex-plugin/plugin.json` manifest and a bundled `skills/` directory.

Add the marketplace once:

```powershell
codex plugin marketplace add NAMUORI00/cross-review-bridge --ref main
```

Then restart Codex Desktop, open the Plugins directory, choose `NAMUORI00 Codex Plugins`, and install `Cross Review Bridge`.

You can also install from the repo URL if your Codex surface supports Git-backed plugin marketplaces:

```text
https://github.com/NAMUORI00/cross-review-bridge
```

## Install As A Standalone Skill

If you only want the skill folder instead of the plugin package, install it with Codex's skill installer:

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
Use $cross-review-bridge to cross-check this project through ChatGPT web in the Codex Desktop browser.
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
- API-based review is disabled unless the user explicitly requests API mode.

Do not use this skill for bulk automated extraction from ChatGPT or for sending secrets, credentials, customer data, or unrelated private files.

## Repository Layout

```text
.codex-plugin/
  plugin.json
.agents/plugins/
  marketplace.json
skills/cross-review-bridge/
  SKILL.md
  agents/openai.yaml
  references/
  scripts/
```

## License

MIT
