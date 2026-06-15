---
'@openproject/primer-view-components': patch
---

Fix selection of nodes with the same path in Primer::Alpha::TreeView

When a `[role=treeitem]` element carries a `data-node-id` attribute, that id is now included as `nodeId` in the hidden form input payload (`{path, nodeId?, value?}`). Trees with duplicate-path nodes should set `data-node-id` to a stable unique identifier so the server can distinguish which node was selected.

**Breaking change in `TreeViewElement#checkOnlyAtPath`:** if the given path is not found the method is now a no-op. Previously it would uncheck all active nodes before failing to check the missing node, which could be used as an indirect "clear selection" mechanism. Use explicit `setNodeCheckedValue(node, 'false')` calls if that behaviour is needed.
