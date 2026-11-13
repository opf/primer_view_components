---
'@openproject/primer-view-components': minor
---

Adds `setError`, `setSuccess` and `clearError` to `primer-color-input`. Text
field and color field validation now set `aria-invalid` on error and remove it
on success and clear; clearing also removes `invalid`.
