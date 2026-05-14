<template>
  <Header />
  <Navbar />

  <main class="quests-content">
    <!-- Loading State -->
    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <p>{{ text('Quests werden geladen...', 'Loading quests...') }}</p>
    </div>

    <template v-else>
      <section class="page-heading">
        <span class="page-kicker">Quests</span>
        <h1 class="page-title">{{ text('Quest Log', 'Quest Log') }}</h1>
        <p class="page-subtitle">{{ text('Schließe Quests ab und sammle Belohnungen.', 'Complete quests and collect rewards.') }}</p>
      </section>

      <section class="mobile-stats-panel">
        <div class="stats-grid">
          <article class="stat-card">
            <span class="stat-icon stat-icon-yellow">
              <Trophy :size="24" />
            </span>
            <span class="stat-copy">
              <span class="stat-label">{{ text('Abgeschlossen', 'Completed') }}</span>
              <span class="stat-value">{{ formatNumber(stats.completed) }}</span>
            </span>
          </article>
          <article class="stat-card">
            <span class="stat-icon stat-icon-blue">
              <Flag :size="24" />
            </span>
            <span class="stat-copy">
              <span class="stat-label">{{ text('Aktiv', 'Active') }}</span>
              <span class="stat-value">{{ formatNumber(stats.active) }}</span>
            </span>
          </article>
          <article class="stat-card">
            <span class="stat-icon stat-icon-purple">
              <Zap :size="24" />
            </span>
            <span class="stat-copy">
              <span class="stat-label">{{ text('Verdient', 'Earned') }}</span>
              <span class="stat-value">{{ formatNumber(stats.totalXpEarned) }} XP</span>
            </span>
          </article>
        </div>
      </section>

      <!-- Daily Quests -->
      <section class="quest-section" v-if="dailyQuests.length">
        <div class="section-header">
          <div class="section-title">
            <h2>{{ text('Tägliche Quests', 'Daily Quests') }}</h2>
          </div>
          <span class="renewal-badge">{{ dailyQuests[0]?.timeLeft }}</span>
        </div>
        <div class="quests-grid">
          <QuestCard
            v-for="quest in dailyQuests"
            :key="quest.id"
            :rarity="quest.rarity"
            :title="translate(quest.name)"
            :description="translate(quest.description)"
            :progress="quest.progress"
            :max-progress="quest.targetValue"
            :xp-reward="quest.xpReward"
            :coin-reward="quest.coinReward"
            :time-left="quest.timeLeft"
            :is-completed="quest.isCompleted"
            :is-reward-claimed="quest.isRewardClaimed"
            @claim="claimReward(quest)"
          />
        </div>
      </section>

      <!-- Weekly Quests -->
      <section class="quest-section" v-if="weeklyQuests.length">
        <div class="section-header">
          <div class="section-title">
            <h2>{{ text('Wöchentliche Quests', 'Weekly Quests') }}</h2>
          </div>
          <span class="renewal-badge renewal-weekly">{{ weeklyQuests[0]?.timeLeft }}</span>
        </div>
        <div class="quests-grid">
          <QuestCard
            v-for="quest in weeklyQuests"
            :key="quest.id"
            :rarity="quest.rarity"
            :title="translate(quest.name)"
            :description="translate(quest.description)"
            :progress="quest.progress"
            :max-progress="quest.targetValue"
            :xp-reward="quest.xpReward"
            :coin-reward="quest.coinReward"
            :time-left="quest.timeLeft"
            :is-completed="quest.isCompleted"
            :is-reward-claimed="quest.isRewardClaimed"
            @claim="claimReward(quest)"
          />
        </div>
      </section>

      <!-- Monthly Quests -->
      <section class="quest-section" v-if="monthlyQuests.length">
        <div class="section-header">
          <div class="section-title">
            <h2>{{ text('Monatliche Quests', 'Monthly Quests') }}</h2>
          </div>
          <span class="renewal-badge renewal-monthly">{{ monthlyQuests[0]?.timeLeft }}</span>
        </div>
        <div class="quests-grid">
          <QuestCard
            v-for="quest in monthlyQuests"
            :key="quest.id"
            :rarity="quest.rarity"
            :title="translate(quest.name)"
            :description="translate(quest.description)"
            :progress="quest.progress"
            :max-progress="quest.targetValue"
            :xp-reward="quest.xpReward"
            :coin-reward="quest.coinReward"
            :time-left="quest.timeLeft"
            :is-completed="quest.isCompleted"
            :is-reward-claimed="quest.isRewardClaimed"
            @claim="claimReward(quest)"
          />
        </div>
      </section>
    </template>

    <!-- Popup -->
    <MessagePopup :message="popup.message" :type="popup.type" :visible="popup.visible" @close="popup.visible = false" />
  </main>

  <FooterComponent />
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import Header from '@/components/Header.vue';
import Navbar from '@/components/Navbar.vue';
import QuestCard from '@/components/QuestCard.vue';
import FooterComponent from '@/components/FooterComponent.vue';
import MessagePopup from '@/components/MessagePopup.vue';
import { questService } from '@/services/api';
import { useAuth } from '@/composables/useAuth';
import { useLanguage } from '@/composables/useLanguage';
import type { UserQuest, QuestStats } from '@/models/Quest';
import { Flag, Trophy, Zap } from 'lucide-vue-next';

