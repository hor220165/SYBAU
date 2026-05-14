<template>
  <div class="workout-card" :class="{ 'is-editing': editorOpen, completed }">
    <!-- Category Badge mit dynamischer Farbe -->
    <div class="category-badge" :class="`category-${category.toLowerCase()}`">
      {{ translate(category) }}
    </div>
    
    <!-- Title -->
    <h3 class="workout-title">{{ translate(title) }}</h3>
    
    <!-- Description -->
    <p class="workout-description">{{ translate(exercises[0] ?? '') }}</p>
    
    <!-- Bottom Row -->
    <div class="workout-meta">
      <span class="difficulty" :class="`difficulty-${difficulty.toLowerCase()}`">
        {{ translate(difficulty) }}
      </span>
      <span class="unit-badge" :class="`unit-${unitLabel.toLowerCase()}`">
        {{ unitLabel }}
      </span>
      <span class="xp">
        <img src="../assets/XP_Pixel.png" alt="" />
        +{{ xp }} XP / {{ unitSingular }}
      </span>
    </div>
    
    <button v-if="editorOpen" class="inline-close-btn" @click.stop="$emit('closeEditor')" :aria-label="text('Schließen', 'Close')">
      &times;
    </button>

    <div v-if="completed || remaining <= 0" class="limit-reached">
      {{ text('Tageslimit erreicht', 'Daily limit reached') }}
    </div>
    <button v-else-if="usesTimer" class="log-btn" @click.stop="$emit('submitLog')">
      {{ text('Eintragen', 'Log') }}
    </button>
    <button v-else-if="!editorOpen" class="log-btn" @click.stop="$emit('openEditor')">
      {{ text('Training eintragen', 'Log training') }}
    </button>
    <div v-else class="inline-log-panel" @click.stop>
      <div v-if="unit === 'Reps'" class="rep-stepper">
        <button type="button" @click="$emit('changeDraft', -1)" :aria-label="text('Weniger Reps', 'Fewer reps')">−</button>
        <label class="rep-value-label">
          <input
            :value="draftReps"
            type="number"
            min="1"
            :max="remaining"
            inputmode="numeric"
            @input="$emit('setReps', Number(($event.target as HTMLInputElement).value))"
          />
          <span>{{ text('Reps', 'Reps') }}</span>
        </label>
        <button type="button" @click="$emit('changeDraft', 1)" :aria-label="text('Mehr Reps', 'More reps')">+</button>
      </div>
      <input
        v-else-if="unit === 'Time'"
        class="amount-input"
        :value="draftTime"
        inputmode="numeric"
        maxlength="8"
        placeholder="00:00:00"
        :aria-label="text('Zeit im Format 00:00:00', 'Time in 00:00:00 format')"
        @input="$emit('setTime', ($event.target as HTMLInputElement).value)"
      />
      <div v-else class="distance-entry">
        <input
          class="amount-input"
          :value="draftDistance"
          type="number"
          min="0"
          step="0.01"
          :placeholder="text('Distanz', 'Distance')"
          @input="$emit('setDistance', Number(($event.target as HTMLInputElement).value))"
        />
        <select :value="distanceUnit" @change="$emit('setDistanceUnit', ($event.target as HTMLSelectElement).value as 'm' | 'km')">
          <option value="m">m</option>
          <option value="km">km</option>
        </select>
      </div>
      <button class="submit-log-btn" type="button" :disabled="!canSubmit" @click="$emit('submitLog')">
        {{ text('Eintragen', 'Log') }}
      </button>
      <p class="remaining-hint">{{ text('Noch', 'Still') }} {{ remainingLabel }} {{ text('möglich heute', 'possible today') }}</p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';
import { useLanguage } from '@/composables/useLanguage';

const { text, translate, locale } = useLanguage();

const props = withDefaults(defineProps<{
  category: string;
  title: string;
  exercises: string[];
  difficulty: 'Easy' | 'Medium' | 'Hard';
  xp: number;
  unit?: 'Reps' | 'Time' | 'Distance';
  completed?: boolean;
  editorOpen?: boolean;
  draftReps?: number;
  draftTime?: string;
  draftDistance?: number;
  distanceUnit?: 'm' | 'km';
  remaining?: number;
  duration?: number;
  calories?: number;
}>(), {
  unit: 'Reps',
  completed: false,
  editorOpen: false,
  draftReps: 0,
  draftTime: '00:00:10',
  draftDistance: 100,
  distanceUnit: 'm',
  remaining: 0,
});

