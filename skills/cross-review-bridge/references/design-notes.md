# Design Notes

Use an official-style Codex plugin package for distribution, while keeping the skill installable on its own.

- OpenAI Codex skill docs say repository skills are loaded from `.agents/skills` and are intended for workflows relevant to a working folder.
- OpenAI Codex plugin docs position plugins as the distribution path for stable reusable workflows. The package root includes `.codex-plugin/plugin.json` and points `skills` at `./skills/`.
- The marketplace file at `.agents/plugins/marketplace.json` exposes this plugin to Codex Desktop/CLI plugin installation flows.
- The Codex in-app browser docs say it is intended for local/public pages and that signed-in sites are brittle; keep user login and data transmission approval human-gated.
- ChatGPT Projects are useful as the external review workspace because they keep chats, project instructions, files, and connected app context together.
- ChatGPT Pro usage should not become bulk automated extraction; keep this a human-approved review loop.
