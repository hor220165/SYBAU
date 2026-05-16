# SYBAU Frontend

Vue 3 + TypeScript + Vite frontend.

## Netlify

The repository root contains `netlify.toml`, which tells Netlify to build this app from
`sybau_frontend`, publish `dist`, and route Vue history URLs back to `index.html`.

Netlify uses this public build variable:

```bash
VITE_API_URL=https://sybau-xll5.onrender.com
```

For local development, the frontend falls back to `http://localhost:5243` when `VITE_API_URL` is not set.

The backend CORS allowlist must include the deployed Netlify origin:

```text
https://sybau-fitness.netlify.app
```

Add your custom production domain too if you use one.