const formatTime = (seconds: number) => {
  const safe = Math.max(0, Math.floor(seconds));
  const hours = Math.floor(safe / 3600);
  const minutes = Math.floor((safe % 3600) / 60);
  const secs = safe % 60;
  return [hours, minutes, secs].map((part) => String(part).padStart(2, '0')).join(':');
};

const unitLabel = computed(() => {
  if (props.unit === 'Time') return 'Time';
  if (props.unit === 'Distance') return 'Distance';
  return 'Reps';
});

const unitSingular = computed(() => {
  if (props.unit === 'Time') return text('Sek', 'sec');
  if (props.unit === 'Distance') return 'm';
  return 'Rep';
});

const usesTimer = computed(() => props.unit !== 'Distance');

const remainingLabel = computed(() => {
  if (props.unit === 'Time') return formatTime(props.remaining);
  if (props.unit === 'Distance') {
    return props.remaining >= 1000
      ? `${(props.remaining / 1000).toLocaleString(locale.value, { maximumFractionDigits: 2 })} km`
      : `${props.remaining.toLocaleString(locale.value)} m`;
  }
  return `${props.remaining.toLocaleString(locale.value)} ${text('Wiederholungen', 'reps')}`;
});

const canSubmit = computed(() => {
  if (props.unit === 'Time') {
    return props.draftTime && props.draftTime !== '00:00:00';
  }
  if (props.unit === 'Distance') {
    return props.draftDistance > 0;
  }
  return props.draftReps > 0;
});

defineEmits<{
  openEditor: [];
  closeEditor: [];
  changeDraft: [delta: number];
  setReps: [value: number];
  setTime: [value: string];
  setDistance: [value: number];
  setDistanceUnit: [value: 'm' | 'km'];
  submitLog: [];
}>();
</script>

<style scoped>
.workout-card {
  position: relative;
  background: rgba(30, 41, 59, 0.6);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 20px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  cursor: pointer;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
}

.workout-card.is-editing {
  border-color: rgba(236, 72, 153, 0.32);
  background: rgba(30, 41, 59, 0.7);
}

.workout-card.completed {
  cursor: default;
}

.workout-card:hover {
  border-color: rgba(236, 72, 153, 0.3);
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
}

.workout-card.completed:hover {
  transform: none;
  box-shadow: none;
}

/* Category Badge */
.category-badge {
  display: inline-block;
  padding: 6px 14px;
  border-radius: 30px;
  font-size: 13px;
  font-weight: 600;
  width: fit-content;
  text-transform: capitalize;
}

/* Category Farben */
.category-cardio {
  background: rgba(239, 68, 68, 0.2);
  border: 1px solid rgba(239, 68, 68, 0.4);
  color: #fca5a5;
}

.category-strength {
  background: rgba(168, 85, 247, 0.2);
  border: 1px solid rgba(168, 85, 247, 0.4);
  color: #c4b5fd;
}

.category-core {
  background: rgba(236, 72, 153, 0.2);
  border: 1px solid rgba(236, 72, 153, 0.4);
  color: #f9a8d4;
}

.category-flexibility {
  background: rgba(34, 197, 94, 0.2);
  border: 1px solid rgba(34, 197, 94, 0.4);
  color: #86efac;
}

/* Title */
.workout-title {
  font-size: 24px;
  font-weight: 700;
  color: white;
  margin: 0;
}

/* Description */
.workout-description {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.6);
  margin: 0;
  line-height: 1.5;
}

/* Meta Row */
.workout-meta {
  display: flex;
  align-items: center;
  gap: 16px;
  padding-top: 8px;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
}

/* Difficulty - MIT SCHATTEN statt Box */
.difficulty {
  font-size: 14px;
  font-weight: 700;
}

/* Difficulty Farben mit Schatten */
.difficulty-easy {
  color: #86efac;
  text-shadow: 0 0 12px rgba(34, 197, 94, 0.8);
}

.difficulty-medium {
  color: #fde047;
  text-shadow: 0 0 12px rgba(251, 191, 36, 0.8);
}

.difficulty-hard {
  color: #fca5a5;
  text-shadow: 0 0 12px rgba(239, 68, 68, 0.8);
}

