<template>
  <div v-if="isOpen" class="workout-modal-overlay" @click.self="$emit('close')">
    <div class="workout-modal">
      <!-- Header -->
      <div class="modal-header">
        <div class="workout-info">
          <div class="workout-icon">{{ icon }}</div>
          <h2 class="workout-title">{{ exerciseName }}</h2>
        </div>
        <button class="close-btn" @click="$emit('close')">Zurück</button>
      </div>

      <!-- Counter -->
      <div class="counter-section">
        <div class="counter-label">Wiederholungen</div>
        <div class="counter-controls">
          <button class="counter-btn" @click="decreaseCount(10)">-10</button>
          <button class="counter-btn small" @click="decreaseCount(1)">-</button>
          <div class="counter-display">{{ count }}</div>
          <button class="counter-btn small" @click="increaseCount(1)">+</button>
          <button class="counter-btn" @click="increaseCount(10)">+10</button>
        </div>
        <div class="counter-info">
          <span>Noch {{ remaining }} heute möglich</span>
          <span>Heute: {{ todayCount }} / {{ dailyLimit }}</span>
        </div>
      </div>

      <!-- XP Preview -->
      <div class="xp-preview">
        <span>XP-Gewinn</span>
        <div class="xp-amount">
          <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/>
          </svg>
          +{{ xpGain }}
        </div>
      </div>

      <!-- Actions -->
      <div class="modal-actions">
        <button class="action-btn secondary" @click="$emit('close')">
          Abbrechen
        </button>
        <button class="action-btn primary" @click="handleSubmit">
          Eintragen
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';

const props = defineProps<{
  isOpen: boolean;
  exerciseName: string;
  icon: string;
  xpPerRep: number;
  dailyLimit: number;
  todayCount: number;
}>();

const emit = defineEmits<{
  close: [];
  submit: [data: { exercise: string; reps: number; xp: number }];
}>();

const count = ref(0);

const remaining = computed(() => Math.max(0, props.dailyLimit - props.todayCount));
const xpGain = computed(() => Math.round(count.value * props.xpPerRep));

const increaseCount = (amount: number) => {
  const newCount = count.value + amount;
  if (newCount <= remaining.value) {
    count.value = newCount;
  } else {
    count.value = remaining.value;
  }
};

const decreaseCount = (amount: number) => {
  count.value = Math.max(0, count.value - amount);
};

const handleSubmit = () => {
  if (count.value > 0) {
    emit('submit', {
      exercise: props.exerciseName,
      reps: count.value,
      xp: xpGain.value
    });
    count.value = 0;
    emit('close');
  }
};

// Reset count when modal opens
watch(() => props.isOpen, (isOpen) => {
  if (isOpen) {
    count.value = 0;
  }
});
</script>

<style scoped>
.workout-modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.7);
  backdrop-filter: blur(8px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
}

.workout-modal {
  background: rgba(15, 23, 42, 0.95);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 24px;
  width: 100%;
  max-width: 480px;
  padding: 32px;
}

/* Header */
.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 32px;
}

.workout-info {
  display: flex;
  align-items: center;
  gap: 16px;
}

.workout-icon {
  font-size: 32px;
}

.workout-title {
  font-size: 24px;
  font-weight: 700;
  color: white;
  margin: 0;
}

.close-btn {
  padding: 0px;
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.6);
  font-weight: 500;
  font-size: 14px;
  cursor: pointer;
  transition: all 0.3s ease;
  border-radius: 8px;
  white-space: nowrap;
}


.close-btn:hover {
  color: #ec4899;
  transform: translateX(-4px);
}

/* Counter */
.counter-section {
  margin-bottom: 24px;
}

.counter-label {
  font-size: 13px;
  font-weight: 500;
  color: rgba(255, 255, 255, 0.5);
  text-transform: uppercase;
  letter-spacing: 0.5px;
  margin-bottom: 16px;
}

.counter-controls {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  margin-bottom: 16px;
}

.counter-btn {
  width: 56px;
  height: 48px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(255, 255, 255, 0.05);
  color: white;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.counter-btn.small {
  width: 48px;
}

.counter-btn:hover {
  background: rgba(255, 255, 255, 0.1);
  border-color: rgba(255, 255, 255, 0.2);
}

.counter-display {
  min-width: 100px;
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 40px;
  font-weight: 700;
  color: white;
  border-radius: 16px;
  background: linear-gradient(135deg, rgba(236, 72, 153, 0.1), rgba(244, 63, 94, 0.1));
  border: 2px solid rgba(236, 72, 153, 0.3);
}

.counter-info {
  display: flex;
  justify-content: space-between;
  font-size: 13px;
  color: rgba(255, 255, 255, 0.5);
}

/* XP Preview */
.xp-preview {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  background: rgba(236, 72, 153, 0.1);
  border: 1px solid rgba(236, 72, 153, 0.2);
  border-radius: 12px;
  margin-bottom: 24px;
}

.xp-preview span {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.7);
}

.xp-amount {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 24px;
  font-weight: 700;
  color: #fbbf24;
}

.xp-amount svg {
  color: #fbbf24;
}

/* Actions */
.modal-actions {
  display: flex;
  gap: 12px;
}

.action-btn {
  flex: 1;
  height: 48px;
  border-radius: 12px;
  border: none;
  font-size: 15px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.action-btn.secondary {
  background: rgba(255, 255, 255, 0.05);
  color: rgba(255, 255, 255, 0.7);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.action-btn.secondary:hover {
  background: rgba(255, 255, 255, 0.1);
  color: white;
}

.action-btn.primary {
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  color: white;
  box-shadow: 0 4px 12px rgba(236, 72, 153, 0.3);
}

.action-btn.primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(236, 72, 153, 0.4);
}

.action-btn.primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
}

/* Responsive */
@media (max-width: 768px) {
  .workout-modal {
    padding: 24px;
  }

  .counter-display {
    min-width: 80px;
    height: 56px;
    font-size: 32px;
  }

  .counter-btn {
    width: 48px;
    height: 44px;
  }

  .counter-btn.small {
    width: 40px;
  }
}
</style>