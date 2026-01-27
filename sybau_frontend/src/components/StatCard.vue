<template>
  <div class="stat-card" :class="cardClass">
    <div class="stat-card-icon">{{ icon }}</div>
    <div class="stat-card-content">
      <p class="stat-card-label">{{ label }}</p>
      <p class="stat-card-value">{{ value }}</p>
      <p class="stat-card-trend">{{ trend }}</p>
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  icon: string;
  label: string;
  value: string;
  trend: string;
  cardClass?: string;
}>();
</script>

<style scoped>
.stat-card {
  background: rgba(15, 23, 42, 0.5);
  border: 1px solid rgba(59, 130, 246, 0.2);
  border-radius: 16px;
  padding: 24px;
  backdrop-filter: blur(10px);
  transition: all 0.3s ease;
  cursor: pointer;
}

.stat-card:hover {
  border-color: rgba(236, 72, 153, 0.4);
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(236, 72, 153, 0.2);
}

.stat-card-icon {
  width: 56px;
  height: 56px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
  margin-bottom: 16px;
  transition: transform 0.3s ease;
}

.stat-card:hover .stat-card-icon {
  transform: scale(1.1);
}

.streak-card .stat-card-icon {
  background: linear-gradient(135deg, #f97316, #ea580c);
  box-shadow: 0 4px 12px rgba(249, 115, 22, 0.3);
}

.achievements-card .stat-card-icon {
  background: linear-gradient(135deg, #eab308, #ca8a04);
  box-shadow: 0 4px 12px rgba(234, 179, 8, 0.3);
}

.quests-card .stat-card-icon {
  background: linear-gradient(135deg, #3b82f6, #2563eb);
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
}

.xp-card .stat-card-icon {
  background: linear-gradient(135deg, #ec4899, #db2777);
  box-shadow: 0 4px 12px rgba(236, 72, 153, 0.3);
}

.stat-card-content {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.stat-card-label {
  font-size: 14px;
  color: #93c5fd;
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