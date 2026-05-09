<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import {
  Users, UserPlus, Swords, Trophy, Check, X,
  Search, Clock, Trash2, Plus, Target
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
  goalAmount: 100,
  goalUnit: 'reps',
  distanceUnit: 'm',
  durationHours: 24,
});

// Progress Modal
const showProgressModal = ref(false);
const progressChallengeId = ref(0);
const progressAmount = ref(1);
const progressChallengeGoal = ref(100);
const progressChallengeCurrent = ref(0);
const progressChallengeUnit = ref<CreateFriendChallengeDto['goalUnit']>('reps');

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

const canDeleteChallenge = (status: string) =>
  status === 'Completed' || status === 'Expired';

const goalUnitLabel = (unit: FriendChallengeDto['goalUnit'] | CreateFriendChallengeDto['goalUnit']) => {
  switch (unit) {
    case 'time': return 'Sekunden';
    case 'distance': return 'Meter';
    default: return 'Reps';
  }
};

const goalUnitShort = (unit: FriendChallengeDto['goalUnit'] | CreateFriendChallengeDto['goalUnit']) => {
  switch (unit) {
    case 'time': return 'Sek';
    case 'distance': return 'm';
    default: return 'Reps';
  }
};

const formatGoalInput = (value: number, unit: CreateFriendChallengeDto['goalUnit']) => {
  if (unit !== 'time') return String(value || '');
  const totalSeconds = Math.max(0, Math.floor(value || 0));
  const hours = Math.floor(totalSeconds / 3600).toString().padStart(2, '0');
  const minutes = Math.floor((totalSeconds % 3600) / 60).toString().padStart(2, '0');
  const seconds = (totalSeconds % 60).toString().padStart(2, '0');
  return `${hours}:${minutes}:${seconds}`;
};

const parseGoalInput = (value: string, unit: CreateFriendChallengeDto['goalUnit']) => {
  if (unit !== 'time') {
    return Number(value.replace(/[^\d]/g, '')) || 0;
  }

  const parts = value.split(':').map((part) => Number(part) || 0);
  if (parts.length === 3) return (parts[0] * 3600) + (parts[1] * 60) + parts[2];
  if (parts.length === 2) return (parts[0] * 60) + parts[1];
  if (parts.length === 1) return parts[0];
  return 0;
};

const challengeGoalInput = computed({
  get: () => formatGoalInput(challengeForm.value.goalAmount, challengeForm.value.goalUnit),
  set: (value: string) => {
    challengeForm.value.goalAmount = parseGoalInput(value, challengeForm.value.goalUnit);
  },
});

const challengeProgressInput = computed({
  get: () => formatGoalInput(progressAmount.value, progressChallengeUnit.value),
  set: (value: string) => {
    progressAmount.value = parseGoalInput(value, progressChallengeUnit.value);
  },
});

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
  challengeForm.value = {
    opponentId: friendId,
    title: '',
    description: '',
    goalAmount: 100,
    goalUnit: 'reps',
    distanceUnit: 'm',
    durationHours: 24,
  };
  showChallengeModal.value = true;
};

