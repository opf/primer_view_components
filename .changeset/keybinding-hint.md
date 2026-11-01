---
'@openproject/primer-view-components': minor
---

Add `Primer::OpenProject::KeybindingHint`, a port of Primer React's `KeybindingHint`, and a `keybinding_hint` trailing visual slot type on `Primer::Beta::Button` and `Primer::Alpha::ActionList::Item`. Adds `lit-html` as a runtime dependency. Raises the `@primer/primitives` peer dependency to `^11.5.1`, which introduces the `--buttonKeybindingHint-*` tokens. Key names follow the current locale through the new `keybinding_hint` locale scope.
