import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { writeFileSync, readdirSync, statSync } from 'fs'
import { resolve } from 'path'

function assetManifestPlugin() {
  return {
    name: 'asset-manifest',
    apply: 'build' as const,
    closeBundle() {
      const manifest: { files: Record<string, string>; entrypoints: string[] } = {
        files: {},
        entrypoints: [],
      }
      const outputDir = resolve(__dirname, 'dist')
      function walk(dir: string, base: string) {
        for (const entry of readdirSync(dir)) {
          const full = resolve(dir, entry)
          const rel = base ? `${base}/${entry}` : entry
          if (statSync(full).isDirectory()) {
            walk(full, rel)
          } else {
            manifest.files[rel] = `./${rel}`
            if (rel.endsWith('.js') && !rel.endsWith('.map')) {
              manifest.entrypoints.push(rel)
            }
          }
        }
      }
      walk(outputDir, '')
      writeFileSync(resolve(outputDir, 'asset-manifest.json'), JSON.stringify(manifest, null, 2))
    },
  }
}

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), assetManifestPlugin()],
  base: './',
  server: {
    proxy: {
    },
  },
})

