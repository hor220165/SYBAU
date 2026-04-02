<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import {
  Users, UserPlus, Swords, Trophy, Crown, Send, Check, X,
  Search, Clock, Sparkles, Shield, Trash2, Plus
} from 'lucide-vue-next';
import Navbar from '@/components/Navbar.vue';
import Header from '@/components/Header.vue';
import FooterComponent from '@/components/FooterComponent.vue';
import MessagePopup from '@/components/MessagePopup.vue';
import LeaderboardRow from '@/components/LeaderboardRow.vue';
import { friendService } from '@/services/api';
import { useAuth } from '@/composables/useAuth';
import { useNotifications } from '@/composables/useNotifications';
import type { FriendshipDto, FriendRequestDto, FriendChallengeDto, CreateFriendChallengeDto } from '@/models/Friend';

const { refreshProfile } = useAuth();
const { onSignalREvent, offSignalREvent } = useNotifications();

// ───── SignalR live-refresh ─────
const handleSignalR = async (type: string) => {
  if (type === 'friend_request') {
    await loadRequests();
    activeTab.value = 'requests';
  } else if (type === 'friend_accepted') {
    await loadFriends();
  }
};
import type { LeaderboardDisplayEntry } from '@/models/LeaderboardDisplayEntry';

// ───── Popup ─────
const popupMessage = ref('');
const popupType = ref<'success' | 'error'>('success');

const showPopup = (msg: string, type: 'success' | 'error' = 'success') => {
  popupMessage.value = '';
  setTimeout(() => {
    popupMessage.value = msg;
    popupType.value = type;
  }, 50);
};

// ───── State ─────
const activeTab = ref<'friends' | 'requests' | 'challenges' | 'leaderboard'>('friends');
const loading = ref(false);

const friends = ref<FriendshipDto[]>([]);
const pendingRequests = ref<FriendRequestDto[]>([]);
const challenges = ref<FriendChallengeDto[]>([]);
const leaderboard = ref<any[]>([]);

const searchQuery = ref('');
const friendRequestName = ref('');

// Challenge erstellen
const showChallengeModal = ref(false);
const challengeForm = ref<CreateFriendChallengeDto>({
  opponentId: 0,
  title: '',
  description: '',
  xpReward: 50,
  coinReward: 10,
  goalAmount: 100,
  durationHours: 24,
});

// Progress Modal
const showProgressModal = ref(false);
const progressChallengeId = ref(0);
const progressAmount = ref(1);
const progressChallengeGoal = ref(100);
const progressChallengeCurrent = ref(0);

const currentUserName = ref('');
const currentUserId = ref(0);

// ───── Computed ─────
const filteredFriends = computed(() => {
  if (!searchQuery.value) return friends.value;
  const q = searchQuery.value.toLowerCase();
  return friends.value.filter(f => f.friendUserName.toLowerCase().includes(q));
});

const activeChallenges = computed(() =>
  challenges.value.filter(c => c.status === 'Accepted')
);
const pendingChallenges = computed(() =>
  challenges.value.filter(c => c.status === 'Pending')
);
const completedChallenges = computed(() =>
  challenges.value.filter(c => c.status === 'Completed' || c.status === 'Expired' || c.status === 'Declined')
);

const leaderboardEntries = computed<LeaderboardDisplayEntry[]>(() =>
  leaderboard.value.map((player: any) => ({
    Id: player.id ?? player.Id,
    Rank: player.rank ?? player.Rank,
    UserName: player.userName ?? player.UserName,
    Experience: player.experience ?? player.Experience,
    Level: player.level ?? player.Level,
    initials: getInitials(player.userName ?? player.UserName ?? ''),
    isCurrentUser: (player.userName ?? player.UserName ?? '').toLowerCase() === currentUserName.value.toLowerCase(),
  }))
);

// ───── Helpers ─────
const getInitials = (name: string) =>
  name.split(/\s+/).filter(Boolean).slice(0, 2).map(p => p[0]?.toUpperCase() ?? '').join('') || 'SB';

const formatDate = (dateStr: string) => {
  if (!dateStr) return '–';
  // Backend sendet UTC-Zeiten ohne 'Z'-Suffix → anhängen damit JS korrekt konvertiert
  const fixed = dateStr.endsWith('Z') ? dateStr : dateStr + 'Z';
  const d = new Date(fixed);
  if (isNaN(d.getTime())) return '–';
  return d.toLocaleDateString('de-DE', { day: '2-digit', month: 'long', year: 'numeric' });
};

