---
'@openproject/primer-view-components': minor
---

Allow deferred `Primer::Alpha::ActionMenu` content to be refreshed by changing the `src` attribute on `<action-menu>`, and pick up include-fragments inserted into the menu after connect. Deferred menus now apply the server-rendered selection to the dynamic label and form inputs on first load. Sub-menu focus traps are now released when sub-menus close or the menu is removed.
