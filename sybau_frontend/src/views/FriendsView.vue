<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import {
  Users, UserPlus, Swords, Trophy, Check, X,
  Search, Clock, Sparkles, Trash2, Plus
} from 'lucide-vue-next';
import Navbar from '@/components/Navbar.vue';
import Header from '@/components/Header.vue';
import FooterComponent from '@/components/FooterComponent.vue';
import MessagePopup from '@/components/MessagePopup.vue';
import PublicProfileSheet from '@/components/PublicProfileSheet.vue';
import { friendService, resolveMediaUrl, userService } from '@/services/api';
import { useAuth } from '@/composables/useAuth';
import { useNotifications } from '@/composables/useNotifications';
import type { FriendshipDto, FriendRequestDto, SentFriendRequestDto, FriendChallengeDto, CreateFriendChallengeDto } from '@/models/Friend';

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
const activeTab = ref<'friends' | 'requests' | 'challenges'>('friends');
const loading = ref(false);

const friends = ref<FriendshipDto[]>([]);
const pendingRequests = ref<FriendRequestDto[]>([]);
const sentRequests = ref<SentFriendRequestDto[]>([]);
const challenges = ref<FriendChallengeDto[]>([]);
const userDirectory = ref<any[]>([]);

const searchQuery = ref('');

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
const viewedProfileId = ref<number | null>(null);
const showProfileSheet = ref(false);
const brokenProfileImages = ref<Set<string>>(new Set());

// ───── Computed ─────
const friendNames = computed(() => new Set(
  friends.value.map((friend) => friend.friendUserName.toLowerCase()).filter(Boolean)
));

const sentRequestNames = computed(() => new Set(
  sentRequests.value.map((request) => request.toUserName.toLowerCase()).filter(Boolean)
));

const searchResults = computed(() => {
  const query = searchQuery.value.trim().toLowerCase();
  if (!query) return [];
  return userDirectory.value
    .filter((user) => {
      const userName = String(user.userName ?? user.UserName ?? user.username ?? '').toLowerCase();
      return userName.includes(query) && userName !== currentUserName.value.toLowerCase() && !friendNames.value.has(userName);
    })
    .slice(0, 8);
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

// ───── Helpers ─────
const getInitials = (name: string) =>
  name.split(/\s+/).filter(Boolean).slice(0, 2).map(p => p[0]?.toUpperCase() ?? '').join('') || 'SB';

const getUserName = (user: any) => String(user.userName ?? user.UserName ?? user.username ?? '');
const getUserId = (user: any) => Number(user.id ?? user.Id ?? 0);
const getUserLevel = (user: any) => Number(user.level ?? user.Level ?? 0);
const getUserXp = (user: any) => Number(user.totalXp ?? user.TotalXp ?? user.experience ?? user.Experience ?? 0);
const getRawProfileImage = (value: any) =>
  String(value?.profileImageUrl ?? value?.ProfileImageUrl ?? value?.profileImageURL ?? value?.ProfileImageURL ?? '');
const getUserImage = (user: any) => resolveMediaUrl(getRawProfileImage(user));
const getFriendId = (friend: any) => Number(friend.friendId ?? friend.FriendId ?? 0);
const getFriendName = (friend: any) => String(friend.friendUserName ?? friend.FriendUserName ?? '');
const getFriendLevel = (friend: any) => Number(friend.friendLevel ?? friend.FriendLevel ?? 0);
const getFriendXp = (friend: any) => Number(friend.friendExperience ?? friend.FriendExperience ?? friend.totalXp ?? friend.TotalXp ?? 0);
const getFriendImage = (friend: any) => {
  const direct = String(
    friend.friendProfileImageUrl ??
    friend.FriendProfileImageUrl ??
    friend.profileImageUrl ??
    friend.ProfileImageUrl ??
    '',
  );
  if (direct) return resolveMediaUrl(direct);

  const friendId = getFriendId(friend);
  const directoryUser = userDirectory.value.find((user) => getUserId(user) === friendId);
  return getUserImage(directoryUser);
};
const getRequestImage = (request: any, direction: 'from' | 'to') => {
  if (direction === 'from') return resolveMediaUrl(request.fromUserProfileImageUrl ?? request.FromUserProfileImageUrl ?? '');
  return resolveMediaUrl(request.toUserProfileImageUrl ?? request.ToUserProfileImageUrl ?? '');
};

const openUserProfile = (userId: number) => {
  if (!userId) return;
  viewedProfileId.value = userId;
  showProfileSheet.value = true;
};

const markProfileImageBroken = (key: string) => {
  brokenProfileImages.value = new Set([...brokenProfileImages.value, key]);
};

const canShowProfileImage = (key: string, url: string) => Boolean(url) && !brokenProfileImages.value.has(key);

const formatCompact = (value: number) => {
  if (Math.abs(value) < 10000) return value.toLocaleString('de-DE');
  const units = [
    { amount: 1_000_000_000, suffix: 'B' },
    { amount: 1_000_000, suffix: 'M' },
    { amount: 1_000, suffix: 'K' },
  ];
  const unit = units.find((item) => Math.abs(value) >= item.amount);
  if (!unit) return value.toLocaleString('de-DE');
  const compact = value / unit.amount;
  const digits = compact >= 100 || Number.isInteger(compact) ? 0 : 1;
  return `${compact.toFixed(digits).replace('.', ',')}${unit.suffix}`;
};

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
    case 'Completed': return '#ec4899';
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
    const enriched = await Promise.all(
      data.map(async (friend: any) => {
        try {
          const friendId = getFriendId(friend);
          const { data: profile } = await userService.getPublicProfile(friendId);
          return {
            ...friend,
            friendId,
            friendUserName: getFriendName(friend),
            friendProfileImageUrl: getRawProfileImage(profile) || friend.friendProfileImageUrl,
            FriendProfileImageUrl: getRawProfileImage(profile) || friend.FriendProfileImageUrl,
          };
        } catch {
          return friend;
        }
      }),
    );
    friends.value = enriched;
  } catch (e) { console.error('Fehler beim Laden der Freunde', e); }
};

