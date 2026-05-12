<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { Crown, Trophy, Sparkles } from 'lucide-vue-next';
import Navbar from '@/components/Navbar.vue';
import Header from '@/components/Header.vue';
import LeaderboardPodiumCard from '@/components/LeaderboardPodiumCard.vue';
import LeaderboardRow from '@/components/LeaderboardRow.vue';
import PublicProfileSheet from '@/components/PublicProfileSheet.vue';
import { useLeaderboard } from '@/composables/useLeaderboard';
import { userService } from '@/services/api';
import type { LeaderboardDisplayEntry } from '@/models/LeaderboardDisplayEntry';
import FooterComponent from '@/components/FooterComponent.vue';

const { sortedLeaderboard, loading, error, loadLeaderboard } = useLeaderboard();
const currentUserName = ref('');
const viewedProfileId = ref<number | null>(null);
const showProfileSheet = ref(false);

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
    ProfileImageUrl: player.ProfileImageUrl,
    initials: getInitials(player.UserName),
    isCurrentUser: isCurrentUser(player.UserName),
  })),
);

const podiumPlayers = computed(() => leaderboardEntries.value.slice(0, 3));

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

const openUserProfile = (userId: number) => {
  if (!userId) return;
  viewedProfileId.value = userId;
  showProfileSheet.value = true;
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
            <LeaderboardPodiumCard v-if="podiumPlayers[1]" :player="podiumPlayers[1]" :place="2" @open-profile="openUserProfile" />
            <LeaderboardPodiumCard v-if="podiumPlayers[0]" :player="podiumPlayers[0]" :place="1" @open-profile="openUserProfile" />
            <LeaderboardPodiumCard v-if="podiumPlayers[2]" :player="podiumPlayers[2]" :place="3" @open-profile="openUserProfile" />
          </div>
        </section>

        <section class="section-card">
          <div class="section-heading">
            <div>
              <div class="title-with-icon">
                <Trophy :size="20" />
                <h2>Globale Rangliste</h2>
              </div>
              <p>Alle Spieler nach Erfahrungspunkten sortiert.</p>
            </div>
          </div>

          <div v-if="leaderboardEntries.length" class="leaderboard-list">
            <LeaderboardRow
              v-for="player in leaderboardEntries"
              :key="player.Id"
              :player="player"
              @open-profile="openUserProfile"
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
    <PublicProfileSheet
      :visible="showProfileSheet"
      :user-id="viewedProfileId"
      @close="showProfileSheet = false"
    />
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

.section-card,
.state-box,
.empty-box {
  border-radius: 22px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(15, 23, 42, 0.62);
  backdrop-filter: blur(18px);
  -webkit-backdrop-filter: blur(18px);
  box-shadow: 0 18px 42px rgba(2, 6, 23, 0.24);
}

.hero-card {
  display: block;
  padding: 0;
  background: transparent;
}

.hero-kicker {
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
  color: #d4af37;
}

.podium-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 18px;
  align-items: end;
}

.leaderboard-list {
  display: grid;
  gap: 0;
  padding: 4px 0 0;
}

.leaderboard-list :deep(.leaderboard-row:last-child) {
  border-bottom: 0;
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

@media (max-width: 860px) {
  .leaderboard-page {
    width: min(100%, calc(100% - 24px));
    padding-top: 24px;
  }

  .section-card {
    padding: 18px;
  }

  .section-heading {
    margin-bottom: 16px;
  }

  .title-with-icon {
    gap: 8px;
  }

  .title-with-icon h2 {
    font-size: 1.05rem;
  }

  .section-heading p {
    font-size: 0.92rem;
  }

  .podium-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 12px;
  }
}

@media (max-width: 560px) {
  .leaderboard-page {
    width: min(100%, calc(100% - 16px));
    gap: 18px;
  }

  .section-card,
  .state-box,
  .empty-box {
    border-radius: 18px;
  }

  .section-card {
    padding: 12px;
  }

  .section-heading {
    gap: 5px;
    margin-bottom: 12px;
  }

  .title-with-icon h2 {
    font-size: 0.98rem;
  }

  .title-with-icon svg {
    width: 17px;
    height: 17px;
  }

  .section-heading p {
    font-size: 0.82rem;
    line-height: 1.35;
  }

  .podium-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 6px;
    align-items: stretch;
  }
}

@media (max-width: 400px) {
  .leaderboard-page {
    gap: 14px;
  }

  .section-card {
    padding: 10px;
  }

  .podium-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 4px;
  }
}
</style>
