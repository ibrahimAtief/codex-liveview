---
name: codex-liveview-browser-testing
description: Use when Codex tests, debugs, verifies, or changes a web UI in a visible browser, especially for local pages, styling problems, responsive behavior, overflow, failed assets, or screenshots.
---

# Codex LiveView Browser Testing

Use this skill for browser-based UI testing and debugging where a human and Codex should inspect the same visible page.

## Operating rules

- Preserve the human’s browser control. Do not silently navigate, submit forms, change data, or close the user’s tab.
- Keep the workflow local-first. Do not create public URLs, remote streams, credential capture, or cloud dependencies without explicit approval.
- Use selected screenshots after meaningful state changes; never stream continuous screenshots into model context.
- If the page is a local project, inspect project instructions and project status/memory docs before substantial changes.

## Diagnostic workflow

Follow this order and report evidence, not assumptions:

1. Confirm the final URL, navigation result, page title, and document readiness.
2. Check failed network requests, especially CSS, JavaScript, fonts, images, source maps, and data requests.
3. Check console errors and warnings.
4. Confirm stylesheets and scripts are present and applied; do not treat an HTML 200 alone as page health.
5. Measure viewport width/height, document width/height, scroll dimensions, and visible element rectangles.
6. Detect horizontal overflow and identify likely candidates by selector, width, and position.
7. Capture one settled frame after the page finishes loading or after a meaningful user action.
8. Summarize the result in plain language before proposing code changes.

### Diagnostic phases

Label each published snapshot with one phase:

- `initial-load`: the first stable observation before Codex or the user performs the test action.
- `action`: the immediate observation after a meaningful click, navigation, search, filter, or form interaction; report only changed facts.
- `settled-result`: the final observation after the page and dependent data finish settling; this is the phase used for a final screenshot and edit decision.

Do not call an `initial-load` or `action` snapshot the final result. The action phase is intentionally compact; keep the phase in the handoff and manifest so resumed work can identify which screen is authoritative.

Before capturing the settled frame, record the browser CSS viewport (`innerWidth`, `innerHeight`) and document dimensions. After capture, record the actual raster dimensions (`raster.width`, `raster.height`) separately; device scale factors can make raster pixels differ from CSS pixels. Never reuse an older screenshot path when a newer meaningful browser state has been captured.

Only publish a screenshot after a visual and structural integrity check confirms that it is one coherent viewport or full-page capture. Include `integrity: 'verified'` only after that check. If the frame is duplicated, tiled, stale, or cannot be inspected, omit the screenshot or keep the last verified reference; do not overwrite good evidence with it.

## Shared-page handoff

- Prefer the user’s existing authenticated visible browser tab when it is available.
- Claim only a tab returned by the browser tool’s current tab-list operation; never guess a tab ID.
- Keep a user-facing page open when the user needs to inspect it directly.
- Before finishing browser work, release or hand off the tab according to the browser tool’s finalization rules.

## Local startup

- Use the project’s documented startup command and wait for the server to be ready before diagnosing the browser.
- Before the first handoff or after a resume, run `scripts/ensure-liveview.ps1`. It reuses a responding LiveView instance; otherwise it starts only the documented LiveView `npm.cmd start` command and waits for `/api/evidence/health`.
- Set `CODEX_LIVEVIEW_ROOT` when the LiveView project is installed somewhere other than the local default. The helper never starts the application under test.
- Start the application under test only with its own documented project command. If the page appears raw or incomplete, first verify that expected startup path; do not immediately blame a stylesheet or rewrite application code.

## Browser capability preflight

Before testing, run `scripts/preflight-browser.ps1` once. It reports the available Chrome/Edge installation, Node and Playwright availability, approved screenshot-root presence, independent HTTP capability, current LiveView health, and the shared-tab status supplied by the browser tool. It is read-only: it does not install browsers, dependencies, extensions, or start LiveView or the application under test. If the shared browser tool is available, use that visible tab; otherwise choose the strongest available fallback and report the limitation once.

## Automatic evidence publishing

After Codex has prepared and integrity-checked one snapshot JSON file, run `scripts/publish-evidence.ps1 -SnapshotPath <path>`. The helper reuses the readiness check, sends one `POST /api/evidence`, and reports `published=true` or `published=false`. It never starts the application under test and does not retry failed publishes.

