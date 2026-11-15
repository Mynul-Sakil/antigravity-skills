---
name: playtest
description: "Spawn a visual browser agent to interactively click through and test frontend UI flows."
---

# Visual UI Playtest

Act as a Senior QA Automation Engineer. I need you to perform a visual E2E test using your browser automation tools.

## Instructions
1. Launch the headless browser using the Puppeteer/Browser tools.
2. Navigate to `http://localhost:3000` (or whichever URL the user specifies).
3. Authenticate with the credentials provided by the user.
4. Visually navigate to the target page, click the necessary buttons, and evaluate the UI state.
5. Capture screenshots to verify there are no visual bugs, layout overflows, or console errors.
6. If a button is unresponsive or a layout is broken, drop into the codebase, fix the React/API code, and retry the test until it is flawless.

**To the user:** Please provide the URL, credentials, and the specific feature or flow you want tested when triggering this command.
