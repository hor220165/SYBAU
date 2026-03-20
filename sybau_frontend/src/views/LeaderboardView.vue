<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { Crown, Trophy, Users, Sparkles } from 'lucide-vue-next';
import Navbar from '@/components/Navbar.vue';
import Header from '@/components/Header.vue';
import LeaderboardPodiumCard from '@/components/LeaderboardPodiumCard.vue';
import LeaderboardRow from '@/components/LeaderboardRow.vue';
import { useLeaderboard } from '@/composables/useLeaderboard';
import { userService } from '@/services/api';
import type { LeaderboardDisplayEntry } from '@/models/LeaderboardDisplayEntry';
import FooterComponent from '@/components/FooterComponent.vue';

const { sortedLeaderboard, loading, error, loadLeaderboard } = useLeaderboard();
const currentUserName = ref('');

const getInitials = (name: string) => {
  return name
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase() ?? '')
    .join('') || 'SB';
};

const syncCurrentUser = () => {
  const raw = JSON.parse(localStorage.getItem('user') || '{}');
  currentUserName.value = raw.userName ?? raw.UserName ?? raw.username ?? '';
};

const isCurrentUser = (name: string) => {
  if (!currentUserName.value) return false;
  return name.trim().toLowerCase() === currentUserName.value.trim().toLowerCase();
};

const leaderboardEntries = computed<LeaderboardDisplayEntry[]>(() =>
  sortedLeaderboard.value.map((player) => ({
    ...player,
    initials: getInitials(player.UserName),
    isCurrentUser: isCurrentUser(player.UserName),
  })),
);

const podiumPlayers = computed(() => leaderboardEntries.value.slice(0, 3));
const currentUserEntry = computed(() => leaderboardEntries.value.find((entry) => entry.isCurrentUser) ?? null);
const topFiveBorderXp = computed(() => leaderboardEntries.value[4]?.Experience ?? 0);
const xpToTopFive = computed(() => {
  if (!currentUserEntry.value || currentUserEntry.value.Rank <= 5) return 0;
  return Math.max(0, topFiveBorderXp.value - currentUserEntry.value.Experience);
});

const loadPageData = async () => {
  syncCurrentUser();

  try {
    await userService.getProfile();
  } catch (profileError) {
    console.warn('Profil konnte nicht aktualisiert werden:', profileError);
  } finally {
    syncCurrentUser();
  }

  await loadLeaderboard();
};

onMounted(loadPageData);
</script>

<template>
  <div class="leaderboard-page-shell">
    <Header />
    <Navbar />

    <main class="leaderboard-page">
      <section class="hero-card">
        <div class="hero-copy">
          <span class="hero-kicker">Leaderboard</span>
          <h1>Globales Ranking</h1>
          <p>
            Kämpfe dich durch Workouts und Quests nach oben. Dein aktueller Fortschritt wird live
            mit dem globalen Ranking abgeglichen.
          </p>
        </div>

        <div class="hero-stats">
          <article class="hero-stat-box">
            <span class="hero-stat-label">Dein Rang</span>
            <strong>{{ currentUserEntry ? `#${currentUserEntry.Rank}` : '—' }}</strong>
          </article>
          <article class="hero-stat-box">
            <span class="hero-stat-label">Spieler gesamt</span>
            <strong>{{ leaderboardEntries.length }}</strong>
          </article>
          <article class="hero-stat-box">
            <span class="hero-stat-label">Bis Top 5</span>
            <strong>{{ xpToTopFive.toLocaleString() }} XP</strong>
          </article>
        </div>
      </section>

      <div v-if="loading" class="state-box">Lade Leaderboard…</div>
      <div v-else-if="error" class="state-box state-box-error">
        <span>{{ error }}</span>
        <button class="retry-button" @click="loadPageData">Erneut versuchen</button>
      </div>

      <template v-else>
        <section class="section-card">
          <div class="section-heading">
            <div class="title-with-icon">
              <Crown :size="20" />
              <h2>Top Champions</h2>
            </div>
            <p>Das aktuelle Podium auf einen Blick.</p>
          </div>

          <div class="podium-grid" :class="{ 'podium-grid-compact': podiumPlayers.length < 3 }">
            <LeaderboardPodiumCard v-if="podiumPlayers[1]" :player="podiumPlayers[1]" :place="2" />
            <LeaderboardPodiumCard v-if="podiumPlayers[0]" :player="podiumPlayers[0]" :place="1" />
            <LeaderboardPodiumCard v-if="podiumPlayers[2]" :player="podiumPlayers[2]" :place="3" />
          </div>
        </section>

        <section class="section-card">
          <div class="section-heading section-heading-spread">
            <div>
              <div class="title-with-icon">
                <Trophy :size="20" />
                <h2>Globale Rangliste</h2>
              </div>
              <p>Alle Spieler nach Erfahrungspunkten sortiert.</p>
            </div>

            <div class="mini-insight-pill">
              <Users :size="16" />
              {{ leaderboardEntries.length }} aktive Einträge
            </div>
          </div>

          <div v-if="leaderboardEntries.length" class="leaderboard-list">
            <LeaderboardRow
              v-for="player in leaderboardEntries"
              :key="player.Id"
              :player="player"
            />
          </div>
          <div v-else class="empty-box">
            <Sparkles :size="18" />
            Noch keine Leaderboard-Daten vorhanden.
          </div>
        </section>
      </template>
    </main>
     <!-- Footer -->
    <FooterComponent />
  </div>