const loadRequests = async () => {
  try {
    const { data } = await friendService.getPendingRequests();
    pendingRequests.value = data;
  } catch (e) { console.error('Fehler beim Laden der Anfragen', e); }
};

const loadSentRequests = async () => {
  try {
    const { data } = await friendService.getSentRequests();
    sentRequests.value = data;
  } catch (e) { console.error('Fehler beim Laden der gesendeten Anfragen', e); }
};

const loadChallenges = async () => {
  try {
    const { data } = await friendService.getChallenges();
    challenges.value = data;
  } catch (e) { console.error('Fehler beim Laden der Challenges', e); }
};

const loadUserDirectory = async () => {
  try {
    const { data } = await userService.getLeaderboard();
    userDirectory.value = Array.isArray(data) ? data : [];
  } catch (e) { console.error('Fehler beim Laden der Nutzersuche', e); }
};

const loadAll = async () => {
  loading.value = true;
  await Promise.all([loadFriends(), loadRequests(), loadSentRequests(), loadChallenges(), loadUserDirectory()]);
  loading.value = false;
};

// ───── Actions ─────
const sendFriendRequest = async (userName = searchQuery.value.trim()) => {
  if (!userName.trim()) return;
  try {
    const { data } = await friendService.sendFriendRequest(userName.trim());
    showPopup(data.message, 'success');
    await loadSentRequests();
  } catch (e: any) {
    showPopup(e.response?.data?.message || 'Fehler beim Senden der Anfrage.', 'error');
  }
};

const acceptRequest = async (id: number) => {
  try {
    const { data } = await friendService.acceptRequest(id);
    showPopup(data.message || 'Anfrage angenommen!', 'success');
    await Promise.all([loadRequests(), loadFriends(), loadUserDirectory()]);
  } catch (e: any) {
    showPopup(e.response?.data?.message || 'Fehler beim Annehmen.', 'error');
  }
};