## Compact final report

After the settled-result handoff, run `scripts/format-report.ps1 -SnapshotPath <path>`. It emits three compact lines: `observed` for direct browser facts, `independent-verification` for separate HTTP/handoff facts (independent verification), and `inference` for the edit-readiness decision. Use `-OutputPath` only when a local report file is useful. Do not present the inference as a direct observation, and do not repeat healthy resource details in the conversation.

## Reporting format

Return a compact evidence summary with:

- page URL/title/readiness;
- asset and data-request status;
- console status;
- viewport/document dimensions;
- overflow candidates;
- screenshot path or inline frame when available;
- whether the evidence is sufficient to edit code.

## Token-efficient reporting

Keep the conversation compact by default:

- Send one preflight summary and one handoff per meaningful browser state.
- After an action, report only new or changed facts; do not repeat unchanged project, session, URL, asset, or console details.
- Represent healthy assets and console checks as counts. List individual entries only for failures, environment restrictions, or requested detail.
- Capture a screenshot only after a meaningful state change or failure; never send duplicate frames.
- Keep full structured evidence in the local manifest and send a short result summary to the conversation.
- If LiveView is unavailable, report that once and continue the browser test without retry loops.

## Evidence-source classification

Classify each request using the strongest available evidence instead of guessing:

- `loaded`: the browser observed a successful resource response.
- `failed`: the browser or an independent probe observed an application failure such as HTTP 4xx/5xx.
- `environment-blocked`: the browser was prevented by the current environment, while an independent HTTP probe may still confirm the resource is healthy.
- `not-tested`: no browser observation or independent probe exists.

Keep browser observations and independent HTTP probes as separate fields. A blocked browser request is not an application failure when an independent probe succeeds. Report both facts compactly, for example: `browser environment-blocked · independent HTTP 200`. Do not list individual healthy resources unless requested.

## Startup and resume health

When LiveView is available, check `GET http://127.0.0.1:4173/api/evidence/health` during startup and after a resumed task before publishing a new handoff.

- `healthy` means the persisted evidence state is readable and contains saved records.
- `empty` is a valid first-run state; continue the browser diagnosis without treating it as a page failure.
- `unavailable` is a LiveView diagnostic warning; continue the browser diagnosis, preserve the last verified frame, and report that persistence health could not be confirmed.
- When retention needs checking, request the read-only `/api/artifacts/cleanup-dry-run` report. Never delete from the skill without the existing explicit approval flow.
- Publish the verified handoff only after the health result is known, or clearly report the dashboard-unavailable fallback.

## Local LiveView handoff

When Codex LiveView is running at `http://127.0.0.1:4173`, publish one compact evidence snapshot after a meaningful browser state change. Use one stable `sessionId` for the browser-debugging run, the real project name for `projectName` when available, and an optional `chatSessionId` or Codex task ID when the evidence belongs to a conversation. If there is no project or chat session, omit the optional field; LiveView keeps the evidence under an unassigned fallback.

```js
const handoff = await fetch('http://127.0.0.1:4173/api/evidence', {
  method: 'POST',
  headers: { 'content-type': 'application/json' },
  body: JSON.stringify({
    projectName,
    sessionId,
    chatSessionId,
    phase,
    url,
    title,
    readyState,
    viewport: { width: innerWidth, height: innerHeight },
    document: { width: document.documentElement.scrollWidth, height: document.documentElement.scrollHeight },
    layout: { status, overflowPixels, candidates },
    assets,
    console: { errors, warnings },
    screenshot: { path: screenshotPath, raster: { width: raster.width, height: raster.height }, integrity: 'verified' }
  })
});

if (!handoff.ok) {
  throw new Error(`LiveView handoff failed: ${handoff.status}`);
}
```

Send compact measurements and selected frame references only. The local dashboard persists the latest metadata and bounded session history across normal restarts, and accepted handoffs are indexed in the local JSONL evidence manifest. If the dashboard is unavailable, continue the browser diagnosis and report the evidence in the task; do not treat dashboard delivery failure as a page failure.
