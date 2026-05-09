# Project Agent Notes

This repository packages the `$cross-review-bridge` Codex skill as a Codex plugin. Keep `.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json`, and `skills/cross-review-bridge/SKILL.md` aligned.

Use the skill when the user asks for:

- `프로 리뷰`
- `프로 분석`
- `프로 해소`
- `프로 리서치`
- `크로스 검증`
- `ChatGPT 웹앱에 추가 질문해서 검증`
- `외부 피드백 반영`

Default behavior:

1. Build a compact local context brief with `skills/cross-review-bridge/scripts/New-CrossReviewBrief.ps1` when useful.
2. Ask before sending any project content to ChatGPT web or another external reviewer.
3. Use the Codex in-app browser only after the user has logged in manually.
4. Prefer `Pro • 확장` in ChatGPT web when visible and appropriate.
5. Treat external feedback as advisory, then verify locally before applying changes.
