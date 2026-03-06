<template>
  <div class="workout-card">
    <!-- Category Badge -->
    <div class="category-badge" :class="categoryClass">
      {{ category }}
    </div>

    <!-- Completion Badge (optional) -->
    <div v-if="completed" class="completion-badge">
      ✓
    </div>

    <!-- Workout Title -->
    <h3 class="workout-title">{{ title }}</h3>

    <!-- Duration & Calories -->
    <div class="workout-stats">
      <div class="stat">
        <span class="icon">🕐</span>
        <span>{{ duration }} min</span>
      </div>
      <div class="stat">
        <span class="icon">🔥</span>
        <span>{{ calories }} kcal</span>
      </div>
    </div>

    <!-- Exercises Pills -->
    <div class="exercises">
      <span 
        v-for="(exercise, index) in displayExercises" 
        :key="index" 
        class="exercise-pill"
      >
        {{ exercise }}
      </span>
      <span v-if="remainingCount > 0" class="exercise-pill">
        +{{ remainingCount }}
      </span>
    </div>

    <!-- Bottom Section: Difficulty + XP + Button -->
    <div class="workout-footer">
      <div class="difficulty-section">
        <span class="difficulty-badge" :class="difficultyClass">
          {{ difficulty }}
        </span>
        <span class="xp-badge">
          <span class="icon">⚡</span>
          <span>+{{ xp }}</span>
        </span>
      </div>

      <button 
        v-if="!completed" 
        class="start-btn"
        @click="$emit('start')"
      >
        Start
        <span class="icon">▶</span>
      </button>
      <button 
        v-else 
        class="completed-btn"
        @click="$emit('view')"
      >
        Erledigt
        <span class="icon">▶</span>
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
  category: string;
  title: string;
  duration: number;
  calories: number;
  exercises: string[];
  difficulty: 'Easy' | 'Medium' | 'Hard';
  xp: number;
  completed?: boolean;
}>();

defineEmits(['start', 'view']);

const categoryClass = computed(() => {
  const classes: Record<string, string> = {
    'Cardio': 'category-cardio',
    'Strength': 'category-strength',
    'Yoga': 'category-yoga',
    'Core': 'category-core'
  };
  return classes[props.category] || 'category-default';
});

const difficultyClass = computed(() => {
  const classes: Record<string, string> = {
    'Easy': 'difficulty-easy',
    'Medium': 'difficulty-medium',
    'Hard': 'difficulty-hard'
  };
  return classes[props.difficulty] || '';
});

const displayExercises = computed(() => props.exercises.slice(0, 3));
const remainingCount = computed(() => Math.max(0, props.exercises.length - 3));
</script>

<style scoped>
.workout-card {
  background: rgba(30, 41, 59, 0.6);
  border: 1px solid rgba(59, 130, 246, 0.2);
  border-radius: 20px;
  padding: 24px;
  position: relative;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
}

.workout-card:hover {
  border-color: rgba(236, 72, 153, 0.4);
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(236, 72, 153, 0.2);
}

/* Category Badge */
.category-badge {
  display: inline-block;
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  margin-bottom: 16px;
}

.category-cardio {
  background: rgba(245, 158, 11, 0.2);
  color: #fbbf24;
  border: 1px solid rgba(245, 158, 11, 0.3);
}

.category-strength {
  background: rgba(59, 130, 246, 0.2);
  color: #60a5fa;
  border: 1px solid rgba(59, 130, 246, 0.3);
}

.category-yoga {
  background: rgba(139, 92, 246, 0.2);
  color: #a78bfa;
  border: 1px solid rgba(139, 92, 246, 0.3);
}

.category-core {
  background: rgba(236, 72, 153, 0.2);
  color: #ec4899;
  border: 1px solid rgba(236, 72, 153, 0.3);
}

/* Completion Badge */
.completion-badge {
  position: absolute;
  top: 20px;
  right: 20px;
  width: 32px;
  height: 32px;
  background: rgba(34, 197, 94, 0.3);
  border: 2px solid #22c55e;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #22c55e;
  font-weight: 700;
}

/* Title */
.workout-title {
  font-size: 20px;
  font-weight: 700;
  color: white;
  margin: 0 0 16px 0;
}

/* Stats */
.workout-stats {
  display: flex;
  gap: 16px;
  margin-bottom: 16px;
}

.stat {
  display: flex;
  align-items: center;
  gap: 6px;
  color: rgba(255, 255, 255, 0.7);
  font-size: 14px;
}

.stat .icon {
  font-size: 16px;
}

/* Exercises */
.exercises {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 20px;
}

.exercise-pill {
  padding: 6px 12px;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 8px;
  font-size: 12px;
  color: rgba(255, 255, 255, 0.7);
}

/* Footer */
.workout-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.difficulty-section {
  display: flex;
  gap: 12px;
  align-items: center;
}

.difficulty-badge {
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
}

.difficulty-easy {
  background: rgba(34, 197, 94, 0.2);
  color: #22c55e;
  border: 1px solid rgba(34, 197, 94, 0.3);
}

.difficulty-medium {
  background: rgba(234, 179, 8, 0.2);
  color: #fbbf24;
  border: 1px solid rgba(234, 179, 8, 0.3);
}

.difficulty-hard {
  background: rgba(239, 68, 68, 0.2);
  color: #f87171;
  border: 1px solid rgba(239, 68, 68, 0.3);
}

.xp-badge {
  display: flex;
  align-items: center;
  gap: 4px;
  color: #fbbf24;
  font-weight: 600;
  font-size: 14px;
}

/* Buttons */
.start-btn,
.completed-btn {
  padding: 10px 24px;
  border-radius: 12px;
  border: none;
  font-weight: 600;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.3s ease;
}

.start-btn {
   background: linear-gradient(135deg, #ec4899, #f43f5e);
  color: white;
}

.start-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(168, 85, 247, 0.3);
}

.completed-btn {
  background: rgba(236, 72, 153, 0.2);
  color: #f472b6;
  border: 1px solid rgba(236, 72, 153, 0.3);
}

.completed-btn:hover {
  background: rgba(236, 72, 153, 0.3);
}
</style>