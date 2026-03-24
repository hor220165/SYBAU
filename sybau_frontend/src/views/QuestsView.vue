<template>
  <!-- Header -->
  <Header></Header>

  <!-- Navigation -->
  <Navbar></Navbar>

  <!-- Main Content -->
  <main class="quests-content">
    <!-- Stats Header -->
    <div class="stats-header">
      <div class="stats-header-content">
        <h1 class="page-title">Quest Log</h1>
        <p class="page-subtitle">Schließe Quests ab und sammle epische Belohnungen!</p>

        <div class="stats-grid">
          <div class="stat-card">
            <div class="stat-icon">
              <Trophy :size="28" />
            </div>
            <div class="stat-info">
              <span class="stat-label">Abgeschlossen</span>
              <span class="stat-value">47 Quests</span>
            </div>
          </div>
          <div class="stat-card">
            <div class="stat-icon">
              <Swords :size="28" />
            </div>
            <div class="stat-info">
              <span class="stat-label">Aktiv</span>
              <span class="stat-value">9 Quests</span>
            </div>
          </div>
          <div class="stat-card">
            <div class="stat-icon">
              <Sparkles :size="28" />
            </div>
            <div class="stat-info">
              <span class="stat-label">Verdient</span>
              <span class="stat-value">12,450 XP</span>
            </div>
          </div>
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
   <!-- Footer -->
    <FooterComponent />
</template>

<script setup lang="ts">
import { ref } from 'vue';
import { Trophy, Swords, Sparkles } from 'lucide-vue-next';
import Header from '@/components/Header.vue';
import Navbar from '@/components/Navbar.vue';
import QuestCard from '@/components/QuestCard.vue';
import FooterComponent from '@/components/FooterComponent.vue';

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

/* Stats Header - Glassmorphism Style */
.stats-header {
  position: relative;
  background: linear-gradient(135deg, 
    rgba(236, 72, 153, 0.25) 0%, 
    rgba(168, 85, 247, 0.2) 50%, 
    rgba(59, 130, 246, 0.15) 100%
  );
  border: 2px solid rgba(236, 72, 153, 0.5);
  border-radius: 24px;
  padding: 40px;
  margin-bottom: 40px;
  overflow: hidden;
  backdrop-filter: blur(20px);
  box-shadow: 
    0 0 40px rgba(236, 72, 153, 0.3),
    0 8px 32px rgba(0, 0, 0, 0.3);
}

/* Animated Gradient Overlay */
.stats-header::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(135deg, 
    rgba(236, 72, 153, 0.3) 0%, 
    rgba(168, 85, 247, 0.25) 50%, 
    rgba(59, 130, 246, 0.2) 100%
  );
  opacity: 0.6;
  pointer-events: none;
  z-index: 0;
  animation: pulse 8s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 0.6; }
  50% { opacity: 0.8; }
}

.stats-header-content {
  position: relative;
  z-index: 1;
}

.page-title {
  font-size: 36px;
  font-weight: 700;
  margin: 0 0 8px 0;
  color: white;
  text-shadow: 0 2px 20px rgba(236, 72, 153, 0.6);
}

.page-subtitle {
  font-size: 16px;
  margin: 0 0 32px 0;
  color: rgba(255, 255, 255, 0.9);
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
}

/* Stat Cards */
.stat-card {
  background: rgba(15, 23, 42, 0.7);
  backdrop-filter: blur(10px);
  border: 2px solid rgba(236, 72, 153, 0.5);
  border-radius: 16px;
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 16px;
  box-shadow: 
    0 4px 16px rgba(0, 0, 0, 0.3),
    0 0 20px rgba(236, 72, 153, 0.2);
}

.stat-icon {
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, rgba(236, 72, 153, 0.3), rgba(168, 85, 247, 0.3));
  border-radius: 12px;
  color: #ec4899;
  border: 1px solid rgba(236, 72, 153, 0.4);
}

.stat-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.stat-label {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.7);
  font-weight: 500;
}

.stat-value {
  font-size: 20px;
  font-weight: 700;
  color: white;
  text-shadow: 0 2px 10px rgba(236, 72, 153, 0.5);
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

/* Responsive - Tablet */
@media (max-width: 1024px) {
  .quests-content {
    padding: 32px 24px;
  }

  .stats-header {
    padding: 32px;
  }

  .page-title {
    font-size: 32px;
  }

  .stats-grid {
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
  }

  .stat-card {
    padding: 16px;
  }

  .stat-icon {
    width: 44px;
    height: 44px;
  }

  .stat-value {
    font-size: 18px;
  }
}

/* Responsive - Mobile */
@media (max-width: 768px) {
  .quests-content {
    padding: 24px 16px;
  }

  .stats-header {
    padding: 24px;
  }

  .page-title {
    font-size: 28px;
  }

  .page-subtitle {
    font-size: 14px;
  }

  .stats-grid {
    grid-template-columns: 1fr;
    gap: 12px;
  }

  .stat-card {
    padding: 16px;
  }

  .stat-icon {
    width: 40px;
    height: 40px;
  }

  .stat-label {
    font-size: 12px;
  }

  .stat-value {
    font-size: 16px;
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

/* Responsive - Small Mobile */
@media (max-width: 480px) {
  .quests-content {
    padding: 20px 12px;
  }

  .stats-header {
    padding: 20px;
    border-radius: 20px;
  }

  .page-title {
    font-size: 24px;
  }

  .page-subtitle {
    font-size: 13px;
    margin-bottom: 24px;
  }

  .stat-card {
    padding: 14px;
  }

  .stat-icon {
    width: 36px;
    height: 36px;
  }
}
</style>