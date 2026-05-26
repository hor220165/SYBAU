# SYBAU Frontend

Frontend der SYBAU Web-App.

Live URL:

```text
https://sybau-fitness.vercel.app
```

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

`vercel.json` routes Vue history URLs such as `/profile` and `/workouts` back to `index.html`.

The backend CORS allowlist accepts SYBAU Vercel preview domains ending in `.vercel.app`.
The current production domain is already configured:

```text
https://sybau-fitness.vercel.app
```
