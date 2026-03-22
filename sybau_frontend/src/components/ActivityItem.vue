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
  gap: 16px;
  padding: 16px 20px;
  background: rgba(30, 41, 59, 0.6);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
}

.activity-item:hover {
  background: rgba(30, 41, 59, 0.8);
  border-color: rgba(236, 72, 153, 0.3);
  transform: translateX(4px);
}

.activity-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.icon-workout {
  background: rgba(59, 130, 246, 0.2);
  border: 1px solid rgba(59, 130, 246, 0.4);
  color: #3b82f6;
}

.icon-quest {
  background: rgba(168, 85, 247, 0.2);
  border: 1px solid rgba(168, 85, 247, 0.4);
  color: #a855f7;
}

.icon-achievement {
  background: rgba(251, 191, 36, 0.2);
  border: 1px solid rgba(251, 191, 36, 0.4);
  color: #fbbf24;
}

.icon-level {
  background: rgba(34, 197, 94, 0.2);
  border: 1px solid rgba(34, 197, 94, 0.4);
  color: #22c55e;
}

.activity-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.activity-title {
  font-size: 15px;
  font-weight: 600;
  color: white;
  margin: 0;
}

.activity-time {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.5);
}

.activity-xp {
  padding: 6px 12px;
  background: rgba(251, 191, 36, 0.2);
  border: 1px solid rgba(251, 191, 36, 0.4);
  border-radius: 8px;
  font-size: 14px;
  font-weight: 700;
  color: #fbbf24;
  flex-shrink: 0;
}
</style>