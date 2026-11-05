// eslint-disable-next-line import/no-unresolved -- the resolver does not read vitest's exports map
import {defineConfig} from 'vitest/config'

export default defineConfig({
  resolve: {
    // `npm run build` emits .js next to each .ts; tests must run the source
    extensions: ['.ts', '.mts', '.js', '.mjs', '.json'],
  },
  test: {
    environment: 'happy-dom',
    include: ['test/javascript/**/*.test.ts'],
  },
})