/* XP */
.unit-badge {
  display: inline-block;
  padding: 2px 10px;
  border-radius: 30px;
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.unit-reps {
  background: rgba(59, 130, 246, 0.18);
  border: 1px solid rgba(59, 130, 246, 0.35);
  color: #93c5fd;
}

.unit-time {
  background: rgba(234, 179, 8, 0.18);
  border: 1px solid rgba(234, 179, 8, 0.35);
  color: #fde047;
}

.unit-distance {
  background: rgba(34, 197, 94, 0.18);
  border: 1px solid rgba(34, 197, 94, 0.35);
  color: #86efac;
}

.xp {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.7);
}

.xp img {
  width: 16px;
  height: 16px;
  object-fit: contain;
}

/* Button */
.log-btn {
  margin-top: 8px;
  padding: 14px;
  border-radius: 12px;
  border: none;
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  color: white;
  font-weight: 600;
  font-size: 15px;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 4px 12px rgba(236, 72, 153, 0.3);
}

.log-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(236, 72, 153, 0.4);
}

.log-btn:active {
  transform: translateY(0);
}

.inline-close-btn {
  position: absolute;
  top: 18px;
  right: 18px;
  width: 28px;
  height: 28px;
  border: 0;
  background: transparent;
  color: rgba(255, 255, 255, 0.8);
  font-size: 26px;
  line-height: 1;
  cursor: pointer;
  padding: 0;
}

.inline-close-btn:hover {
  color: white;
}

.limit-reached {
  margin-top: 8px;
  padding: 14px;
  border-radius: 12px;
  text-align: center;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: rgba(255, 255, 255, 0.7);
  font-weight: 700;
}

.inline-log-panel {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 132px;
  gap: 10px;
  margin-top: 8px;
}

.rep-stepper {
  height: 46px;
  display: grid;
  grid-template-columns: 44px minmax(0, 1fr) 44px;
  align-items: center;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.12);
  overflow: hidden;
}

.rep-stepper button {
  width: 44px;
  height: 46px;
  border: 0;
  background: transparent;
  color: white;
  font-size: 26px;
  font-weight: 800;
  cursor: pointer;
  display: grid;
  place-items: center;
  line-height: 1;
  padding: 0 0 2px;
  font-family: inherit;
}

.rep-stepper button:hover {
  background: rgba(255, 255, 255, 0.08);
}

.rep-value-label {
  display: grid;
  grid-template-columns: minmax(42px, max-content) auto;
  justify-content: center;
  align-items: center;
  gap: 6px;
  height: 46px;
  color: white;
  text-align: center;
  font-size: 15px;
  font-weight: 800;
  line-height: 1;
}

.rep-value-label input {
  width: clamp(42px, 5vw, 74px);
  border: 0;
  outline: 0;
  background: transparent;
  color: white;
  font: inherit;
  text-align: center;
  padding: 0;
  appearance: textfield;
}

.rep-value-label input::-webkit-outer-spin-button,
.rep-value-label input::-webkit-inner-spin-button {
  appearance: none;
  margin: 0;
}

.rep-value-label span {
  color: rgba(255, 255, 255, 0.86);
}

.amount-input,
.distance-entry select {
  min-height: 46px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: rgba(255, 255, 255, 0.05);
  color: white;
  font: inherit;
  font-weight: 800;
  text-align: center;
  font-variant-numeric: tabular-nums;
}

.amount-input {
  width: 100%;
  padding: 0 14px;
  font-size: 16px;
}

.distance-entry {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 84px;
  gap: 8px;
}

.distance-entry select {
  padding: 0 10px;
  font-size: 15px;
}

.submit-log-btn {
  height: 46px;
  border: 0;
  border-radius: 12px;
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  color: white;
  font-size: 15px;
  font-weight: 800;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(236, 72, 153, 0.3);
}

.submit-log-btn:disabled {
  cursor: not-allowed;
  opacity: 0.55;
  box-shadow: none;
}

.remaining-hint {
  grid-column: 1 / -1;
  margin: -2px 0 0;
  color: rgba(255, 255, 255, 0.6);
  font-size: 13px;
}

/* Responsive */
@media (max-width: 768px) {
  .workout-card {
    padding: 20px;
  }

  .workout-title {
    font-size: 20px;
  }

  .inline-log-panel {
    grid-template-columns: 1fr;
  }
}
</style>
