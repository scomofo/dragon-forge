import { configDefaults, defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  base: '/dragon-forge/',
  test: {
    environment: 'node',
    exclude: [
      ...configDefaults.exclude,
      '.claude/**',
      'dist/**',
      'dragon-forge-reborn/**',
      'dragon-forge-godot/**',
    ],
  },
});
