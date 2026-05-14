import { computed, ref, watch } from 'vue';

export type AppLanguage = 'de' | 'en';

const STORAGE_KEY = 'sybau.language';

const getInitialLanguage = (): AppLanguage => {
  const saved = localStorage.getItem(STORAGE_KEY);
  if (saved === 'de' || saved === 'en') return saved;
  return navigator.language.toLowerCase().startsWith('en') ? 'en' : 'de';
};

const language = ref<AppLanguage>(getInitialLanguage());

const languageOptions: Array<{ code: AppLanguage; label: string; flag: string }> = [
  { code: 'de', label: 'Deutsch', flag: '🇩🇪' },
  { code: 'en', label: 'English', flag: '🇬🇧' },
];

watch(
  language,
  (value) => {
    localStorage.setItem(STORAGE_KEY, value);
    document.documentElement.lang = value;
  },
  { immediate: true }
);

export function useLanguage() {
  const isEnglish = computed(() => language.value === 'en');

  const setLanguage = (nextLanguage: AppLanguage) => {
    language.value = nextLanguage;
  };

  const text = (de: string, en: string) => (language.value === 'en' ? en : de);

  return {
    language,
    languageOptions,
    isEnglish,
    setLanguage,
    text,
  };
}
