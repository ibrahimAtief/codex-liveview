# Codex LiveView Browser Testing

A local-first Codex skill for inspecting the same visible browser page as a human while testing or debugging web UIs.

## What it does

The skill guides Codex through a disciplined browser workflow:

- Confirms the final URL, title, and document readiness.
- Checks failed assets and data requests.
- Checks console errors and warnings.
- Measures viewport, document size, and horizontal overflow.
- Captures selected settled screenshots only after meaningful actions.
- Verifies screenshot integrity before publishing evidence.
- Publishes compact evidence to a local Codex LiveView dashboard.
- Preserves human control of the visible browser session.

## Automatic LiveView readiness

The bundled `scripts/ensure-liveview.ps1` helper:

1. Reuses an already-running LiveView server.
2. Starts the documented `npm.cmd start` command when LiveView is unavailable.
3. Waits for `/api/evidence/health`.
4. Reports a bounded startup or timeout error if readiness fails.

Set `CODEX_LIVEVIEW_ROOT` when LiveView is installed outside its local default path.

The helper starts only LiveView. It does not start, navigate, submit, or modify the application being tested.

## Local handoff

When LiveView is available at `http://127.0.0.1:4173`, the skill publishes one compact `POST /api/evidence` handoff after a meaningful browser state change. The handoff can include project/session identity, DOM measurements, asset status, console findings, and a verified screenshot reference.

If LiveView is unavailable after the readiness check, Codex continues the browser diagnosis and reports the handoff limitation instead of treating it as a page failure.

## Token-efficient reporting

The skill is designed to improve testing quality without increasing conversation overhead:

- One compact preflight and one handoff per meaningful state.
- Only new or changed facts after an action.
- Counts for healthy assets and console checks; details for failures or restrictions.
- No duplicate screenshots.
- Full structured evidence stays in the local manifest; the conversation receives the short result.

## Installation

Install or copy this skill folder into the Codex skills directory:

```text
$CODEX_HOME/skills/codex-liveview-browser-testing
```

The required file is `SKILL.md`. The `agents/openai.yaml` file provides display metadata, and `scripts/ensure-liveview.ps1` provides deterministic local readiness checks.

## Safety boundaries

- Local-first by default.
- No public URLs, remote streams, cloud dependencies, or credential capture.
- No continuous screenshot streaming.
- No silent browser takeover.
- Screenshots and traces remain outside the skill repository.

## License

MIT License. See [LICENSE](LICENSE).

## Origin

Idea, planning, and implementation by Luna 5.6 with Ibrahim Atief.