const timeRemaining = (expiresAt: string) => {
  const diff = new Date(expiresAt).getTime() - Date.now();
  if (diff <= 0) return 'Abgelaufen';
  const hours = Math.floor(diff / 3600000);
  const minutes = Math.floor((diff % 3600000) / 60000);
  if (hours > 24) return `${Math.floor(hours / 24)}d ${hours % 24}h`;
  return `${hours}h ${minutes}m`;
};

const statusColor = (status: string) => {
  switch (status) {
    case 'Accepted': return '#22c55e';
    case 'Pending': return '#f59e0b';
    case 'Completed': return '#8b5cf6';
    case 'Expired': return '#6b7280';
    case 'Declined': return '#ef4444';
    default: return '#94a3b8';
  }
};

const statusLabel = (status: string) => {
  switch (status) {
    case 'Accepted': return 'Aktiv';
    case 'Pending': return 'Ausstehend';
    case 'Completed': return 'Abgeschlossen';
    case 'Expired': return 'Abgelaufen';
    case 'Declined': return 'Abgelehnt';
    default: return status;
  }
};

const progressPercent = (current: number, goal: number) =>
  Math.min(100, Math.round((current / Math.max(goal, 1)) * 100));

// ───── API Calls ─────
const loadFriends = async () => {
  try {
    const { data } = await friendService.getFriends();
    friends.value = data;
  } catch (e) { console.error('Fehler beim Laden der Freunde', e); }
};

const loadRequests = async () => {
  try {
    const { data } = await friendService.getPendingRequests();
    pendingRequests.value = data;
  } catch (e) { console.error('Fehler beim Laden der Anfragen', e); }
};

const loadChallenges = async () => {
  try {
    const { data } = await friendService.getChallenges();
    challenges.value = data;
  } catch (e) { console.error('Fehler beim Laden der Challenges', e); }
};

const loadLeaderboard = async () => {
  try {
    const { data } = await friendService.getFriendsLeaderboard();
    leaderboard.value = Array.isArray(data) ? data : [];
  } catch (e) { console.error('Fehler beim Laden der Bestenliste', e); }
};

const loadAll = async () => {
  loading.value = true;
  await Promise.all([loadFriends(), loadRequests(), loadChallenges(), loadLeaderboard()]);
  loading.value = false;
};

// ───── Actions ─────
const sendFriendRequest = async () => {
  if (!friendRequestName.value.trim()) return;
  try {
    const { data } = await friendService.sendFriendRequest(friendRequestName.value.trim());
    showPopup(data.message, 'success');
    friendRequestName.value = '';
  } catch (e: any) {
    showPopup(e.response?.data?.message || 'Fehler beim Senden der Anfrage.', 'error');
  }
};

const acceptRequest = async (id: number) => {
  try {
    const { data } = await friendService.acceptRequest(id);
    showPopup(data.message || 'Anfrage angenommen!', 'success');
    await Promise.all([loadRequests(), loadFriends(), loadLeaderboard()]);
  } catch (e: any) {
    showPopup(e.response?.data?.message || 'Fehler beim Annehmen.', 'error');
  }
};

const declineRequest = async (id: number) => {
  try {
    const { data } = await friendService.declineRequest(id);
    showPopup(data.message || 'Anfrage abgelehnt.', 'success');
    await loadRequests();
  } catch (e: any) {
    showPopup(e.response?.data?.message || 'Fehler beim Ablehnen.', 'error');
  }
};

const removeFriend = async (id: number) => {
  if (!confirm('Freundschaft wirklich entfernen?')) return;
  try {
    const { data } = await friendService.removeFriend(id);
    showPopup(data.message || 'Freundschaft entfernt.', 'success');
    await Promise.all([loadFriends(), loadLeaderboard()]);
  } catch (e: any) {
    showPopup(e.response?.data?.message || 'Fehler beim Entfernen.', 'error');
  }
};

const openChallengeModal = (friendId: number) => {
  challengeForm.value = { opponentId: friendId, title: '', description: '', xpReward: 50, coinReward: 10, goalAmount: 100, durationHours: 24 };
  showChallengeModal.value = true;
};