const createChallenge = async () => {
  if (!challengeForm.value.title.trim()) {
    showPopup('Titel ist erforderlich.', 'error');
    return;
  }
  try {
    const payload = {
      ...challengeForm.value,
      goalAmount: challengeForm.value.goalUnit === 'distance' && challengeForm.value.distanceUnit === 'km'
        ? Math.round((challengeForm.value.goalAmount || 0) * 1000)
        : challengeForm.value.goalAmount,
    };
    const { data } = await friendService.createChallenge(payload);
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

const deleteChallenge = async (id: number) => {
  if (!confirm('Challenge wirklich löschen?')) return;
  try {
    const { data } = await friendService.deleteChallenge(id);
    showPopup(data.message || 'Challenge gelöscht.', 'success');
    await loadChallenges();
  } catch (e: any) {
    showPopup(e.response?.data?.message || 'Fehler beim Löschen.', 'error');
  }
};

const openProgressModal = (ch: FriendChallengeDto) => {
  progressChallengeId.value = ch.id;
  progressAmount.value = 1;
  progressChallengeGoal.value = ch.goalAmount;
  progressChallengeUnit.value = ch.goalUnit;
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
                <span class="status-text" :style="{ color: statusColor(ch.status), textShadow: `0 0 14px ${statusColor(ch.status)}55` }">{{ statusLabel(ch.status) }}</span>
              </div>
              <p v-if="ch.description" class="challenge-desc">{{ ch.description }}</p>
              <div class="challenge-meta">
                <span><img src="../assets/XP_Pixel.png" alt="" class="reward-pixel-icon" /> {{ ch.xpReward }} XP</span>
                <span><img src="../assets/SYBAU_Coin.png" alt="" class="reward-pixel-icon" /> {{ ch.coinReward }} Coins</span>
                <span><Target :size="14" /> Ziel: {{ ch.goalAmount }} {{ goalUnitShort(ch.goalUnit) }}</span>
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
                <span class="status-text" :style="{ color: statusColor(ch.status), textShadow: `0 0 14px ${statusColor(ch.status)}55` }">{{ statusLabel(ch.status) }}</span>
              </div>
              <p v-if="ch.description" class="challenge-desc">{{ ch.description }}</p>
              <div class="challenge-meta">
                <span><img src="../assets/XP_Pixel.png" alt="" class="reward-pixel-icon" /> {{ ch.xpReward }} XP</span>
                <span><img src="../assets/SYBAU_Coin.png" alt="" class="reward-pixel-icon" /> {{ ch.coinReward }} Coins</span>
                <span><Target :size="14" /> Ziel: {{ ch.goalAmount }} {{ goalUnitShort(ch.goalUnit) }}</span>
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
                <span class="status-text" :style="{ color: statusColor(ch.status), textShadow: `0 0 14px ${statusColor(ch.status)}55` }">{{ statusLabel(ch.status) }}</span>
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
              <div class="past-actions" v-if="canDeleteChallenge(ch.status)">
                <button class="delete-challenge-btn" @click="deleteChallenge(ch.id)">
                  <Trash2 :size="15" /> Löschen
                </button>
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
          <h2>Challenge erstellen</h2>
          <div class="form-group">
            <label>Titel</label>
            <input v-model="challengeForm.title" placeholder="z.B. 100 Liegestütze in 24h" />
          </div>
          <div class="form-group">
            <label>Beschreibung (optional)</label>
            <textarea v-model="challengeForm.description" rows="2" placeholder="Was muss gemacht werden?"></textarea>
          </div>
          <div class="form-row">
            <div class="form-group goal-field-group">
              <label>Ziel (Anzahl)</label>
              <input
                v-if="challengeForm.goalUnit === 'reps'"
                type="number"
                v-model.number="challengeForm.goalAmount"
                min="1"
                max="10000"
                placeholder="z.B. 100"
              />
              <input
                v-else-if="challengeForm.goalUnit === 'time'"
                v-model="challengeGoalInput"
                placeholder="hh:mm:ss"
                inputmode="numeric"
              />
              <div v-else class="distance-input-row">
                <input
                  type="number"
                  v-model.number="challengeForm.goalAmount"
                  min="1"
                  max="1000000"
                  :placeholder="challengeForm.distanceUnit === 'km' ? 'z.B. 5' : 'z.B. 5000'"
                />
                <select v-model="challengeForm.distanceUnit" class="distance-unit-select">
                  <option value="m">m</option>
                  <option value="km">km</option>
                </select>
              </div>
            </div>
            <div class="form-group unit-field-group">
              <label>Einheit</label>
              <select v-model="challengeForm.goalUnit">
                <option value="reps">Reps</option>
                <option value="time">Time</option>
                <option value="distance">Distance</option>
              </select>
            </div>
          </div>
          <div class="form-row">
            <div class="form-group">
              <label>Dauer (Stunden)</label>
              <input type="number" v-model.number="challengeForm.durationHours" min="1" max="168" />
            </div>
            <div class="form-group reward-preview-group">
              <label>Belohnung</label>
              <div class="reward-preview-inline">
                <span><img src="../assets/XP_Pixel.png" alt="" class="reward-pixel-icon" /> automatisch</span>
                <span><img src="../assets/SYBAU_Coin.png" alt="" class="reward-pixel-icon" /> automatisch</span>
              </div>
            </div>
          </div>
          <div class="modal-actions">
            <button class="secondary-btn modal-cancel-btn" @click="showChallengeModal = false">Abbrechen</button>
            <button class="primary-btn" @click="createChallenge">Challenge senden</button>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- ───── MODAL: Fortschritt melden ───── -->
    <Teleport to="body">
      <div v-if="showProgressModal" class="modal-overlay" @click.self="showProgressModal = false">
        <div class="modal-card">
          <h2>📊 Fortschritt melden</h2>
          <p class="modal-progress-info">Aktuell: <strong>{{ formatGoalInput(progressChallengeCurrent, progressChallengeUnit) }}</strong> / {{ formatGoalInput(progressChallengeGoal, progressChallengeUnit) }}</p>
          <div class="form-group">
            <label>Wie viel hast du geschafft?</label>
            <input
              v-if="progressChallengeUnit !== 'time'"
              type="number"
              v-model.number="progressAmount"
              min="1"
              :max="progressChallengeGoal"
              placeholder="z.B. 25"
            />
            <input
              v-else
              v-model="challengeProgressInput"
              placeholder="hh:mm:ss"
              inputmode="numeric"
            />
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
  display: grid;
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
  display: grid;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 22px;
}

.section-heading p {
  margin: 0;
  color: #cbd5e1;
}

.title-with-icon {
  display: grid;
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
  display: grid;
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
  display: grid;
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
  display: grid;
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
  display: grid;
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
  display: grid;
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
  display: grid;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 8px;
}

.challenge-header h3 {
  margin: 0;
  font-size: 1.05rem;
}

.status-text {
  font-size: 0.82rem;
  font-weight: 800;
  letter-spacing: 0;
}

.challenge-desc {
  color: #94a3b8;
  font-size: 0.9rem;
  margin: 0 0 12px;
}

.challenge-meta {
  display: grid;
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

.reward-pixel-icon {
  width: 16px;
  height: 16px;
  object-fit: contain;
  image-rendering: pixelated;
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
  justify-content: center;
  width: 100%;
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
  display: grid;
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
  background: rgba(2, 6, 23, 0.76);
  backdrop-filter: blur(8px);
  display: grid;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.modal-card {
  background: #182235;
  border-radius: 24px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  padding: 28px;
  width: min(520px, 100%);
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 24px 80px rgba(2, 6, 23, 0.42);
}

.modal-card h2 {
  margin: 0 0 20px;
  font-size: 1.3rem;
}

.reward-preview-inline {
  min-height: 50px;
  display: grid;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  gap: 10px;
  padding: 12px 14px;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.1);
  color: #cbd5e1;
  font-size: 0.95rem;
  font-weight: 700;
  box-sizing: border-box;
}

.reward-preview-inline span {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.reward-preview-group {
  display: grid;
  flex-direction: column;
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
.form-group textarea,
.form-group select {
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
.form-group textarea:focus,
.form-group select:focus {
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
  grid-template-columns: minmax(0, 1.45fr) minmax(0, 1fr);
  gap: 12px;
}

.goal-field-group {
  min-width: 0;
}

.unit-field-group {
  min-width: 0;
}

.modal-actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  margin-top: 20px;
  align-items: stretch;
}

.distance-input-row {
  display: grid;
  grid-template-columns: minmax(0, 1.35fr) 110px;
  gap: 10px;
}

.distance-unit-select {
  min-width: 0;
}

.modal-cancel-btn {
  width: 100%;
  min-width: unset;
  justify-content: center;
  min-height: unset;
  border-radius: 14px;
  font-size: 0.9rem;
  font-weight: 700;
}
.past-actions {  margin-top: 14px;  display: flex;  justify-content: flex-end;}
.delete-challenge-btn {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  min-height: 36px;
  padding: 0 12px;
  border: 1px solid rgba(248, 113, 113, 0.24);
  border-radius: 12px;
  background: rgba(127, 29, 29, 0.24);
  color: #fca5a5;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.2s ease;
}

.delete-challenge-btn:hover {
  background: rgba(127, 29, 29, 0.34);
  border-color: rgba(248, 113, 113, 0.38);
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

  .section-card {
    padding: 16px;
  }

  .tab-bar { gap: 4px; }
  .tab-btn { padding: 8px 12px; font-size: 0.82rem; }

  .search-bar {
    padding: 10px 14px;
  }

  .friend-card, .request-card {
    align-items: center;
    padding: 10px;
  }

  .friend-avatar {
    width: 38px;
    height: 38px;
  }

  .friend-name {
    font-size: 0.88rem;
  }

  .friend-meta {
    font-size: 0.68rem;
  }

  .friend-actions {
    justify-content: center;
  }

  .action-btn,
  .icon-action-btn,
  .text-action-btn,
  .send-request-btn,
  .sent-pill {
    padding: 6px 10px;
    min-height: 32px;
    font-size: 0.78rem;
  }

  .challenge-card {
    padding: 14px;
  }

  .challenge-header h3 {
    font-size: 0.92rem;
  }

  .challenge-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .challenge-meta {
    font-size: 0.76rem;
  }

  .progress-section {
    gap: 8px;
  }

  .progress-row {
    grid-template-columns: 80px 1fr 42px;
  }

  .progress-name {
    font-size: 0.76rem;
  }

  .progress-bar-track {
    height: 7px;
  }

  .progress-pct {
    font-size: 0.72rem;
  }

  .status-text {
    font-size: 0.72rem;
  }
}
</style>
