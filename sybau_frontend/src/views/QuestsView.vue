<template>
  <!-- Header -->
  <Header></Header>

  <!-- Navigation -->
  <Navbar></Navbar>

  <!-- Main Content -->
  <main class="quests-content">
    <!-- Stats Header -->
    <div class="stats-header">
      <h1 class="page-title">Quest Log</h1>
      <p class="page-subtitle">Schließe Quests ab und sammle epische Belohnungen!</p>

      <div class="stats-grid">
        <div class="stat-card">
          <span class="stat-label">Abgeschlossen</span>
          <span class="stat-value">47 Quests</span>
        </div>
        <div class="stat-card">
          <span class="stat-label">Aktiv</span>
          <span class="stat-value">9 Quests</span>
        </div>
        <div class="stat-card">
          <span class="stat-label">Verdient</span>
          <span class="stat-value">12,450 XP</span>
        </div>
      </div>
    </div>

    <!-- Daily Quests -->
    <section class="quest-section">
      <div class="section-header">
        <div class="section-title">
          <span class="section-icon">🔥</span>
          <h2>Tägliche Quests</h2>
        </div>
        <span class="renewal-badge">Erneuert in 18h</span>
      </div>

      <div class="quests-grid">
        <QuestCard
          v-for="quest in dailyQuests"
          :key="quest.id"
          :rarity="quest.rarity"
          :title="quest.title"
          :description="quest.description"
          :progress="quest.progress"
          :max-progress="quest.maxProgress"
          :xp-reward="quest.xpReward"
          :time-left="quest.timeLeft"
          @click="viewQuest(quest)"
        />
      </div>
    </section>

    <!-- Weekly Quests -->
    <section class="quest-section">
      <div class="section-header">
        <div class="section-title">
          <span class="section-icon">🎯</span>
          <h2>Wöchentliche Quests</h2>
        </div>
        <span class="renewal-badge renewal-weekly">Erneuert in 4 Tagen</span>
      </div>

      <div class="quests-grid">
        <QuestCard
          v-for="quest in weeklyQuests"
          :key="quest.id"
          :rarity="quest.rarity"
          :title="quest.title"
          :description="quest.description"
          :progress="quest.progress"
          :max-progress="quest.maxProgress"
          :xp-reward="quest.xpReward"
          :time-left="quest.timeLeft"
          @click="viewQuest(quest)"
        />
      </div>
    </section>

    <!-- Monthly Quests -->
    <section class="quest-section">
      <div class="section-header">
        <div class="section-title">
          <span class="section-icon">🏆</span>
          <h2>Monatliche Quests</h2>
        </div>
        <span class="renewal-badge renewal-monthly">Limitiert</span>
      </div>

      <div class="quests-grid">
        <QuestCard
          v-for="quest in monthlyQuests"
          :key="quest.id"
          :rarity="quest.rarity"
          :title="quest.title"
          :description="quest.description"
          :progress="quest.progress"
          :max-progress="quest.maxProgress"
          :xp-reward="quest.xpReward"
          :time-left="quest.timeLeft"
          @click="viewQuest(quest)"
        />
      </div>
    </section>
  </main>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import Header from '@/components/Header.vue';
import Navbar from '@/components/Navbar.vue';
import QuestCard from '@/components/QuestCard.vue';

// Daily Quests
const dailyQuests = ref([
  {
    id: 1,
    rarity: 'Common',
    title: 'Tägliches Training',
    description: 'Schließe ein beliebiges Workout ab',
    progress: 0,
    maxProgress: 1,
    xpReward: 100,
    timeLeft: '18h'
  },
  {
    id: 2,
    rarity: 'Common',
    title: 'Kalorienjäger',
    description: 'Verbrenne 300 Kalorien',
    progress: 180,
    maxProgress: 300,
    xpReward: 150,
    timeLeft: '18h'
  },
  {
    id: 3,
    rarity: 'Common',
    title: 'Step Master',
    description: 'Laufe 10.000 Schritte',
    progress: 6500,
    maxProgress: 10000,
    xpReward: 120,
    timeLeft: '18h'
  }
]);

