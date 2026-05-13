# SYBAU Frontend

Vue 3 + TypeScript + Vite frontend.

## Vercel

Set this environment variable in Vercel:

```bash
VITE_API_URL=https://sybau-xll5.onrender.com
```

For local development, the frontend falls back to `http://localhost:5243` when `VITE_API_URL` is not set.

The backend CORS allowlist must include the deployed Vercel origin, for example:

```text
https://<your-vercel-project>.vercel.app
```

Add your custom production domain too if you use one.