const declineRequest = async (id: number) => {
  try {
    const { data } = await friendService.declineRequest(id);
    showPopup(data.message || 'Anfrage abgelehnt.', 'success');
    await Promise.all([loadRequests(), loadUserDirectory()]);
  } catch (e: any) {
    showPopup(e.response?.data?.message || 'Fehler beim Ablehnen.', 'error');
  }
};

const removeFriend = async (id: number) => {
  if (!confirm('Freundschaft wirklich entfernen?')) return;
  try {
    const { data } = await friendService.removeFriend(id);
    showPopup(data.message || 'Freundschaft entfernt.', 'success');
    await Promise.all([loadFriends(), loadUserDirectory()]);
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
          <Trophy :size="16" /> Challenges
        </button>
      </div>

      <!-- Loading -->
      <div v-if="loading" class="state-box">Laden…</div>

      <!-- ═══ TAB: FREUNDE ═══ -->
      <template v-if="!loading && activeTab === 'friends'">
        <section class="section-card">
          <h2 class="mobile-section-title">Freunde finden</h2>

          <div class="search-bar">
            <Search :size="18" />
            <input v-model="searchQuery" placeholder="Benutzername suchen..." />
          </div>

          <p v-if="searchQuery.trim() && !searchResults.length" class="inline-empty">Keine passenden Nutzer gefunden.</p>

          <div v-if="searchResults.length" class="friends-list search-results">
            <div v-for="user in searchResults" :key="getUserName(user)" class="friend-card">
              <div class="friend-avatar">
                <button class="avatar-button" type="button" @click="openUserProfile(getUserId(user))">
                  <img
                    v-if="canShowProfileImage(`search-${getUserId(user)}`, getUserImage(user))"
                    :src="getUserImage(user)"
                    alt=""
                    @error="markProfileImageBroken(`search-${getUserId(user)}`)"
                  />
                  <span v-else>{{ getInitials(getUserName(user)) }}</span>
                </button>
              </div>
              <div class="friend-info">
                <span class="friend-name">{{ getUserName(user) }}</span>
                <span class="friend-meta">Lv {{ getUserLevel(user) }} · {{ formatCompact(getUserXp(user)) }} XP</span>
              </div>
              <div class="friend-actions">
                <button
                  v-if="sentRequestNames.has(getUserName(user).toLowerCase())"
                  class="sent-pill"
                  disabled
                >
                  Sent
                </button>
                <button v-else class="send-request-btn" @click="sendFriendRequest(getUserName(user))">
                  Senden
                </button>
              </div>
            </div>
          </div>
        </section>

        <section class="section-card">
          <h2 class="mobile-section-title">Friends</h2>

          <div v-if="friends.length" class="friends-list">
            <div v-for="f in friends" :key="f.id" class="friend-card">
              <div class="friend-avatar">
                <button class="avatar-button" type="button" @click="openUserProfile(getFriendId(f))">
                  <img
                    v-if="canShowProfileImage(`friend-${getFriendId(f)}`, getFriendImage(f))"
                    :src="getFriendImage(f)"
                    alt=""
                    @error="markProfileImageBroken(`friend-${getFriendId(f)}`)"
                  />
                  <span v-else>{{ getInitials(getFriendName(f)) }}</span>
                </button>
              </div>
              <div class="friend-info">
                <span class="friend-name">{{ getFriendName(f) }}</span>
                <span class="friend-meta">Lv {{ getFriendLevel(f) }} · {{ formatCompact(getFriendXp(f)) }} XP</span>
              </div>
              <div class="friend-actions">
                <button class="icon-action-btn challenge-btn" @click="openChallengeModal(getFriendId(f))" title="Herausfordern">
                  <Trophy :size="18" />
                </button>
                <button class="icon-action-btn remove-btn" @click="removeFriend(f.id)" title="Entfernen">
                  <Trash2 :size="18" />
                </button>
              </div>
            </div>
          </div>
          <div v-else class="empty-box">
            <Users :size="18" />
            Noch keine Freunde.
          </div>
        </section>
      </template>

      <!-- ═══ TAB: ANFRAGEN ═══ -->
      <template v-if="!loading && activeTab === 'requests'">
        <section class="section-card">
          <h2 class="mobile-section-title">Eingehende Anfragen</h2>

          <div v-if="pendingRequests.length" class="requests-list">
            <div v-for="req in pendingRequests" :key="req.id" class="request-card">
              <div class="friend-avatar">
                <button class="avatar-button" type="button" @click="openUserProfile(req.fromUserId)">
                  <img
                    v-if="canShowProfileImage(`from-${req.fromUserId}`, getRequestImage(req, 'from'))"
                    :src="getRequestImage(req, 'from')"
                    alt=""
                    @error="markProfileImageBroken(`from-${req.fromUserId}`)"
                  />
                  <span v-else>{{ getInitials(req.fromUserName) }}</span>
                </button>
              </div>
              <div class="friend-info">
                <span class="friend-name">{{ req.fromUserName }}</span>
                <span class="friend-meta">Level {{ req.fromUserLevel }}</span>
              </div>
              <div class="friend-actions">
                <button class="text-action-btn accept-btn" @click="acceptRequest(req.id)">Accept</button>
                <button class="text-action-btn decline-btn" @click="declineRequest(req.id)">Decline</button>
              </div>
            </div>
          </div>
          <p v-else class="inline-empty">Keine offenen Anfragen.</p>
        </section>

        <section class="section-card">
          <h2 class="mobile-section-title">Gesendet</h2>

          <div v-if="sentRequests.length" class="requests-list">
            <div v-for="req in sentRequests" :key="req.id" class="request-card">
              <div class="friend-avatar">
                <button class="avatar-button" type="button" @click="openUserProfile(req.toUserId)">
                  <img
                    v-if="canShowProfileImage(`to-${req.toUserId}`, getRequestImage(req, 'to'))"
                    :src="getRequestImage(req, 'to')"
                    alt=""
                    @error="markProfileImageBroken(`to-${req.toUserId}`)"
                  />
                  <span v-else>{{ getInitials(req.toUserName) }}</span>
                </button>
              </div>
              <div class="friend-info">
                <span class="friend-name">{{ req.toUserName }}</span>
                <span class="friend-meta">Sent</span>
              </div>
            </div>
          </div>
          <p v-else class="inline-empty">Keine gesendeten offenen Anfragen.</p>
        </section>
      </template>

      <!-- ═══ TAB: CHALLENGES ═══ -->
      <template v-if="!loading && activeTab === 'challenges'">
        <!-- Ausstehende Challenge-Einladungen -->
        <section v-if="pendingChallenges.length" class="section-card">
          <div class="section-heading">
            <h2 class="mobile-section-title">Challenge-Einladungen</h2>
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
            <h2 class="mobile-section-title">Aktive Challenges</h2>
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
            <h2 class="mobile-section-title">Vergangene Challenges</h2>
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
    <PublicProfileSheet
      :visible="showProfileSheet"
      :user-id="viewedProfileId"
      @close="showProfileSheet = false"
    />
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
  padding: 24px 0 48px;
  display: grid;
  gap: 14px;
}

.section-card,
.state-box,
.empty-box {
  border-radius: 18px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(15, 23, 42, 0.44);
  backdrop-filter: blur(18px);
  -webkit-backdrop-filter: blur(18px);
  box-shadow: none;
}

/* ───── Tabs ───── */
.tab-bar {
  display: flex;
  gap: 8px;
  overflow-x: auto;
  padding: 4px 0 10px;
}

.tab-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 10px 16px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.05);
  color: rgba(255, 255, 255, 0.7);
  font-weight: 800;
  font-size: 0.9rem;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.tab-btn:hover {
  background: rgba(236, 72, 153, 0.12);
  border-color: rgba(236, 72, 153, 0.26);
  color: white;
}

