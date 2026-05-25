<script setup lang="ts">
import { computed, ref } from 'vue';
import { Eye, EyeOff } from 'lucide-vue-next';
import { getPasswordRequirementStates, validatePassword } from '@/utils/authValidation';

const props = withDefaults(defineProps<{
  modelValue: string;
  label?: string;
  placeholder?: string;
  autocomplete?: string;
  required?: boolean;
  requireStrength?: boolean;
  showRequirements?: boolean;
}>(), {
  label: 'Passwort',
  placeholder: '••••••••',
  autocomplete: 'current-password',
  required: true,
  requireStrength: false,
  showRequirements: false,
});

const emit = defineEmits<{
  'update:modelValue': [value: string];
}>();

const touched = ref(false);
const showPassword = ref(false);

const requirements = computed(() => getPasswordRequirementStates(props.modelValue));
const error = computed(() => {
  if (!touched.value) return '';
  return validatePassword(props.modelValue, {
    required: props.required,
    requireStrength: props.requireStrength,
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
  return !validatePassword(props.modelValue, {
    required: props.required,
    requireStrength: props.requireStrength,
  });
}

defineExpose({ validate });
</script>

<template>
  <div class="validated-field">
    <label>{{ label }}</label>
    <div class="password-input-wrapper">
      <input
        :value="modelValue"
        :type="showPassword ? 'text' : 'password'"
        :placeholder="placeholder"
        :autocomplete="autocomplete"
        :required="required"
        :aria-invalid="Boolean(error)"
        @input="updateValue"
        @blur="markTouched"
      />
      <button
        type="button"
        class="toggle-password"
        :aria-label="showPassword ? 'Passwort ausblenden' : 'Passwort anzeigen'"
        :data-tooltip="showPassword ? 'Passwort ausblenden' : 'Passwort anzeigen'"
        @click="showPassword = !showPassword"
      >
        <EyeOff v-if="showPassword" :size="20" />
        <Eye v-else :size="20" />
      </button>
    </div>

    <ul v-if="showRequirements" class="password-rules" aria-label="Passwort-Anforderungen">
      <li v-for="requirement in requirements" :key="requirement.key" :class="{ valid: requirement.valid }">
        <span aria-hidden="true">{{ requirement.valid ? '✓' : '•' }}</span>
        {{ requirement.label }}
      </li>
    </ul>

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

.password-input-wrapper {
  position: relative;
  margin-top: 6px;
}

.password-input-wrapper input {
  width: 100%;
  margin-top: 0;
  padding: 14px 45px 14px 14px;
  border: none;
  border-radius: 12px;
  background: rgba(18, 22, 40, 0.7);
  color: white;
  transition: all 0.3s ease;
}

.password-input-wrapper input:focus {
  outline: none;
  background: rgba(18, 22, 40, 0.9);
  box-shadow: 0 0 0 2px rgba(255, 45, 117, 0.3);
}

.password-input-wrapper input[aria-invalid='true'] {
  box-shadow: 0 0 0 2px rgba(248, 113, 113, 0.36);
}

.password-input-wrapper input::placeholder {
  color: #6b7280;
}

.toggle-password {
  position: absolute;
  top: 50%;
  right: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  padding: 4px;
  transform: translateY(-50%);
  border: 0;
  background: transparent;
  color: rgba(255, 255, 255, 0.55);
  cursor: pointer;
  transition: all 0.3s ease;
}

.toggle-password:hover {
  color: #ff2d75;
}

.password-rules {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 6px 12px;
  margin: 10px 0 0;
  padding: 0;
  list-style: none;
}

.password-rules li {
  display: flex;
  align-items: center;
  gap: 6px;
  color: #94a3b8;
  font-size: 0.78rem;
  line-height: 1.35;
}

.password-rules li.valid {
  color: #86efac;
}

.password-rules span {
  width: 12px;
  color: currentColor;
  font-weight: 800;
}

.field-error {
  margin: 7px 0 0;
  color: #fb7185;
  font-size: 0.82rem;
  line-height: 1.35;
}

@media (max-width: 520px) {
  .password-rules {
    grid-template-columns: 1fr;
  }
}
</style>
