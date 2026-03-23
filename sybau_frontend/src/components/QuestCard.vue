<template>
  <div class="quest-card" :class="`rarity-${rarity.toLowerCase()}`">
    <!-- Rarity Badge -->
    <div class="rarity-badge" :class="`badge-${rarity.toLowerCase()}`">
      {{ rarity }}
    </div>

    <!-- Time Left -->
    <div class="time-badge">
      <span class="icon">⏱</span>
      {{ timeLeft }}
    </div>

    <!-- Quest Info -->
    <h3 class="quest-title">{{ title }}</h3>
    <p class="quest-description">{{ description }}</p>

    <!-- Progress -->
    <div class="progress-section">
      <div class="progress-info">
        <span class="progress-text">{{ progress }} / {{ maxProgress }}</span>
        <span class="progress-percent">{{ progressPercent }}%</span>
      </div>
      <div class="progress-bar">
        <div class="progress-fill" :style="`width: ${progressPercent}%`"></div>
      </div>
    </div>

    <!-- Reward -->
    <div class="reward-section">
      <div class="xp-reward">
        <span class="icon">⭐</span>
        <span>+{{ xpReward }} XP</span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue';

const props = defineProps<{
  rarity: string;
  title: string;
  description: string;
  progress: number;
  maxProgress: number;
  xpReward: number;
  timeLeft: string;
}>();

const progressPercent = computed(() => {
  return Math.min(100, Math.round((props.progress / props.maxProgress) * 100));
});
</script>

<style scoped>
.quest-card {
  background: rgba(30, 41, 59, 0.6);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 20px;
  padding: 24px;
  position: relative;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
  cursor: pointer;
}

.quest-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
}

/* Rarity Styles */
.rarity-common:hover {
  border-color: rgba(156, 163, 175, 0.5);
  box-shadow: 0 8px 24px rgba(156, 163, 175, 0.2);
}

.rarity-rare:hover {
  border-color: rgba(59, 130, 246, 0.5);
  box-shadow: 0 8px 24px rgba(59, 130, 246, 0.2);
}

.rarity-epic:hover {
  border-color: rgba(168, 85, 247, 0.5);
  box-shadow: 0 8px 24px rgba(168, 85, 247, 0.2);
}

.rarity-legendary:hover {
  border-color: rgba(251, 191, 36, 0.5);
  box-shadow: 0 8px 24px rgba(251, 191, 36, 0.2);
}

/* Badges */
.rarity-badge {
  position: absolute;
  top: 16px;
  left: 16px;
  padding: 6px 12px;
  border-radius: 50px;
  font-size: 12px;
  font-weight: 600;
}

.badge-common {
  background: rgba(156, 163, 175, 0.2);
  border: 1px solid rgba(156, 163, 175, 0.4);
  color: #9ca3af;
}

.badge-rare {
  background: rgba(59, 130, 246, 0.2);
  border: 1px solid rgba(59, 130, 246, 0.4);
  color: #60a5fa;
}

.badge-epic {
  background: rgba(168, 85, 247, 0.2);
  border: 1px solid rgba(168, 85, 247, 0.4);
  color: #a855f7;
}

.badge-legendary {
  background: rgba(251, 191, 36, 0.2);
  border: 1px solid rgba(251, 191, 36, 0.4);
  color: #fbbf24;
}

.time-badge {
  position: absolute;
  top: 16px;
  right: 16px;
  padding: 6px 12px;
  background: rgba(0, 0, 0, 0.3);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.8);
  display: flex;
  align-items: center;
  gap: 4px;
}

/* Quest Info */
.quest-title {
  font-size: 20px;
  font-weight: 700;
  color: white;
  margin: 40px 0 8px 0;
}

.quest-description {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.6);
  margin: 0 0 24px 0;
}

/* Progress */
.progress-section {
  margin-bottom: 20px;
}

.progress-info {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 8px;
}

.progress-text {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.8);
  font-weight: 600;
}

.progress-percent {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.6);
}

.progress-bar {
  height: 8px;
  background: rgba(0, 0, 0, 0.3);
  border-radius: 999px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #ec4899, #f43f5e);
  border-radius: 999px;
  transition: width 0.3s ease;
}

/* Reward Section */
.reward-section {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.xp-reward {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 16px;
  font-weight: 700;
  color: #fbbf24;
}
</style>