const createChallenge = async () => {
  if (!challengeForm.value.title.trim()) {
    showPopup('Titel ist erforderlich.', 'error');
    return;
  }
  try {
    const { data } = await friendService.createChallenge(challengeForm.value);
    showPopup(data.message || 'Challenge gesendet!', 'success');
    showChallengeModal.value = false;
    await loadChallenges();
  } catch (e: any) {
    showPopup(e.response?.data?.message || 'Fehler beim Erstellen.', 'error');
  }
};

const acceptChallenge = async (id: number) => {
  try {
    const { data } = await friendService.acceptChallenge(id);
    showPopup(data.message || 'Challenge angenommen!', 'success');
    await loadChallenges();
  } catch (e: any) {
    showPopup(e.response?.data?.message || 'Fehler.', 'error');
  }
};

const declineChallenge = async (id: number) => {
  try {
    const { data } = await friendService.declineChallenge(id);
    showPopup(data.message || 'Challenge abgelehnt.', 'success');
    await loadChallenges();
  } catch (e: any) {
    showPopup(e.response?.data?.message || 'Fehler.', 'error');
  }
};

const openProgressModal = (ch: FriendChallengeDto) => {
  progressChallengeId.value = ch.id;
  progressAmount.value = 1;
  progressChallengeGoal.value = ch.goalAmount;
  progressChallengeCurrent.value = ch.challengerId === currentUserId.value
    ? ch.challengerProgress
    : ch.opponentProgress;
  showProgressModal.value = true;
};

const updateProgress = async () => {
  if (progressAmount.value < 1) {
    showPopup('Menge muss mindestens 1 sein.', 'error');
    return;
  }
  try {
    const { data } = await friendService.updateProgress(progressChallengeId.value, progressAmount.value);
    showPopup(data.message, 'success');
    showProgressModal.value = false;
    await loadChallenges();
    // Profil refreshen (Coins/XP könnten sich geändert haben)
    await refreshProfile();
  } catch (e: any) {
    showPopup(e.response?.data?.message || 'Fehler beim Aktualisieren.', 'error');
  }
};

// ───── Init ─────
onMounted(async () => {
  const raw = JSON.parse(localStorage.getItem('user') || '{}');
  currentUserName.value = raw.userName ?? raw.UserName ?? raw.username ?? '';
  currentUserId.value = raw.id ?? 0;

  try {
    await refreshProfile();
    const updated = JSON.parse(localStorage.getItem('user') || '{}');
    currentUserName.value = updated.userName ?? updated.UserName ?? updated.username ?? '';
    currentUserId.value = updated.id ?? 0;
  } catch (e) { /* ignore */ }

  await loadAll();
  onSignalREvent(handleSignalR);
});

onUnmounted(() => {
  offSignalREvent(handleSignalR);
});
</script>

