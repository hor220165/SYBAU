<template>
  <div class="activity-item">
    <div class="activity-icon" :class="`icon-${type}`">
      {{ icon }}
    </div>

    <div class="activity-info">
      <h4 class="activity-title">{{ title }}</h4>
      <span class="activity-time">{{ time }}</span>
    </div>

    <div v-if="xp > 0" class="activity-xp">
      +{{ xp }} XP
    </div>
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

/* Icon */
.activity-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  flex-shrink: 0;
}

.icon-workout {
  background: rgba(59, 130, 246, 0.2);
  border: 1px solid rgba(59, 130, 246, 0.4);
}

.icon-quest {
  background: rgba(168, 85, 247, 0.2);
  border: 1px solid rgba(168, 85, 247, 0.4);
}

.icon-achievement {
  background: rgba(251, 191, 36, 0.2);
  border: 1px solid rgba(251, 191, 36, 0.4);
}

.icon-level {
  background: rgba(34, 197, 94, 0.2);
  border: 1px solid rgba(34, 197, 94, 0.4);
}

/* Info */
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

/* XP Badge */
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