---
'@openproject/primer-view-components': patch
---

Keep the tab stop on the first loaded item of a deferred `Primer::Alpha::ActionMenu` when it receives focus. Closing any `Primer::Alpha::ActionMenu` by clicking outside it no longer always returns focus to its button: focus that the click or other code moved elsewhere stays there, and returns to the button only when it would otherwise be lost.
