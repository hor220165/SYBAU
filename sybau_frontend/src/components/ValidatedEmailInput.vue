<script setup lang="ts">
import { computed, ref } from 'vue';
import { normalizeEmail, validateEmail } from '@/utils/authValidation';

const props = withDefaults(defineProps<{
  modelValue: string;
  label?: string;
  placeholder?: string;
  autocomplete?: string;
  required?: boolean;
  blockDisposable?: boolean;
}>(), {
  label: 'E-Mail',
  placeholder: 'example@gmail.com',
  autocomplete: 'email',
  required: true,
  blockDisposable: true,
});

const emit = defineEmits<{
  'update:modelValue': [value: string];
}>();

const touched = ref(false);

const error = computed(() => {
  if (!touched.value) return '';
  return validateEmail(props.modelValue, {
    required: props.required,
    blockDisposable: props.blockDisposable,
  });
});

function updateValue(event: Event) {
  emit('update:modelValue', (event.target as HTMLInputElement).value);
}

function markTouched() {
  touched.value = true;
}

function validate() {
  touched.value = true;
  return !validateEmail(props.modelValue, {
    required: props.required,
    blockDisposable: props.blockDisposable,
  });
}

function normalizedValue() {
  return normalizeEmail(props.modelValue);
}

defineExpose({ validate, normalizedValue });
</script>

<template>
  <div class="validated-field">
    <label>{{ label }}</label>
    <input
      :value="modelValue"
      type="email"
      :placeholder="placeholder"
      :autocomplete="autocomplete"
      :required="required"
      :aria-invalid="Boolean(error)"
      @input="updateValue"
      @blur="markTouched"
    />
    <p v-if="error" class="field-error">{{ error }}</p>
  </div>
</template>

<style scoped>
.validated-field {
  display: flex;
  flex-direction: column;
}

.validated-field label {
  margin-top: 16px;
  color: #a0aec0;
  font-size: 0.9rem;
}

.validated-field input {
  margin-top: 6px;
  padding: 14px;
  border: none;
  border-radius: 12px;
  background: rgba(18, 22, 40, 0.7);
  color: white;
  transition: all 0.3s ease;
}

.validated-field input:focus {
  outline: none;
  background: rgba(18, 22, 40, 0.9);
  box-shadow: 0 0 0 2px rgba(255, 45, 117, 0.3);
}

.validated-field input[aria-invalid='true'] {
  box-shadow: 0 0 0 2px rgba(248, 113, 113, 0.36);
}

.validated-field input::placeholder {
  color: #6b7280;
}

.field-error {
  margin: 7px 0 0;
  color: #fb7185;
  font-size: 0.82rem;
  line-height: 1.35;
}
</style>
