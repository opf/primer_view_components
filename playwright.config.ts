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
  // 'changed' rewrites only failing snapshots (and creates missing ones);
  // 'all' rewrote every file every run, churning bytes CI auto-committed.
  updateSnapshots: 'changed',
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
      // Diff budget: without it a single non-deterministic anti-aliased
      // pixel marks the snapshot changed.
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
