#!/usr/bin/env node
// Builds the React adapter package that design-sync's converter consumes.
//
// Primer renders in Ruby, so there is no React entry point to bundle. This
// scrapes each Lookbook preview's real rendered HTML and wraps it in a React
// component that injects that exact markup, alongside Primer's own compiled
// stylesheet and custom-element bundle. Nothing here reimplements a component:
// every byte of markup comes from Primer's own renderer.
//
// Usage: node .design-sync/generate-adapter.mjs [--components A,B] [--base http://127.0.0.1:4567]

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(HERE, '..');
const OUT = path.join(REPO, '.ds-gen');
const PREVIEWS_DIR = path.join(HERE, 'previews');

const argv = process.argv.slice(2);
const arg = (name, dflt) => {
  const i = argv.indexOf(name);
  return i === -1 ? dflt : argv[i + 1];
};
const BASE = arg('--base', 'http://127.0.0.1:4567');
const ONLY = arg('--components', '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);
// Every routable scenario ships by default. These cards accept no content props,
// so a scenario without a cell is a variant the design agent can never see.
const MAX_PREVIEWS = Number(arg('--max-previews', '0')) || Infinity;

// Scenarios whose rendered output tells the reader nothing. Dropping them here is
// the only lever that works: `cfg.overrides.<Name>.skip` is inert for this source
// shape, because it filters storybook story ids that a package build never has.
const EXCLUDED_SCENARIOS = {
  // Fills the card with several screens of lorem ipsum to demonstrate scrolling.
  SelectPanel: ['scroll_container'],
  // A ~1000px empty scroll container with the trigger stranded in the middle.
  ActionMenu: ['in_scroll_container'],
  // Dropdown::Menu on its own renders an empty container: no trigger, no items.
  Dropdown: ['menu'],
};

const PRIMER_JS = path.join(REPO, 'app/assets/javascripts/primer_view_components.js');
const PRIMER_CSS = path.join(REPO, 'app/assets/styles/primer_view_components.css');
const PRIMITIVES = path.join(REPO, 'node_modules/@primer/primitives/dist/css');

// ---------------------------------------------------------------- component list

const pascal = (s) =>
  String(s)
    .replace(/[^a-zA-Z0-9]+/g, ' ')
    .trim()
    .split(' ')
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join('');

// info_arch.json stores nested structures as Python repr strings.
const pyLiteral = (raw) => {
  if (raw == null) return [];
  if (typeof raw !== 'string') return raw;
  const json = raw
    .replace(/(?<![A-Za-z0-9_])None(?![A-Za-z0-9_])/g, 'null')
    .replace(/(?<![A-Za-z0-9_])True(?![A-Za-z0-9_])/g, 'true')
    .replace(/(?<![A-Za-z0-9_])False(?![A-Za-z0-9_])/g, 'false');
  try {
    return JSON.parse(json.replace(/'/g, '"'));
  } catch {
    try {
      // Fall back to a tolerant pass for values containing apostrophes.
      return eval(`(${json.replace(/'([^']*)'/g, (_m, g) => JSON.stringify(g))})`);
    } catch {
      return [];
    }
  }
};

const groupOf = (fqn) => {
  const parts = fqn.split('::');
  if (parts.includes('Alpha')) return 'Alpha';
  if (parts.includes('Beta')) return 'Beta';
  return 'Core';
};

// Lookbook is the only source that knows which scenarios are actually routable:
// scenarios collected under a `@!group` render as one page and their individual
// methods 404, so a group contributes its own route and its children are dropped.
function routableScenarios(scenarios) {
  const leaves = [];
  const groups = [];
  for (const s of scenarios) {
    if (s.examples?.length) groups.push(s);
    else if (s.preview_path) leaves.push({ name: s.name, path: s.preview_path });
  }
  const prefix = leaves[0]
    ? leaves[0].path.slice(0, leaves[0].path.lastIndexOf('/'))
    : groups[0]?.examples?.[0]?.preview_path?.replace(/\/[^/]+$/, '');
  for (const g of groups) if (prefix) leaves.push({ name: g.name, path: `${prefix}/${g.name}` });
  return { prefix, scenarios: leaves };
}

function loadComponents() {
  const index = JSON.parse(fs.readFileSync(path.join(OUT, 'previews-index.json'), 'utf8'));
  const arch = JSON.parse(fs.readFileSync(path.join(REPO, 'static/info_arch.json'), 'utf8'));

  // info_arch is keyed by component; join it to Lookbook by the preview path
  // prefix the two share.
  const byPrefix = new Map();
  for (const rec of arch) {
    for (const p of pyLiteral(rec.previews)) {
      if (!p?.preview_path) continue;
      const prefix = p.preview_path.replace(/\/[^/]+$/, '');
      if (!byPrefix.has(prefix)) byPrefix.set(prefix, rec);
    }
  }

  const taken = new Set();
  const out = [];
  for (const entry of index) {
    const { prefix, scenarios } = routableScenarios(entry.scenarios || []);
    if (!prefix) continue;
    const rel = prefix.replace('/lookbook/preview/', '');
    const rec = byPrefix.get(rel) || {};
    if (rec.is_published === false || rec.is_published === 'False') continue;

    const fqn = rec.fully_qualified_name || rel.split('/').map(pascal).join('::');
    let name = pascal(rec.component || entry.name);
    if (!name) continue;
    if (taken.has(name)) name = groupOf(fqn) + name;
    if (taken.has(name)) continue;

    // Playground previews are argument-driven scaffolds that render the same as
    // default; they would only produce duplicate cells.
    const excluded = new Set(EXCLUDED_SCENARIOS[name] ?? []);
    const picked = scenarios.filter((s) => s.name !== 'playground' && !excluded.has(s.name));
    picked.sort((a, b) => Number(b.name === 'default') - Number(a.name === 'default'));
    if (!picked.length) continue;
    taken.add(name);

    out.push({
      name,
      fqn,
      group: groupOf(fqn),
      status: rec.status || 'unknown',
      requiresJs: String(rec.requires_js) === 'True',
      description: (rec.description || '').trim(),
      accessibility: (rec.accessibility_docs || '').trim(),
      parameters: pyLiteral(rec.parameters),
      slots: pyLiteral(rec.slots),
      source: rec.source || '',
      previews: picked.slice(0, MAX_PREVIEWS).map((s) => ({
        name: s.name,
        preview_path: s.path.replace('/lookbook/preview/', ''),
      })),
    });
  }
  return ONLY.length ? out.filter((c) => ONLY.includes(c.name)) : out;
}

// ---------------------------------------------------------------- scraping

// Lookbook's bare preview endpoint wraps the component in .preview-wrap. Take
// that element's inner HTML and drop the host page's own scripts.
function extractMarkup(html) {
  const open = html.indexOf('<div class="preview-wrap">');
  let body =
    open === -1
      ? html.slice(html.indexOf('<body>') + 6, html.lastIndexOf('</body>'))
      : html.slice(open + '<div class="preview-wrap">'.length);

  if (open !== -1) {
    // Trim the trailing closers that belong to the wrapper and the page shell.
    const idx = body.lastIndexOf('</div>');
    if (idx !== -1) body = body.slice(0, idx);
    let depth = 0;
    for (const m of body.matchAll(/<\/?div\b/g)) depth += m[0] === '</div' ? -1 : 1;
    while (depth < 0) {
      const cut = body.lastIndexOf('</div>');
      if (cut === -1) break;
      body = body.slice(0, cut);
      depth += 1;
    }
  }

  return body
    .replace(/<script\b[^>]*>[\s\S]*?<\/script>/gi, '')
    .replace(/<link\b[^>]*>/gi, '')
    .replace(/^\s+|\s+$/g, '');
}

async function scrape(previewPath) {
  const res = await fetch(`${BASE}/lookbook/preview/${previewPath}`);
  if (!res.ok) throw new Error(`${res.status} ${previewPath}`);
  return extractMarkup(await res.text());
}

// ---------------------------------------------------------------- emit

const rm = (p) => fs.rmSync(p, { recursive: true, force: true });
const mkdir = (p) => fs.mkdirSync(p, { recursive: true });

function copyTree(src, dest) {
  mkdir(dest);
  for (const e of fs.readdirSync(src, { withFileTypes: true })) {
    const s = path.join(src, e.name);
    const d = path.join(dest, e.name);
    if (e.isDirectory()) copyTree(s, d);
    else if (e.isFile()) fs.copyFileSync(s, d);
  }
}

function cssFilesUnder(dir, rel = '') {
  const out = [];
  for (const e of fs.readdirSync(path.join(dir, rel), { withFileTypes: true })) {
    const r = path.join(rel, e.name);
    if (e.isDirectory()) out.push(...cssFilesUnder(dir, r));
    else if (e.name.endsWith('.css')) out.push(r);
  }
  return out;
}

// The file list and its order mirror the demo app's own stylesheet
// (demo/app/assets/stylesheets/application.postcss.css) — that is what a Primer
// page is expected to load, and omitting @primer/css leaves text in the browser
// default serif with a slab of colour tokens undefined. Emitted flat rather than
// as @import chains: those would have to resolve again inside the uploaded
// bundle, and one broken link there ships every design unstyled.
function emitCss(distDir) {
  const cssDir = path.join(distDir, 'css');
  mkdir(cssDir);

  const primitives = [
    'base/size/size.css',
    'base/typography/typography.css',
    'functional/size/border.css',
    'functional/size/breakpoints.css',
    'functional/size/size-coarse.css',
    'functional/size/size-fine.css',
    'functional/size/size.css',
    'functional/size/viewport.css',
    'functional/typography/typography.css',
    // Only the two themes the cards select via data-light-theme/data-dark-theme;
    // the remaining seven accessibility themes would triple the stylesheet.
    'functional/themes/light.css',
    'functional/themes/dark.css',
  ];
  // marketing-buttons.css is beyond the demo's list: ButtonMarketing's default
  // scheme is styled entirely by --color-mktg-* properties that nothing else
  // defines, so without it that button renders with no background and no text
  // colour at all.
  const primerCss = ['base.css', 'buttons.css', 'layout.css', 'utilities.css', 'markdown.css', 'marketing-buttons.css'];

  const parts = [];
  const add = (label, file) => {
    if (!fs.existsSync(file)) {
      console.error(`[GEN] ! css missing: ${file}`);
      return;
    }
    parts.push(`/* ${label} */`);
    parts.push(fs.readFileSync(file, 'utf8').replace(/\/\*# sourceMappingURL=[^*]*\*\//g, ''));
  };

  add('primer_view_components.css', PRIMER_CSS);
  for (const f of primitives) add(`@primer/primitives ${f}`, path.join(PRIMITIVES, ...f.split('/')));
  for (const f of primerCss) add(`@primer/css ${f}`, path.join(REPO, 'node_modules/@primer/css/dist', f));

  const out = path.join(cssDir, 'primer-ds.css');
  fs.writeFileSync(out, `${parts.join('\n')}\n`);
  return path.relative(OUT, out).split(path.sep).join('/');
}

const cellName = (previewName) => pascal(previewName) || 'Default';

function emitAdapter(components, markup) {
  const distDir = path.join(OUT, 'dist');
  mkdir(distDir);

  const table = {};
  for (const c of components) {
    table[c.name] = {};
    for (const p of c.previews) {
      const html = markup.get(p.preview_path);
      if (html) table[c.name][p.name] = html;
    }
  }

  const js = [
    `// Generated by .design-sync/generate-adapter.mjs — do not edit.`,
    `import ${JSON.stringify(path.relative(distDir, PRIMER_JS).split(path.sep).join('/'))};`,
    `import * as React from "react";`,
    ``,
    `const MARKUP = ${JSON.stringify(table)};`,
    ``,
    // Primer's functional tokens are scoped to these attributes; without them
    // every colour resolves to nothing.
    `function make(name, fallback) {`,
    `  const variants = MARKUP[name] || {};`,
    `  const C = ({ preview, className, style }) => React.createElement("div", {`,
    `    "data-color-mode": "light",`,
    `    "data-light-theme": "light",`,
    `    "data-dark-theme": "dark",`,
    `    className,`,
    `    style,`,
    `    dangerouslySetInnerHTML: { __html: variants[preview] ?? variants[fallback] ?? "" },`,
    `  });`,
    `  C.displayName = name;`,
    `  return C;`,
    `}`,
    ``,
    ...components.map((c) => {
      const first = c.previews.find((p) => table[c.name][p.name]);
      return `export const ${c.name} = make(${JSON.stringify(c.name)}, ${JSON.stringify(first ? first.name : '')});`;
    }),
    ``,
  ].join('\n');
  fs.writeFileSync(path.join(distDir, 'index.js'), js);

  const dts = [
    `// Generated by .design-sync/generate-adapter.mjs — do not edit.`,
    `import type * as React from "react";`,
    ``,
    ...components.flatMap((c) => {
      const names = c.previews.filter((p) => table[c.name][p.name]).map((p) => JSON.stringify(p.name));
      return [
        `/**`,
        ` * ${(c.description.split('\n')[0] || c.fqn).replace(/\*\//g, '')}`,
        ` *`,
        ` * Renders Primer's own server-rendered markup for ${c.fqn}. The Ruby`,
        ` * component's arguments and slots are not props — pick a rendered variant`,
        ` * with \`preview\`, or copy the markup and write Primer classes directly.`,
        ` */`,
        `export interface ${c.name}Props {`,
        `  /** Which of Primer's rendered previews to show. */`,
        names.length ? `  preview?: ${names.join(' | ')};` : `  preview?: string;`,
        `  className?: string;`,
        `  style?: React.CSSProperties;`,
        `}`,
        `export declare const ${c.name}: React.FC<${c.name}Props>;`,
        ``,
      ];
    }),
  ].join('\n');
  fs.writeFileSync(path.join(distDir, 'index.d.ts'), dts);

  fs.writeFileSync(
    path.join(OUT, 'package.json'),
    `${JSON.stringify(
      {
        name: '@openproject/primer-view-components-ds',
        version: '0.0.0',
        private: true,
        type: 'module',
        module: './dist/index.js',
        main: './dist/index.js',
        types: './dist/index.d.ts',
        exports: { '.': { types: './dist/index.d.ts', import: './dist/index.js' } },
      },
      null,
      2,
    )}\n`,
  );

  return table;
}

function paramTable(parameters) {
  if (!parameters.length) return '_No arguments._';
  const rows = parameters.map(
    (p) =>
      `| \`${p.name}\` | ${p.type || ''} | ${p.default || ''} | ${String(p.description || '').replace(/\|/g, '\\|').replace(/\n/g, ' ')} |`,
  );
  return ['| Argument | Type | Default | Description |', '| --- | --- | --- | --- |', ...rows].join('\n');
}

function emitDocs(components, table) {
  const docsDir = path.join(OUT, 'docs');
  mkdir(docsDir);
  for (const c of components) {
    const cells = c.previews.filter((p) => table[c.name][p.name]);
    const md = [
      '---',
      `category: ${c.group}`,
      '---',
      '',
      `# ${c.name}`,
      '',
      c.description || `${c.fqn}.`,
      '',
      '## How to build with this',
      '',
      `${c.name} is a Ruby ViewComponent (\`${c.fqn}\`). This card renders Primer's own`,
      "server-rendered markup, so it accepts no content props - `children` and the Ruby",
      'arguments below are **not** available as React props.',
      '',
      'To build UI with it, copy the markup from the rendered variant you want and',
      'write Primer classes directly. The variants available here are:',
      '',
      ...cells.map((p) => `- \`preview="${p.name}"\``),
      '',
      `Status: **${c.status}**${c.requiresJs ? ' - requires the Primer custom-element JS (included in this bundle)' : ''}.`,
      '',
      '## Ruby arguments (reference)',
      '',
      'These are the arguments the Ruby component accepts. They document the design',
      'intent and the class vocabulary each variant produces; they are not React props.',
      '',
      paramTable(c.parameters),
      '',
      ...(c.slots.length
        ? ['## Slots', '', ...c.slots.map((s) => `- \`${s.name}\`${s.description ? ` - ${String(s.description).replace(/\n/g, ' ')}` : ''}`), '']
        : []),
      ...(c.accessibility && c.accessibility !== 'None' ? ['## Accessibility', '', c.accessibility, ''] : []),
      `Source: ${c.source}`,
      '',
    ].join('\n');
    fs.writeFileSync(path.join(docsDir, `${c.name}.md`), md);
  }
}

function emitPreviews(components, table) {
  mkdir(PREVIEWS_DIR);
  for (const c of components) {
    const cells = c.previews.filter((p) => table[c.name][p.name]);
    if (!cells.length) continue;
    const seen = new Set();
    const exports = [];
    for (const p of cells) {
      let cell = cellName(p.name);
      while (seen.has(cell)) cell += 'Variant';
      seen.add(cell);
      exports.push(`export const ${cell} = () => <${c.name} preview="${p.name}" />;`);
    }
    fs.writeFileSync(
      path.join(PREVIEWS_DIR, `${c.name}.tsx`),
      [
        `// Generated by .design-sync/generate-adapter.mjs — do not edit.`,
        `import { ${c.name} } from '@openproject/primer-view-components-ds';`,
        ``,
        ...exports,
        ``,
      ].join('\n'),
    );
  }
}

// ---------------------------------------------------------------- main

mkdir(OUT);
const indexRes = await fetch(`${BASE}/lookbook/previews.json`);
if (!indexRes.ok) {
  console.error(`[GEN] cannot reach Lookbook at ${BASE} (${indexRes.status}) — start it with: cd demo && bin/rails s -p 4567`);
  process.exit(1);
}
fs.writeFileSync(path.join(OUT, 'previews-index.json'), await indexRes.text());

const components = loadComponents();
if (!components.length) {
  console.error('no components matched');
  process.exit(1);
}
console.error(`[GEN] ${components.length} components, ${components.reduce((n, c) => n + c.previews.length, 0)} previews`);

const markup = new Map();
const failures = [];
let done = 0;
for (const c of components) {
  for (const p of c.previews) {
    try {
      const html = await scrape(p.preview_path);
      if (html) markup.set(p.preview_path, html);
      else failures.push(`${p.preview_path} (empty)`);
    } catch (e) {
      failures.push(`${p.preview_path} (${e.message})`);
    }
  }
  done += 1;
  if (done % 20 === 0) console.error(`[GEN] scraped ${done}/${components.length} components`);
}

rm(path.join(OUT, 'dist'));
rm(path.join(OUT, 'docs'));
mkdir(OUT);
const table = emitAdapter(components, markup);
const cssEntry = emitCss(path.join(OUT, 'dist'));
emitDocs(components, table);
emitPreviews(components, table);

const empty = components.filter((c) => !Object.keys(table[c.name]).length).map((c) => c.name);
console.error(`[GEN] cssEntry: ${cssEntry}`);
if (empty.length) console.error(`[GEN] no markup scraped for: ${empty.join(', ')}`);
if (failures.length) console.error(`[GEN] ${failures.length} preview failures:\n  ${failures.slice(0, 20).join('\n  ')}`);
console.error(`[GEN] done: ${markup.size} previews embedded`);
