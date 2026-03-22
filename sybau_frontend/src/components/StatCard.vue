<template>
  <div class="stat-card" :class="cardClass">
    <div class="stat-card-icon">
      <div v-html="`<svg xmlns='http://www.w3.org/2000/svg' width='36' height='36' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='1.75' stroke-linecap='round' stroke-linejoin='round'>${icon}</svg>`"></div>
    </div>
    <div class="stat-card-content">
      <p class="stat-card-label">{{ label }}</p>
      <p class="stat-card-value">{{ value }}</p>
      <p v-if="trend" class="stat-card-trend">{{ trend }}</p>
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  icon: string;
  label: string;
  value: string;
  trend?: string;
  cardClass?: string;
}>();
</script>

<style scoped>
.stat-card {
  background: rgba(15, 23, 42, 0.5);
  border: 1px solid rgba(255, 255, 255, 0.07);
  border-radius: 16px;
  padding: 24px;
  backdrop-filter: blur(10px);
  transition: all 0.3s ease;
  cursor: pointer;
}

.stat-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0, 0, 0, 0.3);
}

.stat-card-icon {
  width: 56px;
  height: 56px;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 16px;
  transition: transform 0.3s ease;
}

.stat-card:hover .stat-card-icon {
  transform: scale(1.15);
}

/* Purple */
.stat-purple .stat-card-icon {
  color: #a855f7;
  filter: drop-shadow(0 0 10px rgba(168, 85, 247, 0.8)) drop-shadow(0 0 20px rgba(168, 85, 247, 0.4));
}
.stat-purple:hover {
  border-color: rgba(168, 85, 247, 0.3);
  box-shadow: 0 8px 24px rgba(168, 85, 247, 0.15);
}

/* Blue */
.stat-blue .stat-card-icon {
  color: #3b82f6;
  filter: drop-shadow(0 0 10px rgba(59, 130, 246, 0.8)) drop-shadow(0 0 20px rgba(59, 130, 246, 0.4));
}
.stat-blue:hover {
  border-color: rgba(59, 130, 246, 0.3);
  box-shadow: 0 8px 24px rgba(59, 130, 246, 0.15);
}

/* Orange */
.stat-orange .stat-card-icon {
  color: #f97316;
  filter: drop-shadow(0 0 10px rgba(249, 115, 22, 0.8)) drop-shadow(0 0 20px rgba(249, 115, 22, 0.4));
}
.stat-orange:hover {
  border-color: rgba(249, 115, 22, 0.3);
  box-shadow: 0 8px 24px rgba(249, 115, 22, 0.15);
}

/* Green */
.stat-green .stat-card-icon {
  color: #22c55e;
  filter: drop-shadow(0 0 10px rgba(34, 197, 94, 0.8)) drop-shadow(0 0 20px rgba(34, 197, 94, 0.4));
}
.stat-green:hover {
  border-color: rgba(34, 197, 94, 0.3);
  box-shadow: 0 8px 24px rgba(34, 197, 94, 0.15);
}

/* legacy class support */
.streak-card .stat-card-icon {
  color: #f97316;
  filter: drop-shadow(0 0 10px rgba(249, 115, 22, 0.8)) drop-shadow(0 0 20px rgba(249, 115, 22, 0.4));
}
.achievements-card .stat-card-icon {
  color: #eab308;
  filter: drop-shadow(0 0 10px rgba(234, 179, 8, 0.8)) drop-shadow(0 0 20px rgba(234, 179, 8, 0.4));
}
.quests-card .stat-card-icon {
  color: #3b82f6;
  filter: drop-shadow(0 0 10px rgba(59, 130, 246, 0.8)) drop-shadow(0 0 20px rgba(59, 130, 246, 0.4));
}
.xp-card .stat-card-icon {
  color: #ec4899;
  filter: drop-shadow(0 0 10px rgba(236, 72, 153, 0.8)) drop-shadow(0 0 20px rgba(236, 72, 153, 0.4));
}

.stat-card-content {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.stat-card-label {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.5);
  margin: 0;
}

.stat-card-value {
  font-size: 24px;
  font-weight: 700;
  color: white;
  margin: 0;
}

.stat-card-trend {
  font-size: 12px;
  color: #6ee7b7;
  margin: 0;
}
</style>