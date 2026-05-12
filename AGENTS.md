# Project Agent Notes

This repository packages Pro review related Codex skills as a Codex plugin. Keep `.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json`, and the bundled `skills/*/SKILL.md` files aligned.

This is the Codex Desktop in-app browser variant, not a generic Chrome-profile or ChatGPT desktop GUI handoff. Do not switch to a `chatgpt-gui-handoff` style transport unless the user explicitly asks for that.

Use the skill when the user asks for:

- `프로 리뷰`
- `프로 분석`
- `프로 해소`
- `프로 리서치`
- `크로스 검증`
- `ChatGPT 웹앱에 추가 질문해서 검증`
- `외부 피드백 반영`
- `Pro 리뷰용 ZIP 만들어줘`
- `ZIP만 올려도 리뷰 가능하게 묶어줘`
- `GPT Pro 답변 참고해서 고칠 것만 고쳐줘`

Default behavior:

1. Build a compact local context brief with `skills/cross-review-bridge/scripts/New-CrossReviewBrief.ps1` when useful.
2. Build a self-contained ZIP with `skills/pro-review-package-handoff/scripts/New-ProReviewPackage.ps1` when ChatGPT Pro should receive richer context or files.
3. Use ChatGPT web through the Codex Desktop in-app browser by default.
4. Do not use OpenAI API or SDK calls unless the user explicitly asks for API mode.
5. Ask before sending any project content to ChatGPT web or another external reviewer.
6. Use the Codex in-app browser only after the user has logged in manually.
7. Prefer `Pro • 확장` in ChatGPT web when visible and appropriate.
8. Treat external feedback as advisory, then verify locally before applying changes, using `skills/external-feedback-integrator` when feedback needs classification.
