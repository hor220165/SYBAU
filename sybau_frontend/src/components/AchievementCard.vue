<template>
  <div class="achievement-card" :class="{ unlocked: unlocked, locked: !unlocked }">
    <div v-if="unlocked" class="unlock-badge">
      <img src="../assets/Star_Pixel.png" alt="">
    </div>
    <div class="achievement-icon" :class="{ grayscale: !unlocked }">
      <div v-html="`<svg xmlns='http://www.w3.org/2000/svg' width='40' height='40' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'>${icon}</svg>`"></div>
    </div>
    <h4 class="achievement-title">{{ title }}</h4>
    <p class="achievement-description">{{ description }}</p>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  icon: string;
  title: string;
  description: string;
  unlocked: boolean;
}>();
</script>

<style scoped>
.achievement-card {
  background: rgba(60, 50, 40, 0.6);
  border: 2px solid rgba(139, 92, 46, 0.4);
  border-radius: 16px;
  padding: 20px 16px;
  position: relative;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
  text-align: center;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  min-height: 160px;
}

.achievement-card.unlocked {
  border-color: rgba(251, 191, 36, 0.6);
  background: rgba(60, 50, 40, 0.8);
}

.achievement-card.unlocked:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(251, 191, 36, 0.3);
  border-color: rgba(251, 191, 36, 0.8);
}

.achievement-card.locked {
  opacity: 0.5;
  background: rgba(40, 40, 50, 0.4);
  border-color: rgba(100, 100, 120, 0.3);
}

.achievement-card.locked:hover {
  opacity: 0.7;
}

.unlock-badge {
  position: absolute;
  top: 10px;
  right: 10px;
  width: 28px;
  height: 28px;
  background: rgba(34, 197, 94, 0.3);
  border: 2px solid #22c55e;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.unlock-badge img {
  width: 16px;
  height: 16px;
  image-rendering: pixelated;
}

.achievement-icon {
  margin-bottom: 6px;
  color: #fbbf24;
  filter: drop-shadow(0 4px 12px rgba(251, 191, 36, 0.4));
  transition: all 0.3s ease;
}

.achievement-icon.grayscale {
  filter: grayscale(100%) opacity(0.4);
  color: rgba(255, 255, 255, 0.4);
}

.achievement-card.unlocked:hover .achievement-icon {
  transform: scale(1.1);
  filter: drop-shadow(0 8px 20px rgba(251, 191, 36, 0.6));
}

.achievement-title {
  font-size: 15px;
  font-weight: 700;
  color: white;
  margin: 0;
}

.achievement-card.locked .achievement-title {
  color: rgba(255, 255, 255, 0.4);
}

.achievement-description {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.7);
  margin: 0;
  line-height: 1.3;
}

.achievement-card.locked .achievement-description {
  color: rgba(255, 255, 255, 0.3);
}
@media (max-width: 480px) {
  .achievement-card {
    min-height: 120px;
    padding: 14px 10px;
  }

  .achievement-title {
    font-size: 12px;
  }

  .achievement-description {
    font-size: 10px;
  }

  .achievement-icon div {
    font-size: 0;
  }

  .achievement-icon svg {
    width: 28px;
    height: 28px;
  }

  .unlock-badge {
    width: 22px;
    height: 22px;
  }

  .unlock-badge img {
    width: 12px;
    height: 12px;
  }
}
</style>