.tab-btn.active {
  background: rgba(236, 72, 153, 0.26);
  border-color: rgba(236, 72, 153, 0.55);
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
  padding: 22px;
}

.mobile-section-title {
  margin: 0 0 18px;
  color: white;
  font-size: 1.35rem;
  font-weight: 800;
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
  color: #f9a8d4;
}

/* ───── Search ───── */
.search-bar {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.1);
  margin-bottom: 10px;
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
  gap: 10px;
}

.search-results {
  margin-top: 8px;
}

.friend-card, .request-card {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px;
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.08);
  transition: all 0.2s;
}

.friend-card:hover, .request-card:hover {
  background: rgba(255, 255, 255, 0.07);
  border-color: rgba(236, 72, 153, 0.2);
}

.friend-avatar {
  width: 46px;
  height: 46px;
  border-radius: 50%;
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 0.9rem;
  flex-shrink: 0;
  overflow: hidden;
}

.avatar-button {
  width: 100%;
  height: 100%;
  display: grid;
  place-items: center;
  padding: 0;
  border: 0;
  border-radius: inherit;
  color: inherit;
  background: transparent;
  font: inherit;
  cursor: pointer;
  overflow: hidden;
}

.avatar-button:focus-visible {
  outline: 2px solid rgba(236, 72, 153, 0.65);
  outline-offset: 2px;
}

