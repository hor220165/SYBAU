<template>
  <div class="activity-item">
    <div class="activity-icon" :class="`icon-${type}`">
      <div v-html="`<svg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'>${icon}</svg>`"></div>
    </div>
    <div class="activity-info">
      <h4 class="activity-title">{{ title }}</h4>
      <span class="activity-time">{{ time }}</span>
    </div>
    <div v-if="xp > 0" class="activity-xp">+{{ xp }} XP</div>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  icon: string;
  title: string;
  time: string;
  xp: number;
  type: 'workout' | 'quest' | 'achievement' | 'level';
}>();
</script>

<style scoped>
.activity-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 0 10px;
  background: transparent;
  border: 0;
  border-radius: 0;
}

.activity-icon {
  width: 42px;
  height: 42px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  background: rgba(255, 255, 255, 0.05);
  border: 1px solid rgba(255, 255, 255, 0.08);
  color: #fda4af;
}

.icon-workout {
  color: #fda4af;
}

.icon-quest {
  color: #fda4af;
}

.icon-achievement {
  color: #fda4af;
}

.icon-level {
  color: #fda4af;
}

.activity-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.activity-title {
  font-size: 15px;
  font-weight: 700;
  color: white;
  margin: 0;
}

.activity-time {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.56);
}

.activity-xp {
  padding: 0;
  background: transparent;
  border: 0;
  border-radius: 0;
  font-size: 15px;
  font-weight: 800;
  color: #fde047;
  flex-shrink: 0;
}
</style>
