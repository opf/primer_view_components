---
'@openproject/primer-view-components': patch
---

Keep a deferred ActionMenu sub-menu open when its content loads, at any depth, moving focus to its first item that can take focus instead of closing the whole menu; hidden groups are skipped, in the primary menu too. A deferred sub-menu whose response has no items closes and returns focus to its item; one whose response had no items or whose load failed fetches again when it next opens. Focus that a consumer moves while a sub-menu loads stays where it went. A static menu's deferred sub-menu now focuses its own first item rather than the primary menu's, and a static menu is ready only while none of its deferred sub-menus is loading. In a single-select menu, a sub-menu that loads later no longer replaces an item already chosen outside it.
