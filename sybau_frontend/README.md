# SYBAU Frontend

Vue 3 + TypeScript + Vite frontend.

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

The backend CORS allowlist accepts SYBAU Vercel preview domains ending in `.vercel.app`.
After adding a final custom domain, add that exact origin to the backend CORS configuration too:

```text
https://your-domain.example
```
