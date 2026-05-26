# SYBAU Frontend

Vue 3 + TypeScript + Vite frontend for the SYBAU web app.

Live URL:

```text
https://sybau-fitness.vercel.app
```

The frontend uses optimized WebP assets and long-lived cache headers for `/assets/*` through `vercel.json`.

## Vercel

Import the repository in Vercel and set the project root directory to `sybau_frontend`.

Use these build settings:

```text
Framework Preset: Vite
Install Command: npm ci
Build Command: npm run build
Output Directory: dist
```

Set this public build variable for Production and Preview:

```bash
VITE_API_URL=https://sybau-xll5.onrender.com
```

For local development, the frontend falls back to `http://localhost:5243` when `VITE_API_URL` is not set.

`vercel.json` routes Vue history URLs such as `/profile` and `/workouts` back to `index.html`.
It also sends immutable cache headers for generated assets:

```text
Cache-Control: public, max-age=31536000, immutable
```

The backend CORS allowlist accepts SYBAU Vercel preview domains ending in `.vercel.app`.
The current production domain is already configured:

```text
https://sybau-fitness.vercel.app
```

## Local Development

```bash
npm install
npm run dev
```

Local URL:

```text
http://localhost:5173
```