const { refreshProfile } = useAuth();
const { text, translate, locale } = useLanguage();

const allQuests = ref<UserQuest[]>([]);
const stats = ref<QuestStats>({ completed: 0, active: 0, totalXpEarned: 0 });
const loading = ref(true);
const popup = ref({ message: '', type: 'success' as 'success' | 'error', visible: false });

const dailyQuests = computed(() => allQuests.value.filter(q => q.type === 'daily'));
const weeklyQuests = computed(() => allQuests.value.filter(q => q.type === 'weekly'));
const monthlyQuests = computed(() => allQuests.value.filter(q => q.type === 'monthly'));

const showPopup = (message: string, type: 'success' | 'error') => {
  popup.value = { message, type, visible: true };
};

const formatNumber = (value: number) => {
  if (Math.abs(value) < 10000) return value.toLocaleString(locale.value);
  const units = [
    { amount: 1_000_000_000, suffix: 'B' },
    { amount: 1_000_000, suffix: 'M' },
    { amount: 1_000, suffix: 'K' }
  ];
  const unit = units.find((item) => Math.abs(value) >= item.amount);
  if (!unit) return value.toLocaleString(locale.value);
  const compact = value / unit.amount;
  const digits = compact >= 100 || Number.isInteger(compact) ? 0 : 1;
  return `${compact.toFixed(digits).replace('.', ',')}${unit.suffix}`;
};

const loadQuests = async () => {
  try {
    const [questsRes, statsRes] = await Promise.all([
      questService.getMyQuests(),
      questService.getStats()
    ]);
    allQuests.value = questsRes.data;
    stats.value = statsRes.data;
    notifyQuestBadge();
  } catch (e: any) {
    showPopup(e.response?.data?.message || text('Fehler beim Laden der Quests.', 'Could not load quests.'), 'error');
  }
};

const notifyQuestBadge = () => {
  const claimable = allQuests.value.some(q => q.isCompleted && !q.isRewardClaimed);
  window.dispatchEvent(new CustomEvent('sybau:quests-updated', { detail: { claimable } }));
};

const claimReward = async (quest: UserQuest) => {
  try {
    const { data } = await questService.claimReward(quest.id);
    showPopup(data.message, 'success');
    await Promise.all([loadQuests(), refreshProfile()]);
  } catch (e: any) {
    showPopup(e.response?.data?.message || text('Fehler beim Einfordern.', 'Could not claim reward.'), 'error');
  }
};

onMounted(async () => {
  await loadQuests();
  loading.value = false;
});
</script>

<style scoped>
.quests-content {
  padding: 40px;
  max-width: 1400px;
  margin: 0 auto;
}

