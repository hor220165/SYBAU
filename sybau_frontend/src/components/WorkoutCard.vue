<template>
  <div class="workout-card" @click="$emit('log')">
    <!-- Category Badge mit dynamischer Farbe -->
    <div class="category-badge" :class="`category-${category.toLowerCase()}`">
      {{ category }}
    </div>
    
    <!-- Title -->
    <h3 class="workout-title">{{ title }}</h3>
    
    <!-- Description -->
    <p class="workout-description">{{ exercises[0] }}</p>
    
    <!-- Bottom Row -->
    <div class="workout-meta">
      <span class="difficulty" :class="`difficulty-${difficulty.toLowerCase()}`">
        {{ difficulty }}
      </span>
      <span class="xp">
        <img src="../assets/XP_Pixel.png" alt="" />
        +{{ xp }} XP
      </span>
    </div>
    
    <!-- Action Button -->
    <button class="log-btn" @click.stop="$emit('log')">
      Training eintragen
    </button>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  category: string;
  title: string;
  exercises: string[];
  difficulty: 'Easy' | 'Medium' | 'Hard';
  xp: number;
  completed?: boolean;
  duration?: number;
  calories?: number;
}>();

defineEmits<{
  log: [];
}>();
</script>

<style scoped>
.workout-card {
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

.workout-card:hover {
  border-color: rgba(236, 72, 153, 0.3);
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
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

/* Responsive */
@media (max-width: 768px) {
  .workout-card {
    padding: 20px;
  }

  .workout-title {
    font-size: 20px;
  }
}
</style>
