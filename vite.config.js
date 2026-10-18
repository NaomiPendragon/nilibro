import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    // El proyecto vive en D: y se corre desde WSL (/mnt/d): sin polling,
    // Vite no se entera de los cambios hechos desde Windows.
    watch: { usePolling: true, interval: 300 },
  },
})