.friend-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.friend-info {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 3px;
}

.friend-name {
  font-weight: 800;
  font-size: 1rem;
}

.friend-meta {
  color: rgba(255, 255, 255, 0.58);
  font-size: 0.78rem;
}

.friend-actions {
  display: flex;
  gap: 8px;
}

.action-btn,
.icon-action-btn,
.text-action-btn,
.send-request-btn,
.sent-pill {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  min-height: 38px;
  padding: 9px 12px;
  border-radius: 14px;
  border: none;
  font-weight: 800;
  font-size: 0.85rem;
  cursor: pointer;
  transition: all 0.2s;
  color: white;
}

.icon-action-btn {
  width: 38px;
  padding: 0;
}

.send-request-btn {
  min-width: 86px;
  background: linear-gradient(135deg, #ec4899, #f43f5e);
}

.sent-pill {
  min-width: 72px;
  color: white;
  background: rgba(148, 163, 184, 0.22);
  cursor: default;
}

.challenge-btn { background: rgba(236, 72, 153, 0.16); }
.challenge-btn:hover { background: rgba(236, 72, 153, 0.28); }
.accept-btn { background: rgba(34, 197, 94, 0.18); }
.accept-btn:hover { background: rgba(34, 197, 94, 0.4); }
.decline-btn { background: rgba(239, 68, 68, 0.18); }
.decline-btn:hover { background: rgba(239, 68, 68, 0.4); }
.remove-btn { background: rgba(239, 68, 68, 0.1); }
.remove-btn:hover { background: rgba(239, 68, 68, 0.25); }

.inline-empty {
  margin: 0;
  color: rgba(255, 255, 255, 0.62);
  font-size: 0.86rem;
}

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
  background: linear-gradient(90deg, #ec4899, #f9a8d4);
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
/* ───── Buttons ───── */
.primary-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 12px 20px;
  border-radius: 14px;
  border: none;
  background: linear-gradient(135deg, #ec4899, #f43f5e);
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
  color: #f9a8d4;
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
  border-color: rgba(236, 72, 153, 0.42);
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
  color: #f9a8d4;
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
@media (max-width: 860px) {
  .friends-page {
    width: min(100%, calc(100% - 24px));
    padding-top: 24px;
  }
  .form-row { grid-template-columns: 1fr; }
  .progress-row { grid-template-columns: 80px 1fr 40px; }
}

@media (max-width: 560px) {
  .friends-page {
    width: min(100%, calc(100% - 16px));
    gap: 18px;
  }
  .section-card, .state-box, .empty-box { border-radius: 18px; }
  .tab-bar { gap: 4px; }
  .tab-btn { padding: 10px 14px; font-size: 0.82rem; }
  .friend-card, .request-card { align-items: center; }
  .friend-actions { justify-content: center; }
  .challenge-header { flex-direction: column; align-items: flex-start; }
}
</style>
