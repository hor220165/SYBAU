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
  display: grid;
  grid-template-columns: 30px minmax(0, 1fr) max-content;
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
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}

.activity-title {
  font-size: 13px;
  line-height: 1.2;
  font-weight: 800;
  color: white;
  margin: 0;
  overflow-wrap: anywhere;
}

.activity-time {
  min-width: 0;
  overflow: hidden;
  color: rgba(255, 255, 255, 0.56);
  font-size: 11px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.activity-xp {
  padding: 0;
  background: transparent;
  border: 0;
  border-radius: 0;
  min-width: 74px;
  text-align: right;
  font-size: 12.5px;
  line-height: 1;
  font-weight: 800;
  color: #60a5fa;
  white-space: nowrap;
}

@media (max-width: 560px) {
  .activity-item {
    grid-template-columns: 26px minmax(0, 1fr) minmax(58px, max-content);
    gap: 8px;
  }

  .activity-xp-icon {
    width: 24px;
    height: 24px;
  }

  .activity-title {
    font-size: 12.5px;
  }

  .activity-xp {
    min-width: 58px;
    font-size: 12px;
  }
}
</style>
