---
'@openproject/primer-view-components': patch
---

Keep a deferred ActionMenu sub-menu open when its content loads, at any depth, focusing its first focusable item instead of closing the menu. An empty or failed load closes the sub-menu, returns focus to its item, and fetches again on next open. Focus moved by a consumer during loading is preserved.
