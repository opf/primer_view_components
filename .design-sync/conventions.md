# Building with Primer ViewComponents

This design system is **rendered by Ruby**, not React. Every component in it is a
`Primer::*` ViewComponent, and each card here shows that component's real
server-rendered HTML.

## The one thing to understand first

**The components in this library take no content props.** `<Button />` renders a fixed
piece of Primer's own markup; `children`, `size`, `scheme` and the rest are Ruby
arguments, not React props. Passing them does nothing.

So build UI the way a non-Rails Primer consumer does: **write Primer's classes directly.**
Open the component's card, copy the markup, change the text. Each component's
`.prompt.md` lists the Ruby arguments for reference and names every rendered variant you
can view via `preview="<name>"`.

```jsx
// Wrong — props are ignored, you get the default render
<Button scheme="primary">Save</Button>

// Right — Primer's own classes, your own content
<button type="button" className="Button Button--primary Button--medium">
  <span className="Button-content">
    <span className="Button-label">Save</span>
  </span>
</button>
```

## Wrap the root, or nothing has colour

Primer's colour tokens are defined under attribute selectors, not on `:root`. A tree
without them renders with every colour unresolved:

```jsx
<div data-color-mode="light" data-light-theme="light" data-dark-theme="dark">
  {/* your app */}
</div>
```

Set `data-color-mode="dark"` to switch. Only `light` and `dark` ship.

## The styling idiom: utility classes

Primer's own utilities are the vocabulary for your layout glue — don't invent class names
and don't reach for ad-hoc inline styles. The families, with real examples:

| Concern | Classes |
| --- | --- |
| Display | `d-flex` `d-block` `d-inline` `d-inline-block` `d-inline-flex` `d-none` `d-table` |
| Flex | `flex-row` `flex-column` `flex-wrap` `flex-1` `flex-justify-between` `flex-items-center` |
| Margin | `m-0`…`m-6`, per side `mt-` `mr-` `mb-` `ml-` `mx-` `my-`, negative `mt-n1` |
| Padding | `p-0`…`p-6`, per side `pt-` `pr-` `pb-` `pl-` `px-` `py-` |
| Text | `text-bold` `text-small` `text-center` `text-right` `lh-condensed` |
| Colour | `fgColor-default` `fgColor-muted` `fgColor-accent` `fgColor-danger`, `bgColor-default` `bgColor-muted` `bgColor-emphasis` |
| Border | `border` `border-top` `border-0` `rounded-2` `borderColor-default` `borderColor-muted` |
| Layout | `position-relative` `position-absolute` `overflow-hidden` `float-right` |

The numeric scale is Primer's spacing scale (`1`≈4px … `6`≈40px) — use it rather than
pixel values. `fgColor-*`/`bgColor-*` are the current names; `color-fg-*`/`color-bg-*`
also resolve but are the older spelling, so prefer the former.

In CSS of your own, use the tokens rather than literals:

```css
.my-panel {
  color: var(--fgColor-default);
  background: var(--bgColor-default);
  border: 1px solid var(--borderColor-default);
  font-family: var(--fontStack-sansSerif);
}
```

## Where the truth is

Read these before styling anything — they beat any summary:

- `_ds/<folder>/styles.css` — the whole stylesheet: `@primer/primitives` tokens, then
  Primer's component CSS, then `@primer/css` `base`/`buttons`/`layout`/`utilities`/`markdown`.
  Grep it for a class or token to confirm it exists.
- `components/<group>/<Name>/<Name>.prompt.md` — that component's description, its Ruby
  arguments and slots, and the variants its card renders.

## Interactive components

`Dialog`, `Overlay`, `ActionMenu`, `SelectPanel`, `Tooltip` and friends are custom
elements (`<action-menu>`, `<tool-tip>`, `<modal-dialog>`) and the bundle registers them,
so copied markup stays functional. Their cards show the **closed** state, because that is
what a static render produces — check the `.prompt.md` for what the open state contains.