</template>

<style scoped>
.leaderboard-page-shell {
  min-height: 100vh;
  color: white;
}

.leaderboard-page {
  width: min(1280px, calc(100% - 32px));
  margin: 0 auto;
  padding: 32px 0 48px;
  display: grid;
  gap: 24px;
}

.hero-card,
.section-card,
.state-box,
.empty-box {
  border-radius: 28px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(15, 23, 42, 0.56);
  backdrop-filter: blur(18px);
  -webkit-backdrop-filter: blur(18px);
  box-shadow: 0 24px 50px rgba(2, 6, 23, 0.22);
}

.hero-card {
  display: grid;
  grid-template-columns: minmax(0, 1.3fr) minmax(320px, 0.9fr);
  gap: 24px;
  padding: clamp(24px, 3vw, 36px);
  background: linear-gradient(135deg, #ec4899, #f43f5e);
}

.hero-kicker {
  display: inline-flex;
  border-radius: 999px;
  padding: 7px 12px;
  background: rgba(255, 255, 255, 0.14);
  color: #f5d0fe;
  font-size: 0.82rem;
  font-weight: 700;
  letter-spacing: 0.02em;
  margin-bottom: 14px;
}

.hero-copy h1 {
  font-size: clamp(2rem, 4vw, 3.4rem);
  line-height: 1;
  margin: 0;
}

.hero-copy p {
  margin: 16px 0 0;
  max-width: 56ch;
  color: rgba(255, 255, 255, 0.85);
  line-height: 1.65;
}

.hero-stats {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 14px;
  align-self: end;
}

.hero-stat-box {
  padding: 18px;
  border-radius: 22px;
  background: rgba(255, 255, 255, 0.12);
  border: 1px solid rgba(255, 255, 255, 0.12);
}

.hero-stat-label {
  display: block;
  color: rgba(255, 255, 255, 0.7);
  font-size: 0.85rem;
  margin-bottom: 10px;
}

.hero-stat-box strong {
  font-size: clamp(1.15rem, 2vw, 1.5rem);
}

.section-card {
  padding: clamp(22px, 3vw, 30px);
}

.section-heading {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 22px;
}

.section-heading p {
  margin: 0;
  color: #cbd5e1;
}

.section-heading-spread {
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.title-with-icon {
  display: flex;
  align-items: center;
  gap: 10px;
}

.title-with-icon h2 {
  margin: 0;
  font-size: 1.2rem;
}

.title-with-icon svg {
  color: #facc15;
}

.podium-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 18px;
  align-items: end;
}

.leaderboard-list {
  display: grid;
  gap: 14px;
}

.mini-insight-pill {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  border-radius: 999px;
  padding: 10px 14px;
  background: rgba(168, 85, 247, 0.12);
  border: 1px solid rgba(168, 85, 247, 0.2);
  color: #ddd6fe;
  white-space: nowrap;
}

.state-box,
.empty-box {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  padding: 26px;
}

.state-box-error,
.empty-box {
  color: #f8fafc;
}

.retry-button {
  border: none;
  border-radius: 14px;
  padding: 12px 16px;
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  color: white;
  font-weight: 700;
}

@media (max-width: 1080px) {
  .hero-card {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 860px) {
  .leaderboard-page {
    width: min(100%, calc(100% - 24px));
    padding-top: 24px;
  }

  .hero-stats {
    grid-template-columns: 1fr;
  }

  .section-heading-spread {
    flex-direction: column;
    align-items: flex-start;
  }

  .podium-grid {
    grid-template-columns: 1fr;
    align-items: stretch;
  }
}

@media (max-width: 560px) {
  .leaderboard-page {
    width: min(100%, calc(100% - 16px));
    gap: 18px;
  }

  .hero-card,
  .section-card,
  .state-box,
  .empty-box {
    border-radius: 22px;
  }
}
</style>
