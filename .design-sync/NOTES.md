# design-sync notes — primer_view_components

## This repo needs a custom adapter step

Primer renders in Ruby. There is no React entry point, so `package-build.mjs` cannot
consume this repo directly. `.design-sync/generate-adapter.mjs` builds one:

1. Scrapes every routable Lookbook preview's real rendered HTML.
2. Emits `.ds-gen/` — a React package whose components inject that exact markup and
   side-effect-import Primer's own compiled custom-element bundle.
3. Emits `.design-sync/previews/<Name>.tsx` (one cell per scenario) and
   `.ds-gen/docs/<Name>.md` (the `.prompt.md` source, from `static/info_arch.json`).

Nothing is reimplemented: every byte of markup comes from Primer's own renderer.

**The Lookbook server must be running before the generator:**

```sh
cd demo && bin/rails s -p 4567     # gems are already satisfied; vite is not needed
node .design-sync/generate-adapter.mjs
```

Assets 404 in that server without vite, which does not matter — only the markup is read.

## Discovery comes from Lookbook, not info_arch

`/lookbook/previews.json` is the only source that knows which scenarios are routable.
`static/info_arch.json` lists preview paths that **404**: scenarios collected under a
`@!group` are not individually addressable (`blankslate/option_narrow` → 404), the group
renders them together on one page (`blankslate/options` → 200). The generator therefore
takes each group as a single cell and drops its nested examples. `info_arch.json` is still
the metadata source (description, Ruby arguments, slots, status).

`playground` scenarios are excluded — they are argument-driven scaffolds that render the
same as `default`.

## The stylesheet list is not negotiable

`emitCss` mirrors `demo/app/assets/stylesheets/application.postcss.css`, which is what a
Primer page is expected to load. Dropping `@primer/css` leaves every string in the browser
default serif and a slab of colour tokens undefined — it is not a cosmetic omission.
Only the `light` and `dark` primitives themes ship; the other seven accessibility themes
would triple the stylesheet for variants the cards never select.

Primer's functional colour tokens are scoped to `[data-color-mode][data-light-theme]`, so
the adapter puts those attributes on every card root. Without them every colour resolves
to nothing.

## ButtonMarketing needs CSS the demo does not load

`marketing-buttons.css` is in `emitCss`'s list even though `application.postcss.css`
omits it. `ButtonMarketing`'s default scheme is styled entirely by `--color-mktg-*`
properties that only that file defines, so without it the button renders with no
background and no text colour — invisible, not merely off-brand. Primer's own Lookbook
shows the same gap; the card is correct because this pipeline ships the file.

## Cards have no props, by design

`<Name>Props` is `className`/`style`/`preview` only. The Ruby component's arguments are
**not** React props — advertising them would make the design agent write
`<Button size="large">` and silently get the scraped default forever. The argument tables
live in each `.prompt.md` as reference, and the way to vary a component is to copy its
markup and write Primer classes.

## Dropping a useless cell: use the generator, not cfg.overrides

`cfg.overrides.<Name>.skip` does nothing here. It filters storybook story ids, and a
package-shape build has none, so the key is accepted and silently ignored. To drop a
scenario, add it to `EXCLUDED_SCENARIOS` in `generate-adapter.mjs` — the cell then never
reaches the preview `.tsx`. Three scenarios are excluded today and each says why.

`cardMode`/`primaryStory`/`viewport` overrides in the config *do* work. `Dialog` needs
`primaryStory: "InitallyOpen"`: every other Dialog scenario is a closed dialog, so any
other choice makes the card a lone trigger button.

## Interaction-only states never render

Menus, dialogs, overlays and tooltips render **closed**, because that is what static HTML
contains — opening them needs a click, and hover states need a pointer. Those cards show
the trigger, which is honest but not informative; the component's `.prompt.md` is where a
reader learns what the open state holds. Do not read these as broken cards.

Related screenshot artefact: `_screenshots/*.png` are taken at a fixed canvas, so a
trigger-only card looks like a button stranded in a large void. Check `maxHeight` in
`.render-check.json` before believing it — those components measure 32px, and the product
card is compact.

## Known render warns

Check new warn lines against this list; anything not here is new.

- `[TOKENS_MISSING]` (120 properties). Upstream condition, not a packaging gap. The
  legacy `--color-*` aliases and all `--color-mktg-*` are defined nowhere in
  `@primer/css`, and Primer's own demo does not load the marketing CSS that defines the
  latter either. Verified against a rendered card before accepting.

## Re-sync risks

- **The generator is only as current as the Lookbook server.** A re-sync that forgets to
  boot `demo` fails loudly (the generator exits 1) rather than shipping stale markup.
- **Scraped markup is a snapshot.** A Primer release that changes a component's rendered
  output changes the cards only when the generator is re-run. Re-run it on every sync.
- **`.design-sync/previews/*.tsx` are generated** by `generate-adapter.mjs`, unlike the
  usual hand-authored convention for that directory. Do not hand-edit them; the next
  generator run overwrites them. Presentation fixes belong in `cfg.overrides`.
- **The `@primer/css` and `@primer/primitives` versions are whatever the repo has
  installed.** A major bump in either can change the token set the cards render against.
- **`Avatar`, `AvatarStack` and `OpenProjectAvatarWithFallback` load images from
  github.com.** Their previews reference remote URLs, so those cards depend on network
  access at render time and on the host allowing external images. The fallback-initials
  variants are self-contained and unaffected.
- **Scenario counts move with Primer's preview files.** 89 components / 474 cells today,
  from all routable non-playground scenarios. A release that adds previews grows the
  bundle automatically; nothing caps it.