// Weekly Quests
const weeklyQuests = ref([
  {
    id: 4,
    rarity: 'Rare',
    title: 'Cardio Champion',
    description: 'Laufe insgesamt 10km',
    progress: 7,
    maxProgress: 10,
    xpReward: 500,
    timeLeft: '4d'
  },
  {
    id: 5,
    rarity: 'Rare',
    title: 'Kraft Krieger',
    description: 'Hebe insgesamt 5000kg',
    progress: 3200,
    maxProgress: 5000,
    xpReward: 600,
    timeLeft: '4d'
  },
  {
    id: 6,
    rarity: 'Epic',
    title: 'Consistency King',
    description: 'Trainiere 5 Tage diese Woche',
    progress: 3,
    maxProgress: 5,
    xpReward: 800,
    timeLeft: '4d'
  }
]);

// Monthly Quests
const monthlyQuests = ref([
  {
    id: 7,
    rarity: 'Legendary',
    title: 'Marathon Meister',
    description: 'Laufe insgesamt 42km',
    progress: 28,
    maxProgress: 42,
    xpReward: 2000,
    timeLeft: '30d'
  },
  {
    id: 8,
    rarity: 'Legendary',
    title: 'Iron Body',
    description: 'Hebe insgesamt 50.000kg',
    progress: 23400,
    maxProgress: 50000,
    xpReward: 3000,
    timeLeft: '30d'
  },
  {
    id: 9,
    rarity: 'Legendary',
    title: 'Transformer',
    description: 'Trainiere 30 Tage in Folge',
    progress: 12,
    maxProgress: 30,
    xpReward: 5000,
    timeLeft: '∞'
  }
]);

const viewQuest = (quest: any) => {
  console.log('Viewing quest:', quest);
  // TODO: Show quest details or navigate
};
</script>

<style scoped>
.quests-content {
  padding: 40px;
  max-width: 1400px;
  margin: 0 auto;
}

/* Stats Header */
.stats-header {
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  border-radius: 24px;
  padding: 40px;
  margin-bottom: 40px;
}

.page-title {
  font-size: 32px;
  font-weight: 700;
  margin: 0 0 8px 0;
  color: white;
}

.page-subtitle {
  font-size: 16px;
  margin: 0 0 32px 0;
  color: rgba(255, 255, 255, 0.9);
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
}

.stat-card {
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(10px);
  border-radius: 16px;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.stat-label {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.8);
}

.stat-value {
  font-size: 24px;
  font-weight: 700;
  color: white;
}

/* Quest Sections */
.quest-section {
  margin-bottom: 48px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.section-title {
  display: flex;
  align-items: center;
  gap: 12px;
}

.section-icon {
  font-size: 28px;
}

.section-title h2 {
  font-size: 24px;
  font-weight: 700;
  color: white;
  margin: 0;
}

.renewal-badge {
  padding: 8px 16px;
  background: rgba(245, 158, 11, 0.2);
  border: 1px solid rgba(245, 158, 11, 0.4);
  border-radius: 12px;
  font-size: 14px;
  font-weight: 600;
  color: #fbbf24;
}

.renewal-weekly {
  background: rgba(59, 130, 246, 0.2);
  border-color: rgba(59, 130, 246, 0.4);
  color: #60a5fa;
}

.renewal-monthly {
  background: rgba(251, 191, 36, 0.2);
  border-color: rgba(251, 191, 36, 0.4);
  color: #fbbf24;
}

.quests-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 24px;
}

/* Responsive */
@media (max-width: 768px) {
  .quests-content {
    padding: 20px;
  }
  
  .section-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }
  
  .quests-grid {
    grid-template-columns: 1fr;
  }
}
</style>