const localApiUrl = 'http://localhost:5243';
const liveApiUrl = 'https://sybau-xll5.onrender.com';

function getDefaultApiUrl() {
  if (typeof window === 'undefined') return liveApiUrl;

  const { protocol, hostname } = window.location;
  const isLoopback = hostname === 'localhost' || hostname === '127.0.0.1';
  if (isLoopback) return localApiUrl;

  const isPrivateLan =
    /^10\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(hostname) ||
    /^192\.168\.\d{1,3}\.\d{1,3}$/.test(hostname) ||
    /^172\.(1[6-9]|2\d|3[0-1])\.\d{1,3}\.\d{1,3}$/.test(hostname);

  if (isPrivateLan) {
    return `${protocol}//${hostname}:5243`;
  }

  return liveApiUrl;
}

export const API_BASE_URL = String(import.meta.env.VITE_API_URL || getDefaultApiUrl()).replace(/\/+$/, '');

export function resolveApiUrl(path: string) {
  if (/^(https?:|data:|blob:)/i.test(path)) return path;
  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  return `${API_BASE_URL}${normalizedPath}`;
}
