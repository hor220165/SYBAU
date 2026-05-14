import { computed } from 'vue';

export function useLanguage() {
  const locale = computed(() => 'de-DE');

  const text = (de: string, _en: string) => de;
  const translate = (value: string) => value;

  const number = (value: number) => value.toLocaleString(locale.value);

  return {
    locale,
    text,
    translate,
    number,
  };
}
