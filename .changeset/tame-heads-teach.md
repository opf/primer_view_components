---
'@openproject/primer-view-components': minor
---

Remove the `collapsed_search` argument from `Primer::OpenProject::SubHeader`.
The search bar now collapses automatically when empty and a `quick_filter` or
`filter_button` slot is used. Or in mobile views (md and below).
