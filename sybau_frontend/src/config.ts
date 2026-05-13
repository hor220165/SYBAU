const localApiUrl = 'http://localhost:5243';

export const API_BASE_URL = String(import.meta.env.VITE_API_URL || localApiUrl).replace(/\/+$/, '');

export function resolveApiUrl(path: string) {
  if (/^(https?:|data:|blob:)/i.test(path)) return path;
  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  return `${API_BASE_URL}${normalizedPath}`;
}
