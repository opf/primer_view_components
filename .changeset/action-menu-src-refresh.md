---
'@openproject/primer-view-components': minor
---

Reload deferred `Primer::Alpha::ActionMenu` items when `src` changes on `<action-menu>` or `refresh()` is called. A primary menu rendered with `src:` now renders its loader in a `<template>` with an empty overlay body, and a lazy menu carries `data-ready` before it first opens. The first loaded item keeps its tab stop when it receives focus. See "Refreshing deferred content" in the `Primer::Alpha::ActionMenu` docs for details.