<template>
  <div class="friends-page-shell">
    <Header />
    <Navbar />

    <main class="friends-page">
      <!-- Hero -->
      <section class="hero-card">
        <div class="hero-copy">
          <span class="hero-kicker">Freunde</span>
          <h1>Dein Netzwerk</h1>
          <p>Fordere deine Freunde heraus, sammle Belohnungen und klettere in der Freundes-Bestenliste nach oben!</p>
        </div>
        <div class="hero-stats">
          <article class="hero-stat-box">
            <span class="hero-stat-label">Freunde</span>
            <strong>{{ friends.length }}</strong>
          </article>
          <article class="hero-stat-box">
            <span class="hero-stat-label">Aktive Challenges</span>
            <strong>{{ activeChallenges.length }}</strong>
          </article>
          <article class="hero-stat-box">
            <span class="hero-stat-label">Anfragen</span>
            <strong>{{ pendingRequests.length }}</strong>
          </article>
        </div>
      </section>

      <!-- Tabs -->
      <div class="tab-bar">
        <button class="tab-btn" :class="{ active: activeTab === 'friends' }" @click="activeTab = 'friends'">
          <Users :size="16" /> Freunde
        </button>
        <button class="tab-btn" :class="{ active: activeTab === 'requests' }" @click="activeTab = 'requests'">
          <UserPlus :size="16" /> Anfragen
          <span v-if="pendingRequests.length" class="badge">{{ pendingRequests.length }}</span>
        </button>
        <button class="tab-btn" :class="{ active: activeTab === 'challenges' }" @click="activeTab = 'challenges'">
          <Swords :size="16" /> Challenges
        </button>
        <button class="tab-btn" :class="{ active: activeTab === 'leaderboard' }" @click="activeTab = 'leaderboard'">
          <Crown :size="16" /> Bestenliste
        </button>
      </div>

      <!-- Loading -->
      <div v-if="loading" class="state-box">Laden…</div>

      <!-- ═══ TAB: FREUNDE ═══ -->
      <template v-if="!loading && activeTab === 'friends'">
        <section class="section-card">
          <div class="section-heading">
            <div class="title-with-icon">
              <Users :size="20" />
              <h2>Meine Freunde</h2>
            </div>
          </div>

          <!-- Suche -->
          <div class="search-bar">
            <Search :size="18" />
            <input v-model="searchQuery" placeholder="Freund suchen…" />
          </div>

          <div v-if="filteredFriends.length" class="friends-list">
            <div v-for="f in filteredFriends" :key="f.id" class="friend-card">
              <div class="friend-avatar">{{ getInitials(f.friendUserName) }}</div>
              <div class="friend-info">
                <span class="friend-name">{{ f.friendUserName }}</span>
                <span class="friend-meta">Level {{ f.friendLevel }} · {{ f.friendExperience }} XP · {{ f.friendBodyStage }}</span>
                <span class="friend-since">Freunde seit {{ formatDate(f.friendsSince) }}</span>
              </div>
              <div class="friend-actions">
                <button class="action-btn challenge-btn" @click="openChallengeModal(f.friendId)" title="Herausfordern">
                  <Swords :size="16" />
                </button>
                <button class="action-btn remove-btn" @click="removeFriend(f.id)" title="Entfernen">
                  <Trash2 :size="16" />
                </button>
              </div>
            </div>
          </div>
          <div v-else class="empty-box">
            <Users :size="18" />
            {{ searchQuery ? 'Kein Freund gefunden.' : 'Noch keine Freunde. Sende eine Anfrage!' }}
          </div>
        </section>
      </template>

      <!-- ═══ TAB: ANFRAGEN ═══ -->
      <template v-if="!loading && activeTab === 'requests'">
        <section class="section-card">
          <div class="section-heading">
            <div class="title-with-icon">
              <Send :size="20" />
              <h2>Freund hinzufügen</h2>
            </div>
          </div>

          <div class="request-form">
            <input v-model="friendRequestName" placeholder="Benutzername eingeben…" @keyup.enter="sendFriendRequest" />
            <button class="primary-btn" @click="sendFriendRequest">
              <UserPlus :size="16" /> Anfrage senden
            </button>
          </div>
        </section>

        <section class="section-card" v-if="pendingRequests.length">
          <div class="section-heading">
            <div class="title-with-icon">
              <UserPlus :size="20" />
              <h2>Eingehende Anfragen</h2>
            </div>
          </div>

          <div class="requests-list">
            <div v-for="req in pendingRequests" :key="req.id" class="request-card">
              <div class="friend-avatar">{{ getInitials(req.fromUserName) }}</div>
              <div class="friend-info">
                <span class="friend-name">{{ req.fromUserName }}</span>
                <span class="friend-meta">Level {{ req.fromUserLevel }} · {{ formatDate(req.sentAt) }}</span>
              </div>
              <div class="friend-actions">
                <button class="action-btn accept-btn" @click="acceptRequest(req.id)">
                  <Check :size="16" />
                </button>
                <button class="action-btn decline-btn" @click="declineRequest(req.id)">
                  <X :size="16" />
                </button>
              </div>
            </div>
          </div>
        </section>
      </template>

      <!-- ═══ TAB: CHALLENGES ═══ -->
      <template v-if="!loading && activeTab === 'challenges'">
        <!-- Ausstehende Challenge-Einladungen -->
        <section v-if="pendingChallenges.length" class="section-card">
          <div class="section-heading">
            <div class="title-with-icon">
              <Shield :size="20" />
              <h2>Challenge-Einladungen</h2>
            </div>
          </div>

          <div class="challenges-list">
            <div v-for="ch in pendingChallenges" :key="ch.id" class="challenge-card">
              <div class="challenge-header">
                <h3>{{ ch.title }}</h3>
                <span class="status-badge" :style="{ background: statusColor(ch.status) }">{{ statusLabel(ch.status) }}</span>
              </div>
              <p v-if="ch.description" class="challenge-desc">{{ ch.description }}</p>
              <div class="challenge-meta">
                <span><Sparkles :size="14" /> {{ ch.xpReward }} XP</span>
                <span>🪙 {{ ch.coinReward }} Coins</span>
                <span>🎯 Ziel: {{ ch.goalAmount }}</span>
                <span><Clock :size="14" /> {{ timeRemaining(ch.expiresAt) }}</span>
              </div>
              <p class="challenge-from">Von: <strong>{{ ch.challengerUserName }}</strong></p>
              <div class="friend-actions" v-if="ch.opponentId === currentUserId">
                <button class="action-btn accept-btn" @click="acceptChallenge(ch.id)"><Check :size="16" /> Annehmen</button>
                <button class="action-btn decline-btn" @click="declineChallenge(ch.id)"><X :size="16" /> Ablehnen</button>
              </div>
            </div>
          </div>
        </section>

        <!-- Aktive Challenges -->
        <section class="section-card">
          <div class="section-heading">
            <div class="title-with-icon">
              <Swords :size="20" />
              <h2>Aktive Challenges</h2>
            </div>
          </div>

          <div v-if="activeChallenges.length" class="challenges-list">
            <div v-for="ch in activeChallenges" :key="ch.id" class="challenge-card">
              <div class="challenge-header">
                <h3>{{ ch.title }}</h3>
                <span class="status-badge" :style="{ background: statusColor(ch.status) }">{{ statusLabel(ch.status) }}</span>
              </div>
              <p v-if="ch.description" class="challenge-desc">{{ ch.description }}</p>
              <div class="challenge-meta">
                <span><Sparkles :size="14" /> {{ ch.xpReward }} XP</span>
                <span>🪙 {{ ch.coinReward }} Coins</span>
                <span>🎯 Ziel: {{ ch.goalAmount }}</span>
                <span><Clock :size="14" /> {{ timeRemaining(ch.expiresAt) }}</span>
              </div>

              <!-- Fortschrittsbalken -->
              <div class="progress-section">
                <div class="progress-row">
                  <span class="progress-name">{{ ch.challengerUserName }}</span>
                  <div class="progress-bar-track">
                    <div class="progress-bar-fill challenger" :style="{ width: progressPercent(ch.challengerProgress, ch.goalAmount) + '%' }"></div>
                  </div>
                  <span class="progress-pct">{{ ch.challengerProgress }}/{{ ch.goalAmount }}</span>
                </div>
                <div class="progress-row">
                  <span class="progress-name">{{ ch.opponentUserName }}</span>
                  <div class="progress-bar-track">
                    <div class="progress-bar-fill opponent" :style="{ width: progressPercent(ch.opponentProgress, ch.goalAmount) + '%' }"></div>
                  </div>
                  <span class="progress-pct">{{ ch.opponentProgress }}/{{ ch.goalAmount }}</span>
                </div>
              </div>

              <button class="primary-btn sm" @click="openProgressModal(ch)">
                <Plus :size="16" /> Fortschritt melden
              </button>
            </div>
          </div>
          <div v-else class="empty-box">
            <Swords :size="18" /> Keine aktiven Challenges. Fordere einen Freund heraus!
          </div>
        </section>

        <!-- Vergangene Challenges -->
        <section v-if="completedChallenges.length" class="section-card">
          <div class="section-heading">
            <div class="title-with-icon">
              <Trophy :size="20" />
              <h2>Vergangene Challenges</h2>
            </div>
          </div>
          <div class="challenges-list">
            <div v-for="ch in completedChallenges" :key="ch.id" class="challenge-card past">
              <div class="challenge-header">
                <h3>{{ ch.title }}</h3>
                <span class="status-badge" :style="{ background: statusColor(ch.status) }">{{ statusLabel(ch.status) }}</span>
              </div>
              <div class="challenge-meta">
                <span>{{ ch.challengerUserName }} vs {{ ch.opponentUserName }}</span>
                <span v-if="ch.winnerUserName">🏆 Gewinner: <strong>{{ ch.winnerUserName }}</strong></span>
                <span v-if="ch.completedAt">{{ formatDate(ch.completedAt) }}</span>
              </div>
              <div class="progress-section">
                <div class="progress-row">
                  <span class="progress-name">{{ ch.challengerUserName }}</span>
                  <div class="progress-bar-track">
                    <div class="progress-bar-fill challenger" :style="{ width: progressPercent(ch.challengerProgress, ch.goalAmount) + '%' }"></div>
                  </div>
                  <span class="progress-pct">{{ ch.challengerProgress }}/{{ ch.goalAmount }}</span>
                </div>
                <div class="progress-row">
                  <span class="progress-name">{{ ch.opponentUserName }}</span>
                  <div class="progress-bar-track">
                    <div class="progress-bar-fill opponent" :style="{ width: progressPercent(ch.opponentProgress, ch.goalAmount) + '%' }"></div>
                  </div>
                  <span class="progress-pct">{{ ch.opponentProgress }}/{{ ch.goalAmount }}</span>
                </div>
              </div>
            </div>
          </div>
        </section>
      </template>

      <!-- ═══ TAB: BESTENLISTE ═══ -->
      <template v-if="!loading && activeTab === 'leaderboard'">
        <section class="section-card">
          <div class="section-heading">
            <div class="title-with-icon">
              <Crown :size="20" />
              <h2>Freundes-Bestenliste</h2>
            </div>
            <p>Ranking unter deinen Freunden nach Erfahrungspunkten.</p>
          </div>

          <div v-if="leaderboardEntries.length" class="leaderboard-list">
            <LeaderboardRow
              v-for="player in leaderboardEntries"
              :key="player.Id"
              :player="player"
            />
          </div>
          <div v-else class="empty-box">
            <Crown :size="18" /> Füge Freunde hinzu, um die Bestenliste zu sehen.
          </div>
        </section>
      </template>
    </main>

    <!-- ───── MODAL: Challenge erstellen ───── -->
    <Teleport to="body">
      <div v-if="showChallengeModal" class="modal-overlay" @click.self="showChallengeModal = false">
        <div class="modal-card">
          <h2>⚔️ Challenge erstellen</h2>
          <div class="form-group">
            <label>Titel</label>
            <input v-model="challengeForm.title" placeholder="z.B. 100 Liegestütze in 24h" />
          </div>
          <div class="form-group">
            <label>Beschreibung (optional)</label>
            <textarea v-model="challengeForm.description" rows="2" placeholder="Was muss gemacht werden?"></textarea>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>XP Belohnung</label>
              <input type="number" v-model.number="challengeForm.xpReward" min="1" max="500" />
            </div>
            <div class="form-group">
              <label>Coin Belohnung</label>
              <input type="number" v-model.number="challengeForm.coinReward" min="0" max="100" />
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Ziel (Anzahl)</label>
              <input type="number" v-model.number="challengeForm.goalAmount" min="1" max="10000" placeholder="z.B. 100" />
            </div>
            <div class="form-group">
              <label>Dauer (Stunden)</label>
              <input type="number" v-model.number="challengeForm.durationHours" min="1" max="168" />
            </div>
          </div>
          <div class="modal-actions">
            <button class="secondary-btn" @click="showChallengeModal = false">Abbrechen</button>
            <button class="primary-btn" @click="createChallenge"><Swords :size="16" /> Challenge senden</button>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- ───── MODAL: Fortschritt melden ───── -->
    <Teleport to="body">
      <div v-if="showProgressModal" class="modal-overlay" @click.self="showProgressModal = false">
        <div class="modal-card">
          <h2>📊 Fortschritt melden</h2>
          <p class="modal-progress-info">Aktuell: <strong>{{ progressChallengeCurrent }}</strong> / {{ progressChallengeGoal }}</p>
          <div class="form-group">
            <label>Wie viel hast du geschafft?</label>
            <input type="number" v-model.number="progressAmount" min="1" :max="progressChallengeGoal" placeholder="z.B. 25" />
          </div>
          <div class="modal-actions">
            <button class="secondary-btn" @click="showProgressModal = false">Abbrechen</button>
            <button class="primary-btn" @click="updateProgress"><Plus :size="16" /> Eintragen</button>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- MessagePopup -->
    <Teleport to="body">
      <MessagePopup
        v-if="popupMessage"
        :message="popupMessage"
        :type="popupType"
        @close="popupMessage = ''"
      />
    </Teleport>

    <FooterComponent />
  </div>
