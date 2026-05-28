import { readonly, ref } from 'vue';

export type ThemeMode = 'dark' | 'light';

const STORAGE_KEY = 'sybau-theme';
const theme = ref<ThemeMode>('dark');
let initialized = false;

function isThemeMode(value: string | null): value is ThemeMode {
  return value === 'dark' || value === 'light';
}

function applyTheme(mode: ThemeMode) {
  if (typeof document === 'undefined') return;

  const root = document.documentElement;
  root.dataset.theme = mode;
  root.style.colorScheme = mode;

  const themeColor = document.querySelector<HTMLMetaElement>('meta[name="theme-color"]');
  if (themeColor) {
    themeColor.content = mode === 'light' ? '#f8fafc' : '#0f0c29';
  }
}

export function initializeTheme() {
  if (initialized) return;
  initialized = true;

  if (typeof window !== 'undefined') {
    const storedTheme = window.localStorage.getItem(STORAGE_KEY);
    theme.value = isThemeMode(storedTheme) ? storedTheme : 'dark';
  }

  applyTheme(theme.value);
}

export function setTheme(mode: ThemeMode) {
  theme.value = mode;

  if (typeof window !== 'undefined') {
    window.localStorage.setItem(STORAGE_KEY, mode);
  }

  applyTheme(mode);
}

export function useTheme() {
  initializeTheme();

  return {
    theme: readonly(theme),
    setTheme,
  };
}
