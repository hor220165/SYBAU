import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'

const liveApiBase = 'https://sybau-xll5.onrender.com'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const configuredApiBase = (
    process.env.VITE_API_BASE_URL ||
    (mode === 'production' ? '' : env.VITE_API_BASE_URL)
  )?.trim()
  const apiBase = configuredApiBase || liveApiBase

  return {
    plugins: [vue()],
    resolve: {
      alias: {
        '@': path.resolve(__dirname, 'src')
      }
    },
    define: {
      'import.meta.env.VITE_API_BASE_URL': JSON.stringify(apiBase)
    },
    server: {
      host: mode === 'network'
    }
  }
})