</template>

<style scoped>
.friends-page-shell {
  min-height: 100vh;
  color: white;
}

.friends-page {
  width: min(1280px, calc(100% - 32px));
  margin: 0 auto;
  padding: 32px 0 48px;
  display: grid;
  gap: 24px;
}

/* ───── Hero ───── */
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
  grid-template-columns: minmax(0, 1.3fr) minmax(280px, 0.9fr);
  gap: 24px;
  padding: clamp(24px, 3vw, 36px);
  background: linear-gradient(135deg, #8b5cf6, #6366f1);
}

.hero-kicker {
  display: inline-flex;
  border-radius: 999px;
  padding: 7px 12px;
  background: rgba(255, 255, 255, 0.14);
  color: #e0e7ff;
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

/* ───── Tabs ───── */
.tab-bar {
  display: flex;
  gap: 8px;
  overflow-x: auto;
  padding: 4px 0;
}

.tab-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  background: rgba(15, 23, 42, 0.5);
  color: #94a3b8;
  font-weight: 600;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.tab-btn:hover {
  background: rgba(99, 102, 241, 0.15);
  border-color: rgba(99, 102, 241, 0.3);
  color: white;
}

.tab-btn.active {
  background: linear-gradient(135deg, #8b5cf6, #6366f1);
  border-color: transparent;
  color: white;
}

.badge {
  background: #ef4444;
  color: white;
  border-radius: 999px;
  padding: 2px 8px;
  font-size: 0.75rem;
  font-weight: 700;
}

/* ───── Section Card ───── */
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
  color: #a78bfa;
}

/* ───── Search ───── */
.search-bar {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.1);
  margin-bottom: 18px;
}

