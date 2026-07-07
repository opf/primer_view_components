import resolve from "@rollup/plugin-node-resolve"
import typescript from "@rollup/plugin-typescript"
import { terser } from "rollup-plugin-terser"
import pkg from "./package.json"

export default {
  input: pkg.module,
  output: {
    file: pkg.main,
    format: "iife",
    sourcemap: true
  },
  plugins: [
    resolve(),
    // Declarations are emitted by the separate `tsc` step (see script/build-assets),
    // so disable them here. Avoids @rollup/plugin-typescript v12 requiring
    // declarationDir to sit alongside the bundle output.
    typescript({declaration: false, declarationDir: undefined}),
    terser({keep_classnames: /Element$/}) // comment out terser in dev if you want debugger statements
  ],
  onwarn: (warning, warn) => {
    if (warning.code === "THIS_IS_UNDEFINED") return
    warn(warning)
  }
}