.loading-state {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 300px;
  gap: 16px;
  color: rgba(255, 255, 255, 0.7);
  font-size: 16px;
}

.spinner {
  width: 40px;
  height: 40px;
  border: 3px solid rgba(236, 72, 153, 0.2);
  border-top-color: #ec4899;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.page-heading {
  margin-bottom: 24px;
}

.page-kicker {
  display: inline-flex;
  padding: 0;
  background: transparent;
  border: 0;
  color: #f9a8d4;
  font-size: 0.82rem;
  font-weight: 700;
  letter-spacing: 0.02em;
  margin-bottom: 14px;
}

.page-title {
  font-size: clamp(2rem, 4vw, 3.4rem);
  line-height: 1;
  font-weight: 900;
  margin: 0;
  color: white;
  text-shadow: none;
}

.page-subtitle {
  font-size: 16px;
  margin: 16px 0 0;
  color: rgba(255, 255, 255, 0.7);
}

.mobile-stats-panel {
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 24px;
  padding: 18px;
  margin-bottom: 30px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 18px;
}

/* Stat Cards */
.stat-card {
  min-height: 120px;
  background: rgba(2, 6, 23, 0.42);
  border: 1px solid rgba(255, 255, 255, 0.075);
  border-radius: 22px;
  padding: 22px 20px;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: center;
  gap: 12px;
}

.stat-icon {
  width: 30px;
  height: 30px;
  flex: 0 0 auto;
  display: flex;
  align-items: center;
  justify-content: center;
}

.stat-icon :deep(svg) {
  width: 100%;
  height: 100%;
}

.stat-icon-yellow {
  color: #fbbf24;
}

.stat-icon-blue {
  color: #60a5fa;
}

.stat-icon-purple {
  color: #a855f7;
}

.stat-copy {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 5px;
}

.stat-label {
  font-size: 16px;
  color: rgba(255, 255, 255, 0.66);
  font-weight: 700;
}

.stat-value {
  font-size: 22px;
  font-weight: 800;
  color: white;
  text-shadow: none;
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
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 24px;
}

/* Responsive - Tablet */
@media (max-width: 1024px) {
  .quests-content {
    padding: 32px 24px;
  }

  .page-title {
    font-size: 32px;
  }

  .stats-grid {
    grid-template-columns: repeat(3, 1fr);
    gap: 14px;
  }

  .stat-card {
    min-height: 110px;
    padding: 18px;
  }

  .stat-value {
    font-size: 22px;
  }
}

/* Responsive - Mobile */
@media (max-width: 768px) {
  .quests-content {
    padding: 24px 16px;
  }

  .page-title {
    font-size: 28px;
  }

  .page-subtitle {
    font-size: 14px;
  }

  .stats-grid {
    grid-template-columns: repeat(3, 1fr);
    gap: 12px;
  }

  .stat-label {
    font-size: 15px;
  }

  .stat-value {
    font-size: 22px;
  }

  .stat-card {
    padding: 16px;
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

/* Responsive - Narrow Mobile */
@media (max-width: 560px) {
  .mobile-stats-panel {
    border-radius: 18px;
    padding: 10px;
  }

  .stats-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 8px;
  }

  .stat-card {
    min-height: 82px;
    border-radius: 16px;
    padding: 10px 8px;
    gap: 8px;
  }

  .stat-icon {
    width: 21px;
    height: 21px;
  }

  .stat-copy {
    gap: 3px;
  }

  .stat-label {
    font-size: 0.66rem;
    line-height: 1.05;
  }

  .stat-value {
    font-size: 0.92rem;
    line-height: 1.08;
  }
}

/* Responsive - Small Mobile */
@media (max-width: 480px) {
  .quests-content {
    padding: 20px 12px;
  }

  .page-title {
    font-size: 24px;
  }

  .page-subtitle {
    font-size: 13px;
  }

  .stat-card {
    min-height: 76px;
    padding: 9px 7px;
  }

  .stat-label {
    font-size: 0.6rem;
  }

  .stat-value {
    font-size: 0.82rem;
  }

}
</style>
