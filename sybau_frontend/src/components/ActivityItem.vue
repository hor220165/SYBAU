<template>
  <div class="activity-item">
    <img class="activity-xp-icon" :src="xpIcon" alt="" />
    <div class="activity-info">
      <h4 class="activity-title">{{ title }}</h4>
      <span class="activity-time">{{ time }}</span>
    </div>
    <div v-if="xp > 0" class="activity-xp">+{{ xp }} XP</div>
  </div>
</template>

<script setup lang="ts">
import xpIcon from '@/assets/XP_Pixel.png';

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
  padding: 12px 0;
  background: transparent;
  border: 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 0;
}

.activity-xp-icon {
  width: 30px;
  height: 30px;
  object-fit: contain;
  image-rendering: pixelated;
  display: flex;
  flex-shrink: 0;
}

.activity-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.activity-title {
  font-size: 14px;
  line-height: 1.25;
  font-weight: 800;
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
  min-width: 72px;
  text-align: right;
  font-size: 13.5px;
  line-height: 1;
  font-weight: 800;
  color: #60a5fa;
  flex-shrink: 0;
}
</style>
