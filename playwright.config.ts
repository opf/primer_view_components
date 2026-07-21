// eslint-disable-next-line import/no-nodejs-modules
import path from 'node:path'
import type {PlaywrightTestConfig} from '@playwright/test'

/**
 * See https://playwright.dev/docs/test-configuration.
 */
const config: PlaywrightTestConfig = {
  testDir: path.join(__dirname, 'test', 'playwright'),
  testMatch: '**/*.test.ts',
  /* Maximum time one test can run for. */
  timeout: 10 * 1000,

  // https://playwright.dev/docs/api/class-testconfig#test-config-output-dir
  outputDir: path.join(__dirname, '.playwright', 'results'),
  snapshotDir: path.join(__dirname, '.playwright', 'screenshots'),

  /* Run tests in files in parallel */
  fullyParallel: true,
  workers: process.env.CI ? 4 : undefined,
  // Assert against the committed baseline. 'none' means a missing baseline
  // fails rather than being silently created, so new snapshots must be added
  // via the regen path (the `regen-snapshots` PR label in test-visual.yml,
  // which passes --update-snapshots and overrides this). Never rewrite
  // unconditionally — 'all' rewrote every file every run and committed
  // byte-churn.
  updateSnapshots: 'none',
  use: {
    baseURL: 'http://127.0.0.1:4000',
    browserName: 'chromium',
    headless: true,
    screenshot: 'only-on-failure',
  },
  expect: {
    toHaveScreenshot: {
      animations: 'disabled',
    },
    toMatchSnapshot: {
      // `threshold` sets per-pixel colour sensitivity; `maxDiffPixelRatio` sets
      // how many pixels may differ before failing. Without a max-diff budget a
      // single anti-aliased pixel of non-deterministic Chromium rasterisation
      // fails the run. Tune if genuine small changes slip through.
      threshold: 0.1,
      maxDiffPixelRatio: 0.01,
    },
  },
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,

  reporter: [
    ['line'],
    ['html', {open: 'never', outputFolder: path.join(__dirname, '.playwright/report')}],
    ['json', {outputFile: path.join(__dirname, '.playwright', 'results.json')}],
  ],

  webServer: {
    command: 'script/dev',
    port: 4000,
  },
}

export default config
