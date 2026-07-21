---
"@openproject/primer-view-components": patch
---

Sort `static/previews.json` entries by `lookup_path` so the output order is deterministic across platforms, instead of following `Lookbook.previews`' filesystem glob order (which differs between macOS and Linux for previews sharing the same name across statuses, e.g. `beta/heading` and `open_project/heading`).
