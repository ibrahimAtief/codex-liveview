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

The bundled `scripts/publish-evidence.ps1` helper automates the handoff after Codex has prepared and integrity-checked one snapshot JSON file. It reuses the readiness helper, posts once to `/api/evidence`, and reports `published=true` or `published=false`. It never starts the application under test and never retries a failed publish loop.

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

## Evidence-source classification

Requests are classified as `loaded`, `failed`, `environment-blocked`, or `not-tested`. Browser observations remain separate from independent HTTP probes, so a testing-environment restriction is not mistaken for an application failure.

## Installation

Install or copy this skill folder into the Codex skills directory:

```text
$CODEX_HOME/skills/codex-liveview-browser-testing
```

The required file is `SKILL.md`. The `agents/openai.yaml` file provides display metadata, while `scripts/ensure-liveview.ps1` and `scripts/publish-evidence.ps1` provide deterministic local readiness and handoff checks.

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