.search-bar svg { color: #64748b; }

.search-bar input {
  flex: 1;
  border: none;
  background: none;
  color: white;
  font-size: 0.95rem;
  outline: none;
}

.search-bar input::placeholder { color: #64748b; }

/* ───── Friend Cards ───── */
.friends-list, .requests-list, .challenges-list {
  display: grid;
  gap: 12px;
}

.friend-card, .request-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 20px;
  border-radius: 18px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.06);
  transition: all 0.2s;
}

.friend-card:hover, .request-card:hover {
  background: rgba(255, 255, 255, 0.07);
  border-color: rgba(139, 92, 246, 0.2);
}

.friend-avatar {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: linear-gradient(135deg, #8b5cf6, #6366f1);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 0.9rem;
  flex-shrink: 0;
}

.friend-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.friend-name {
  font-weight: 700;
  font-size: 1rem;
}

.friend-meta {
  color: #94a3b8;
  font-size: 0.85rem;
}

.friend-since {
  color: #64748b;
  font-size: 0.78rem;
}

.friend-actions {
  display: flex;
  gap: 8px;
}

.action-btn {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 10px 14px;
  border-radius: 14px;
  border: none;
  font-weight: 600;
  font-size: 0.85rem;
  cursor: pointer;
  transition: all 0.2s;
  color: white;
}

.challenge-btn { background: rgba(139, 92, 246, 0.2); }
.challenge-btn:hover { background: rgba(139, 92, 246, 0.4); }
.accept-btn { background: rgba(34, 197, 94, 0.2); }
.accept-btn:hover { background: rgba(34, 197, 94, 0.4); }
.decline-btn { background: rgba(239, 68, 68, 0.2); }
.decline-btn:hover { background: rgba(239, 68, 68, 0.4); }
.remove-btn { background: rgba(239, 68, 68, 0.1); }
.remove-btn:hover { background: rgba(239, 68, 68, 0.25); }

/* ───── Challenge Cards ───── */
.challenge-card {
  padding: 20px;
  border-radius: 18px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.06);
}

