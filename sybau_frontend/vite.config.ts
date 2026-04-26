import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'
import { networkInterfaces } from 'os'

const getLocalIP = () => {
  const nets = networkInterfaces()
  for (const name of Object.keys(nets)) {
    if (!name.toLowerCase().includes('wi-fi') &&
        !name.toLowerCase().includes('wlan') &&
        !name.toLowerCase().includes('wireless')) continue
    for (const net of nets[name]!) {
      if (net.family === 'IPv4' && !net.internal) {
        return net.address
      }
    }
  }
  return 'localhost'
}

export default defineConfig(({ mode }) => {
  const apiBase = mode === 'network'
    ? `http://${getLocalIP()}:5243/`
    : 'http://localhost:5243/'

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