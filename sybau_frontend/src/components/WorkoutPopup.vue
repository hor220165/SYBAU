<template>
  <Teleport to="body">
    <Transition name="modal">
      <div v-if="isOpen" class="modal-overlay" @click="closeModal">
        <div class="modal-container" @click.stop>
          <!-- Header -->
          <div class="modal-header">
            <div class="header-content">
              <span class="exercise-icon-large">{{ icon }}</span>
              <h2>{{ exerciseName }}</h2>
            </div>
          </div>

          <!-- Body -->
          <div class="modal-body">
            <p class="modal-subtitle">Wie viele hast du gemacht?</p>
            
            <!-- Input Section -->
            <div class="input-section">
              <button 
                class="big-btn decrement-big" 
                @click="changeReps(-10)"
                :disabled="reps <= 0"
              >
                -10
              </button>
              
              <button 
                class="small-btn decrement" 
                @click="changeReps(-1)"
                :disabled="reps <= 0"
              >
                −
              </button>
              
              <input 
                v-model.number="reps"
                type="number"
                min="0"
                :max="remaining"
                class="reps-input-large"
                @input="validateInput"
              />
              
              <button 
                class="small-btn increment" 
                @click="changeReps(1)"
                :disabled="reps >= remaining"
              >
                +
              </button>
              
              <button 
                class="big-btn increment-big" 
                @click="changeReps(10)"
                :disabled="reps >= remaining"
              >
                +10
              </button>
            </div>

            <p class="limit-info">
              <span>Noch {{ remaining }} heute möglich</span>
              <span class="daily-total">Heute: {{ todayCount }} / {{ dailyLimit }}</span>
            </p>

            <!-- XP Preview -->
            <div class="xp-preview">
              <span>XP-Gewinn:</span>
              <span class="xp-value">
                <span class="icon">⚡</span>
                +{{ calculatedXP }}
              </span>
            </div>
          </div>

          <!-- Footer -->
          <div class="modal-footer">
            <button class="cancel-btn" @click="closeModal">
              Abbrechen
            </button>
            <button 
              class="submit-btn"
              @click="submitExercise"
              :disabled="reps === 0"
            >
              Eintragen
            </button>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';

const props = defineProps<{
  isOpen: boolean;
  exerciseName: string;
  icon: string;
  xpPerRep: number;
  dailyLimit: number;
  todayCount: number;
}>();

const emit = defineEmits(['close', 'submit']);

const reps = ref(0);

const remaining = computed(() => {
  return Math.max(0, props.dailyLimit - props.todayCount);
});

const calculatedXP = computed(() => {
  return reps.value * props.xpPerRep;
});

const changeReps = (amount: number) => {
  const newValue = reps.value + amount;
  if (newValue >= 0 && newValue <= remaining.value) {
    reps.value = newValue;
  }
};

const validateInput = () => {
  if (reps.value < 0) reps.value = 0;
  if (reps.value > remaining.value) reps.value = remaining.value;
};

const closeModal = () => {
  reps.value = 0;
  emit('close');
};

const submitExercise = () => {
  emit('submit', {
    exercise: props.exerciseName,
    reps: reps.value,
    xp: calculatedXP.value
  });
  closeModal();
};
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.8);
  backdrop-filter: blur(8px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
  padding: 20px;
}

.modal-container {
  background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
  border: 1px solid rgba(236, 72, 153, 0.3);
  border-radius: 24px;
  max-width: 500px;
  width: 100%;
  box-shadow: 0 20px 60px rgba(236, 72, 153, 0.3);
}

/* Header */
.modal-header {
  padding: 24px 32px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.header-content {
  display: flex;
  align-items: center;
  gap: 16px;
}

.exercise-icon-large {
  font-size: 48px;
}

.modal-header h2 {
  font-size: 24px;
  font-weight: 700;
  color: white;
  margin: 0;
}

/* Body */
.modal-body {
  padding: 40px 32px;
}

.modal-subtitle {
  font-size: 16px;
  color: rgba(255, 255, 255, 0.7);
  margin: 0 0 32px 0;
  text-align: center;
}

/* Input Section */
.input-section {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  margin-bottom: 20px;
}

.reps-input-large {
  width: 120px;
  height: 70px;
  background: rgba(0, 0, 0, 0.4);
  border: 2px solid rgba(236, 72, 153, 0.5);
  border-radius: 16px;
  color: white;
  text-align: center;
  font-size: 36px;
  font-weight: 700;
  transition: all 0.3s ease;
}

.reps-input-large:focus {
  outline: none;
  border-color: rgba(236, 72, 153, 0.8);
  box-shadow: 0 0 20px rgba(236, 72, 153, 0.3);
}

.small-btn,
.big-btn {
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  background: rgba(255, 255, 255, 0.05);
  color: white;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
}

.small-btn {
  width: 50px;
  height: 50px;
  font-size: 24px;
}

.big-btn {
  width: 60px;
  height: 50px;
  font-size: 16px;
}

.small-btn:hover:not(:disabled),
.big-btn:hover:not(:disabled) {
  background: rgba(236, 72, 153, 0.2);
  border-color: rgba(236, 72, 153, 0.5);
}

.small-btn:disabled,
.big-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

/* Limit Info */
.limit-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 13px;
  color: rgba(255, 255, 255, 0.6);
  margin: 0 0 24px 0;
  padding: 0 8px;
}

.daily-total {
  color: rgba(255, 255, 255, 0.4);
}

/* XP Preview */
.xp-preview {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 24px;
  background: linear-gradient(135deg, rgba(236, 72, 153, 0.15), rgba(244, 63, 94, 0.15));
  border: 1px solid rgba(236, 72, 153, 0.3);
  border-radius: 16px;
}

.xp-preview > span:first-child {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.8);
  font-weight: 600;
}

.xp-value {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 24px;
  font-weight: 700;
  color: #fbbf24;
}

/* Footer */
.modal-footer {
  padding: 24px 32px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  display: flex;
  gap: 16px;
}

.cancel-btn,
.submit-btn {
  flex: 1;
  padding: 14px 24px;
  border-radius: 12px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.cancel-btn {
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.2);
  color: white;
}

.cancel-btn:hover {
  background: rgba(255, 255, 255, 0.1);
}

.submit-btn {
  background: linear-gradient(90deg, #ec4899, #f43f5e);
  border: none;
  color: white;
}

.submit-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(236, 72, 153, 0.3);
}

.submit-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* Transitions */
.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.3s ease;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-active .modal-container,
.modal-leave-active .modal-container {
  transition: transform 0.3s ease;
}

.modal-enter-from .modal-container,
.modal-leave-to .modal-container {
  transform: scale(0.95);
}
</style>