.challenge-card.past {
  opacity: 0.7;
}

.challenge-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 8px;
}

.challenge-header h3 {
  margin: 0;
  font-size: 1.05rem;
}

.status-badge {
  padding: 4px 12px;
  border-radius: 999px;
  font-size: 0.75rem;
  font-weight: 700;
  color: white;
}

.challenge-desc {
  color: #94a3b8;
  font-size: 0.9rem;
  margin: 0 0 12px;
}

.challenge-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 16px;
  color: #94a3b8;
  font-size: 0.85rem;
  margin-bottom: 12px;
}

.challenge-meta span {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.challenge-from {
  color: #cbd5e1;
  font-size: 0.9rem;
  margin: 0 0 12px;
}

/* ───── Progress Bars ───── */
.progress-section {
  display: grid;
  gap: 10px;
  margin-bottom: 14px;
}

.progress-row {
  display: grid;
  grid-template-columns: 120px 1fr 50px;
  align-items: center;
  gap: 12px;
}

.progress-name {
  font-size: 0.85rem;
  font-weight: 600;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.progress-bar-track {
  height: 10px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.08);
  overflow: hidden;
}

.progress-bar-fill {
  height: 100%;
  border-radius: 999px;
  transition: width 0.4s ease;
}

.progress-bar-fill.challenger {
  background: linear-gradient(90deg, #8b5cf6, #a78bfa);
}

.progress-bar-fill.opponent {
  background: linear-gradient(90deg, #ec4899, #f472b6);
}

.progress-pct {
  font-size: 0.8rem;
  color: #94a3b8;
  text-align: right;
}

/* ───── Request Form ───── */
.request-form {
  display: flex;
  gap: 12px;
  margin-bottom: 12px;
}

.request-form input {
  flex: 1;
  padding: 12px 16px;
  border-radius: 14px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(255, 255, 255, 0.06);
  color: white;
  font-size: 0.95rem;
  outline: none;
}

.request-form input::placeholder { color: #64748b; }

.request-form input:focus {
  border-color: rgba(139, 92, 246, 0.4);
}

/* ───── Buttons ───── */
.primary-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  border-radius: 14px;
  border: none;
  background: linear-gradient(135deg, #8b5cf6, #6366f1);
  color: white;
  font-weight: 700;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.2s;
}

.primary-btn:hover { opacity: 0.85; transform: translateY(-1px); }
.primary-btn.sm { padding: 8px 16px; font-size: 0.85rem; }

.secondary-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  border-radius: 14px;
  border: 1px solid rgba(255, 255, 255, 0.15);
  background: transparent;
  color: #cbd5e1;
  font-weight: 600;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.2s;
}

.secondary-btn:hover { background: rgba(255, 255, 255, 0.06); }

/* ───── Leaderboard ───── */
.leaderboard-list {
  display: grid;
  gap: 14px;
}

/* ───── Empty / State ───── */
.state-box, .empty-box {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  padding: 26px;
  color: #94a3b8;
}

.modal-progress-info {
  color: #cbd5e1;
  font-size: 0.95rem;
  margin: 0 0 16px;
}

.modal-progress-info strong {
  color: #a78bfa;
}

/* ───── Modals ───── */
.modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 1000;
  background: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(6px);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.modal-card {
  background: #1e293b;
  border-radius: 24px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  padding: 28px;
  width: min(520px, 100%);
  max-height: 90vh;
  overflow-y: auto;
}

.modal-card h2 {
  margin: 0 0 20px;
  font-size: 1.3rem;
}

.form-group {
  margin-bottom: 16px;
}

.form-group label {
  display: block;
  color: #cbd5e1;
  font-size: 0.85rem;
  font-weight: 600;
  margin-bottom: 6px;
}

.form-group input,
.form-group textarea {
  width: 100%;
  padding: 12px 14px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(255, 255, 255, 0.06);
  color: white;
  font-size: 0.95rem;
  outline: none;
  box-sizing: border-box;
}

.form-group input:focus,
.form-group textarea:focus {
  border-color: rgba(139, 92, 246, 0.4);
}

.form-group input[type="range"] {
  padding: 4px 0;
  background: transparent;
  border: none;
}

.range-value {
  display: block;
  text-align: center;
  font-size: 1.2rem;
  font-weight: 700;
  color: #a78bfa;
  margin-top: 6px;
}

.form-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  margin-top: 20px;
}

/* ───── Responsive ───── */
@media (max-width: 1080px) {
  .hero-card { grid-template-columns: 1fr; }
}

@media (max-width: 860px) {
  .friends-page {
    width: min(100%, calc(100% - 24px));
    padding-top: 24px;
  }
  .hero-stats { grid-template-columns: 1fr; }
  .form-row { grid-template-columns: 1fr; }
  .progress-row { grid-template-columns: 80px 1fr 40px; }
}

@media (max-width: 560px) {
  .friends-page {
    width: min(100%, calc(100% - 16px));
    gap: 18px;
  }
  .hero-card, .section-card, .state-box, .empty-box { border-radius: 22px; }
  .tab-bar { gap: 4px; }
  .tab-btn { padding: 10px 14px; font-size: 0.82rem; }
  .friend-card, .request-card { flex-direction: column; text-align: center; }
  .friend-actions { justify-content: center; }
  .request-form { flex-direction: column; }
  .challenge-header { flex-direction: column; align-items: flex-start; }
}
</style>
