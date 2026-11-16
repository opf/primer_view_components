---
'@openproject/primer-view-components': minor
---

`Primer::Alpha::ActionList` with `show_dividers` draws item dividers between items instead of inserting section dividers – just like Primer React. The line starts at the label, so it does not divide leading visuals. Items of such a list carry an `ActionListItem--divided` class; hand-written ActionList markup has to set it per item to get the lines. Subclasses of `ActionList`, such as the lists of `ActionMenu`, `NavList` and `SelectPanel`, ignore `show_dividers`. Hidden items are not supported: remove items from the DOM instead of hiding them.
