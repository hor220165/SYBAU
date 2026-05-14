<template>
  <div class="language-switch" :class="{ compact, labelled: showLabels }" role="group" aria-label="Language">
    <button
      v-for="option in languageOptions"
      :key="option.code"
      class="language-option"
      :class="{ active: language === option.code }"
      type="button"
      :aria-label="option.label"
      :aria-pressed="language === option.code"
      @click="setLanguage(option.code)"
    >
      <span class="language-flag" aria-hidden="true">{{ option.flag }}</span>
      <span v-if="showLabels" class="language-label">{{ option.label }}</span>
    </button>
  </div>
</template>

<script setup lang="ts">
import { useLanguage } from '@/composables/useLanguage';

withDefaults(
  defineProps<{
    compact?: boolean;
    showLabels?: boolean;
  }>(),
  {
    compact: false,
    showLabels: false,
  }
);

const { language, languageOptions, setLanguage } = useLanguage();
</script>

<style scoped>
.language-switch {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 5px;
  border-radius: 14px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(15, 23, 42, 0.48);
}

.language-option {
  width: 38px;
  height: 34px;
  border: 0;
  border-radius: 10px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 0;
  background: transparent;
  color: white;
  cursor: pointer;
  transition: background 0.18s ease, transform 0.18s ease, box-shadow 0.18s ease;
}

.language-option:hover {
  background: rgba(255, 255, 255, 0.08);
}

.language-option.active {
  background: rgba(236, 72, 153, 0.2);
  box-shadow: inset 0 0 0 1px rgba(236, 72, 153, 0.34);
}

.language-flag {
  font-size: 20px;
  line-height: 1;
}

.labelled {
  width: 100%;
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 8px;
}

.labelled .language-option {
  width: 100%;
  height: 42px;
  padding: 0 12px;
  justify-content: center;
}

.language-label {
  font-size: 13px;
  font-weight: 750;
}

.compact {
  padding: 4px;
  border-radius: 12px;
}

.compact .language-option {
  width: 34px;
  height: 30px;
  border-radius: 9px;
}

.compact .language-flag {
  font-size: 18px;
}
</style>
