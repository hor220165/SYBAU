<template>
  <Header></Header>
  <Navbar></Navbar>

  <main class="profile-content">
    <section class="profile-summary-card">
      <div class="profile-summary-main">
        <div class="profile-avatar-wrap">
          <div class="profile-avatar">
            <img
              :src="profileImageUrl || noProfilePicture"
              :alt="currentUsername"
              class="profile-avatar-image"
            />
          </div>
          <button class="avatar-edit-btn" @click="toggleImageActions" type="button" aria-label="Profilbild bearbeiten">
            <Pencil :size="14" />
          </button>
          <div v-if="showImageActions" class="avatar-action-menu">
          <button type="button" @click="openImagePicker">{{ settingsCopy.choosePhoto }}</button>
            <button
              v-if="profileImageUrl"
              type="button"
              class="danger"
              @click="removeProfileImage"
            >
              {{ settingsCopy.removeCurrentPhoto }}
            </button>
          </div>
          <input
            ref="profileImageInput"
            type="file"
            accept="image/*"
            class="hidden-file-input"
            @change="onProfileImageChange"
          />
        </div>

        <div class="profile-summary-copy">
          <h1 class="profile-title">{{ currentUsername || settingsCopy.userFallback }}</h1>
          <p class="profile-email">{{ currentEmail }}</p>
        </div>
      </div>

      <button class="settings-btn" @click="openSettings" type="button">
        <div v-html="`<svg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.1a2 2 0 0 1 1 1.72v.51a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.39a2 2 0 0 0-.73-2.73l-.15-.08a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z'/><circle cx='12' cy='12' r='3'/></svg>`"></div>
        <span>{{ settingsCopy.settings }}</span>
      </button>
    </section>

    <div class="stats-overview">
      <StatCard
        :icon="`<circle cx='12' cy='12' r='10'/><circle cx='12' cy='12' r='6'/><circle cx='12' cy='12' r='2'/>`"
        :label="settingsCopy.totalWorkouts"
        :value="String(profileStats.totalWorkouts)"
        cardClass="stat-purple"
      />
      <StatCard
        :icon="`<rect width='18' height='18' x='3' y='4' rx='2' ry='2'/><line x1='16' x2='16' y1='2' y2='6'/><line x1='8' x2='8' y1='2' y2='6'/><line x1='3' x2='21' y1='10' y2='10'/>`"
        :label="settingsCopy.trainingTime"
        :value="profileStats.trainingHours + 'h'"
        cardClass="stat-blue"
      />
      <StatCard
        :icon="`<path d='M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z'/>`"
        :label="settingsCopy.caloriesBurned"
        :value="profileStats.caloriesBurned.toLocaleString(locale)"
        cardClass="stat-orange"
      />
      <StatCard
        :icon="`<polyline points='22 7 13.5 15.5 8.5 10.5 2 17'/><polyline points='16 7 22 7 22 13'/>`"
        :label="settingsCopy.longestStreak"
        :value="profileStats.longestStreak + ' ' + settingsCopy.days"
        cardClass="stat-green"
      />
    </div>

    <section class="achievements-section">
      <div class="section-header">
        <div class="title-row">
          <div class="section-icon" v-html="`<svg xmlns='http://www.w3.org/2000/svg' width='28' height='28' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M6 9H4.5a2.5 2.5 0 0 1 0-5H6'/><path d='M18 9h1.5a2.5 2.5 0 0 0 0-5H18'/><path d='M4 22h16'/><path d='M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22'/><path d='M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22'/><path d='M18 2H6v7a6 6 0 0 0 12 0V2Z'/></svg>`"></div>
          <h2>Achievements</h2>
        </div>
        <span class="achievement-count">{{ unlockedCount }} / {{ totalAchievements }} {{ settingsCopy.unlocked }}</span>
      </div>

      <div class="achievements-carousel">
        <button class="carousel-btn prev" @click="previousAchievements" :disabled="currentAchievementIndex === 0">&#8592;</button>
        <div class="achievements-grid">
          <AchievementCard
            v-for="achievement in visibleAchievements"
            :key="achievement.id"
            :icon="achievement.icon"
            :title="achievement.title"
            :description="achievement.description"
            :unlocked="achievement.unlocked"
          />
        </div>
        <button class="carousel-btn next" @click="nextAchievements" :disabled="currentAchievementIndex >= achievements.length - visibleCount">&#8594;</button>
      </div>

      <div class="carousel-dots">
        <span
          v-for="(_, i) in Math.ceil(achievements.length / visibleCount)"
          :key="i"
          class="dot"
          :class="{ active: Math.floor(currentAchievementIndex / visibleCount) === i }"
          @click="currentAchievementIndex = i * visibleCount"
        ></span>
      </div>
    </section>

    <section class="activity-section">
      <div class="section-header">
        <div class="title-row">
          <div class="section-icon" v-html="`<svg xmlns='http://www.w3.org/2000/svg' width='28' height='28' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><rect width='18' height='18' x='3' y='4' rx='2' ry='2'/><line x1='16' x2='16' y1='2' y2='6'/><line x1='8' x2='8' y1='2' y2='6'/><line x1='3' x2='21' y1='10' y2='10'/></svg>`"></div>
          <h2>{{ settingsCopy.weeklyActivity }}</h2>
        </div>
        <div class="week-label">{{ weekLabel }}</div>
      </div>

      <div class="activity-calendar">
        <button class="week-nav prev" @click="previousWeek">&#8592;</button>
        <div class="days-grid">
          <div
            v-for="day in currentWeekDays"
            :key="day.date"
            class="day-card"
            :class="{ active: day.workoutDone, today: day.isToday }"
          >
            <span class="day-name">{{ day.name }}</span>
            <span class="day-date">{{ day.dateDisplay }}</span>
            <div class="day-indicator">
              <span v-if="day.workoutDone" class="star-icon"><img src="../assets/Star_Pixel.png" alt=""></span>
              <span v-else class="empty-icon">&#8211;</span>
            </div>
            <span class="day-duration">{{ day.duration }}</span>
          </div>
        </div>
        <button class="week-nav next" @click="nextWeek" :disabled="isCurrentWeek">&#8594;</button>
      </div>
    </section>

    <section class="recent-section">
      <div class="section-header">
        <div class="title-row">
          <div class="section-icon" v-html="`<svg xmlns='http://www.w3.org/2000/svg' width='28' height='28' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><line x1='18' x2='18' y1='20' y2='4'/><line x1='12' x2='12' y1='20' y2='10'/><line x1='6' x2='6' y1='20' y2='16'/></svg>`"></div>
          <h2>{{ settingsCopy.recentActivities }}</h2>
        </div>
      </div>
      <div v-if="recentActivities.length" class="activities-list">
        <ActivityItem
          v-for="activity in recentActivities"
          :key="activity.id"
          :icon="activity.icon"
          :title="activity.title"
          :time="activity.time"
          :xp="activity.xp"
          :type="activity.type"
        />
      </div>
      <p v-else class="empty-activity-text">{{ settingsCopy.noRecentActivities }}</p>
    </section>
  </main>

  <Teleport to="body">
    <Transition name="settings">
      <div v-if="showSettings" class="settings-overlay" @click="closeSettings">
        <div class="settings-sidebar" @click.stop>
          <div class="settings-header">
            <div class="settings-title-row">
              <button
                v-if="settingsView === 'password'"
                class="settings-back-btn"
                @click="settingsView = 'main'"
                type="button"
                :aria-label="settingsCopy.back"
              >
                <ArrowLeft :size="18" />
              </button>
              <h2>{{ settingsView === 'password' ? settingsCopy.passwordTitle : settingsCopy.settings }}</h2>
            </div>
            <button class="close-btn" @click="closeSettings">&#10005;</button>
          </div>
          <div class="settings-content">
            <template v-if="settingsView === 'main'">
              <section class="settings-section">
                <h3>{{ settingsCopy.profile }}</h3>
                <div class="field">
                  <label>{{ settingsCopy.username }}</label>
                  <input v-model="editingUsername" />
                </div>
                <div class="field">
                  <label>{{ settingsCopy.email }}</label>
                  <input :value="user?.email ?? user?.Email ?? ''" readonly />
                </div>
                <button class="btn-primary" @click="saveProfile" :disabled="savingProfile || usernameUnchanged">{{ settingsCopy.save }}</button>
              </section>

              <section class="settings-section">
                <h3>{{ settingsCopy.progress }}</h3>
                <div class="progress-stats">
                  <div class="stat-row">
                    <span class="stat-label">Level</span>
                    <span class="stat-value">{{ level }}</span>
                  </div>
                  <div class="stat-row">
                    <span class="stat-label">XP</span>
                    <span class="stat-value">{{ experience }}</span>
                  </div>
                  <div class="stat-row">
                    <span class="stat-label">{{ settingsCopy.completedChallenges }}</span>
                    <span class="stat-value">{{ completedChallenges }}</span>
                  </div>
                  <div class="stat-row">
                    <span class="stat-label">{{ settingsCopy.leaderboardPosition }}</span>
                    <span class="stat-value">{{ leaderboardPosition }}</span>
                  </div>
                </div>
              </section>

              <section class="settings-section">
                <h3>{{ settingsCopy.security }}</h3>
                <button class="settings-nav-row" @click="settingsView = 'password'" type="button">
                  <span class="settings-nav-icon">
                    <LockKeyhole :size="18" />
                  </span>
                  <span class="settings-nav-copy">
                    <strong>{{ settingsCopy.changePassword }}</strong>
                    <span>{{ settingsCopy.passwordHint }}</span>
                  </span>
                  <ChevronRight :size="18" />
                </button>
              </section>

              <section class="settings-section">
                <h3>{{ settingsCopy.account }}</h3>
                <div class="account-actions">
                  <button class="account-action-btn" @click="handleLogout" type="button">
                    <div class="account-action-icon logout-icon">↪</div>
                    <div class="account-action-copy">
                      <strong>{{ settingsCopy.logout }}</strong>
                      <span>{{ settingsCopy.logoutHint }}</span>
                    </div>
                  </button>

                  <button class="account-action-btn account-action-danger" @click="deleteAccount" type="button">
                    <div class="account-action-icon delete-icon">×</div>
                    <div class="account-action-copy">
                      <strong>{{ settingsCopy.deleteAccount }}</strong>
                      <span>{{ settingsCopy.deleteHint }}</span>
                    </div>
                  </button>
                </div>
              </section>
            </template>

            <template v-else>
              <section class="settings-section password-panel">
                <p class="settings-subtitle">{{ settingsCopy.passwordSubtitle }}</p>
                <div class="field">
                  <label>{{ settingsCopy.oldPassword }}</label>
                  <input type="password" v-model="oldPassword" />
                </div>
                <div class="field">
                  <label>{{ settingsCopy.newPassword }}</label>
                  <input type="password" v-model="newPassword" />
                </div>
                <button class="btn-primary" @click="changePassword" :disabled="changingPassword">{{ settingsCopy.savePassword }}</button>
              </section>
            </template>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>

  <Teleport to="body">
    <MessagePopup
      v-if="popupMessage"
      :message="popupMessage"
      :type="popupType"
      @close="popupMessage = ''"
    />
  </Teleport>

  <FooterComponent />
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { useRouter } from 'vue-router';
import Header from '@/components/Header.vue';
import Navbar from '@/components/Navbar.vue';
import StatCard from '@/components/StatCard.vue';
import AchievementCard from '@/components/AchievementCard.vue';
import ActivityItem from '@/components/ActivityItem.vue';
import { useAuth } from '@/composables/useAuth';
import { useLeaderboard } from '@/composables/useLeaderboard';
import { userService, achievementService, resolveMediaUrl } from '@/services/api';
import FooterComponent from '@/components/FooterComponent.vue';
import MessagePopup from '@/components/MessagePopup.vue';
import type { Achievement, ProfileStats } from '@/models/Achievement';
import noProfilePicture from '@/assets/Nopfp.png';
import { ArrowLeft, ChevronRight, LockKeyhole, Pencil } from 'lucide-vue-next';

const router = useRouter();
const { user, logout, refreshProfile } = useAuth();
const locale = 'de-DE';
const { sortedLeaderboard, loadLeaderboard } = useLeaderboard();

const longestStreak = ref(0);
const currentStreak = ref(0);
const profileStats = ref<ProfileStats>({ totalWorkouts: 0, trainingHours: 0, caloriesBurned: 0, longestStreak: 0, currentStreak: 0 });

const showSettings = ref(false);
const settingsView = ref<'main' | 'password'>('main');
const editingUsername = ref('');
const savingProfile = ref(false);

const settingsCopy = computed(() => ({
    myProfile: 'Mein Profil',
    userFallback: 'Benutzer',
    settings: 'Einstellungen',
    back: 'Zurück',
    profile: 'Profil',
    username: 'Benutzername',
    email: 'E-Mail',
    save: 'Speichern',
    progress: 'Fortschritt',
    completedChallenges: 'Absolvierte Challenges',
    leaderboardPosition: 'Leaderboard-Position',
    security: 'Sicherheit',
    changePassword: 'Passwort ändern',
    passwordTitle: 'Passwort ändern',
    passwordHint: 'Öffnet eine eigene sichere Ansicht.',
    account: 'Account',
    logout: 'Abmelden',
    logoutHint: 'Du wirst in diesem Browser ausgeloggt.',
    deleteAccount: 'Account löschen',
    deleteHint: 'Diese Aktion kann nicht rückgängig gemacht werden.',
    passwordSubtitle: 'Gib dein aktuelles Passwort ein und setze danach ein neues.',
    oldPassword: 'Altes Passwort',
    newPassword: 'Neues Passwort',
    savePassword: 'Passwort speichern',
    noEmail: 'Keine E-Mail',
    profileSaved: 'Profil gespeichert!',
    sessionExpired: 'Session abgelaufen. Bitte melden Sie sich erneut an.',
    saveError: 'Fehler beim Speichern: ',
    profileImageUpdated: 'Profilbild aktualisiert!',
    profileImageFailed: 'Profilbild konnte nicht gespeichert werden.',
    removeProfileImageConfirm: 'Profilbild entfernen? Danach wird wieder das Standardbild angezeigt.',
    profileImageRemoved: 'Profilbild entfernt!',
    profileImageRemoveFailed: 'Profilbild konnte nicht entfernt werden.',
    fillBothFields: 'Bitte beide Felder ausfüllen.',
    samePassword: 'Das neue Passwort darf nicht mit dem alten übereinstimmen.',
    passwordChanged: 'Passwort erfolgreich geändert!',
    passwordChangeFailed: 'Fehler beim Ändern des Passworts.',
    deleteConfirm: 'Account wirklich löschen? Diese Aktion ist endgültig.',
    deleteError: 'Fehler beim Löschen: ',
    choosePhoto: 'Foto auswählen',
    removeCurrentPhoto: 'Aktuelles Foto entfernen',
    totalWorkouts: 'Workouts gesamt',
    trainingTime: 'Trainingszeit',
    caloriesBurned: 'Kalorien verbrannt',
    longestStreak: 'Längster Streak',
    days: 'Tage',
    unlocked: 'freigeschaltet',
    weeklyActivity: 'Wöchentliche Aktivität',
    recentActivities: 'Letzte Aktivitäten',
    noRecentActivities: 'Noch keine letzten Aktivitäten vorhanden.',
}));

const currentUsername = computed(() => user.value?.userName ?? user.value?.UserName ?? user.value?.username ?? '');

function openSettings() {
  editingUsername.value = currentUsername.value;
  settingsView.value = 'main';
  showSettings.value = true;
}

function closeSettings() {
  showSettings.value = false;
  settingsView.value = 'main';
  oldPassword.value = '';
  newPassword.value = '';
}

const popupMessage = ref('');
const popupType = ref<'success' | 'error'>('success');
const profileImageInput = ref<HTMLInputElement | null>(null);
const showImageActions = ref(false);

const usernameUnchanged = computed(() => {
  return editingUsername.value.trim() === currentUsername.value;
});

const currentEmail = computed(() => user.value?.email ?? user.value?.Email ?? settingsCopy.value.noEmail);
const profileImageUrl = computed(() => resolveMediaUrl(user.value?.profileImageUrl ?? user.value?.ProfileImageUrl ?? ''));

async function saveProfile() {
  savingProfile.value = true;
  try {
    await userService.updateProfile({ UserName: editingUsername.value });
    await refreshProfile();
    popupType.value = 'success';
    popupMessage.value = settingsCopy.value.profileSaved;
  } catch (err: any) {
    if (err.response?.status === 401) {
      popupType.value = 'error';
      popupMessage.value = settingsCopy.value.sessionExpired;
      logout();
      router.push('/auth');
    } else {
      popupType.value = 'error';
      popupMessage.value = settingsCopy.value.saveError + (err.response?.data?.message || err.message);
    }
  } finally {
    savingProfile.value = false;
  }
}

function openImagePicker() {
  showImageActions.value = false;
  profileImageInput.value?.click();
}

function toggleImageActions() {
  showImageActions.value = !showImageActions.value;
}

async function onProfileImageChange(event: Event) {
  const input = event.target as HTMLInputElement;
  const file = input.files?.[0];
  if (!file) return;

  try {
    await userService.uploadProfileImage(file);
    await refreshProfile();
    await loadLeaderboard();
    popupType.value = 'success';
    popupMessage.value = settingsCopy.value.profileImageUpdated;
  } catch (err: any) {
    popupType.value = 'error';
    popupMessage.value = err.response?.data?.message || err.message || settingsCopy.value.profileImageFailed;
  } finally {
    if (input) input.value = '';
  }
}

async function removeProfileImage() {
  if (!confirm(settingsCopy.value.removeProfileImageConfirm)) return;

  try {
    showImageActions.value = false;
    await userService.removeProfileImage();
    await refreshProfile();
    await loadLeaderboard();
    popupType.value = 'success';
    popupMessage.value = settingsCopy.value.profileImageRemoved;
  } catch (err: any) {
    popupType.value = 'error';
    popupMessage.value = err.response?.data?.message || err.message || settingsCopy.value.profileImageRemoveFailed;
  }
}

const level = computed(() => user.value?.avatar?.level ?? user.value?.avatar?.Level ?? 1);
const experience = computed(() => user.value?.avatar?.experience ?? user.value?.avatar?.Experience ?? 0);
const completedChallenges = ref(0);
const leaderboardPosition = computed(() => {
  const name = currentUsername.value;
  const idx = sortedLeaderboard.value.findIndex((u: any) => (u.UserName ?? u.username ?? '').toLowerCase() === name.toLowerCase());
  if (idx >= 0 && idx < sortedLeaderboard.value.length) {
    const rank = sortedLeaderboard.value[idx]?.Rank;
    return rank ?? idx + 1;
  }
  return '—';
});

const oldPassword = ref('');
const newPassword = ref('');
const changingPassword = ref(false);

async function changePassword() {
  if (!oldPassword.value || !newPassword.value) {
    popupType.value = 'error';
    popupMessage.value = settingsCopy.value.fillBothFields;
    return;
  }
  if (oldPassword.value === newPassword.value) {
    popupType.value = 'error';
    popupMessage.value = settingsCopy.value.samePassword;
    return;
  }
  changingPassword.value = true;
  try {
    await userService.changePassword(oldPassword.value, newPassword.value);
    oldPassword.value = '';
    newPassword.value = '';
    settingsView.value = 'main';
    popupType.value = 'success';
    popupMessage.value = settingsCopy.value.passwordChanged;
  } catch (err: any) {
    if (err.response?.status === 401) {
      popupType.value = 'error';
      popupMessage.value = settingsCopy.value.sessionExpired;
      logout();
      router.push('/auth');
    } else {
      popupType.value = 'error';
      popupMessage.value = err.response?.data || settingsCopy.value.passwordChangeFailed;
    }
  } finally {
    changingPassword.value = false;
  }
}

async function deleteAccount() {
  if (!confirm(settingsCopy.value.deleteConfirm)) return;
  try {
    await userService.deleteAccount();
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    logout();
    router.push('/auth');
  } catch (err: any) {
    popupType.value = 'error';
    popupMessage.value = settingsCopy.value.deleteError + (err.response?.data?.message || err.message);
  }
}

function handleLogout() {
  logout();
  router.push('/auth');
}

// Responsive visible count
const windowWidth = ref(window.innerWidth);
const onResize = () => { windowWidth.value = window.innerWidth; };
onMounted(() => window.addEventListener('resize', onResize));
onUnmounted(() => window.removeEventListener('resize', onResize));

const visibleCount = computed(() => {
  if (windowWidth.value < 480) return 2;
  if (windowWidth.value < 768) return 4;
  if (windowWidth.value < 1024) return 4;
  return 8;
});

const currentAchievementIndex = ref(0);

// Icon-Map: key → SVG-Pfade (gleiche Icons wie vorher)
const achievementIcons: Record<string, string> = {
  'speedster': `<polygon points='13 2 3 14 12 14 11 22 21 10 12 10 13 2'/>`,
  'iron-body': `<path d='M6 9H4.5a2.5 2.5 0 0 1 0-5H6'/><path d='M18 9h1.5a2.5 2.5 0 0 0 0-5H18'/><path d='M4 22h16'/><path d='M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22'/><path d='M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22'/><path d='M18 2H6v7a6 6 0 0 0 12 0V2Z'/>`,
  'on-fire': `<path d='M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z'/>`,
  'quest-hunter': `<circle cx='12' cy='12' r='10'/><circle cx='12' cy='12' r='6'/><circle cx='12' cy='12' r='2'/>`,
  'rising-star': `<polygon points='12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2'/>`,
  'champion': `<path d='M6 9H4.5a2.5 2.5 0 0 1 0-5H6'/><path d='M18 9h1.5a2.5 2.5 0 0 0 0-5H18'/><path d='M4 22h16'/><path d='M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22'/><path d='M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22'/><path d='M18 2H6v7a6 6 0 0 0 12 0V2Z'/>`,
  'legend': `<circle cx='12' cy='8' r='7'/><polyline points='8.21 13.89 7 23 12 20 17 23 15.79 13.88'/>`,
  'perfectionist': `<polyline points='20 6 9 17 4 12'/>`,
  'sky-rocket': `<path d='M4.5 16.5c-1.5 1.26-2 5-2 5s3.74-.5 5-2c.71-.84.7-2.13-.09-2.91a2.18 2.18 0 0 0-2.91-.09z'/><path d='m12 15-3-3a22 22 0 0 1 2-3.95A12.88 12.88 0 0 1 22 2c0 2.72-.78 7.5-6 11a22.35 22.35 0 0 1-4 2z'/><path d='M9 12H4s.55-3.03 2-4c1.62-1.08 5 0 5 0'/><path d='M12 15v5s3.03-.55 4-2c1.08-1.62 0-5 0-5'/>`,
  'diamond-grind': `<path d='M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z'/>`,
  'speed-demon': `<polygon points='13 2 3 14 12 14 11 22 21 10 12 10 13 2'/>`,
  'workout-warrior': `<polyline points='22 12 18 12 15 21 9 3 6 12 2 12'/>`,
  'triathlon-master': `<path d='M2 12h20'/><path d='M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z'/><circle cx='12' cy='12' r='10'/>`,
  'shining-star': `<polygon points='12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2'/>`,
  'bionic': `<path d='M18 3a3 3 0 0 1 0 6h-6a3 3 0 0 1 0-6h6z'/><path d='M6 21a3 3 0 0 1 0-6h6a3 3 0 0 1 0 6H6z'/><path d='M15 12a3 3 0 1 1 0-6 3 3 0 0 1 0 6z'/><path d='M9 18a3 3 0 1 0 0-6 3 3 0 0 0 0 6z'/>`,
  'elite-athlete': `<circle cx='12' cy='8' r='7'/><polyline points='8.21 13.89 7 23 12 20 17 23 15.79 13.88'/>`
};
const defaultAchievementIcon = `<path d='M6 9H4.5a2.5 2.5 0 0 1 0-5H6'/><path d='M18 9h1.5a2.5 2.5 0 0 0 0-5H18'/><path d='M4 22h16'/><path d='M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22'/><path d='M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22'/><path d='M18 2H6v7a6 6 0 0 0 12 0V2Z'/>`;

const achievements = ref<Array<{ id: number; icon: string; title: string; description: string; unlocked: boolean }>>([]);

const visibleAchievements = computed(() =>
  achievements.value.slice(currentAchievementIndex.value, currentAchievementIndex.value + visibleCount.value)
);
const unlockedCount = computed(() => achievements.value.filter(a => a.unlocked).length);
const totalAchievements = computed(() => achievements.value.length);

const previousAchievements = () => {
  if (currentAchievementIndex.value > 0) currentAchievementIndex.value -= visibleCount.value;
};
const nextAchievements = () => {
  if (currentAchievementIndex.value < achievements.value.length - visibleCount.value)
    currentAchievementIndex.value += visibleCount.value;
};

// Weekly Activity
const currentWeekOffset = ref(0);
const activityDates = ref<Map<string, number>>(new Map());

function getMonday(offset: number): Date {
  const today = new Date();
  const currentDay = today.getDay();
  const monday = new Date(today);
  monday.setDate(today.getDate() - currentDay + (currentDay === 0 ? -6 : 1) + (offset * 7));
  return monday;
}

function toDateString(d: Date): string {
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
}

async function loadWeeklyActivity() {
  const monday = getMonday(currentWeekOffset.value);
  const sunday = new Date(monday);
  sunday.setDate(monday.getDate() + 6);
  try {
    const res = await userService.getWeeklyActivity(toDateString(monday), toDateString(sunday));
    const map = new Map<string, number>();
    (res.data as Array<{ date: string; reps: number }> || []).forEach(item => {
      map.set(item.date, item.reps);
    });
    activityDates.value = map;
  } catch {
    activityDates.value = new Map();
  }
}

const getWeekDays = (offset: number) => {
  const today = new Date();
  const monday = getMonday(offset);
  const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  const weekDays = [];
  for (let i = 0; i < 7; i++) {
    const date = new Date(monday);
    date.setDate(monday.getDate() + i);
    const isToday = date.toDateString() === today.toDateString();
    const dateDisplay = `${date.getDate().toString().padStart(2, '0')}.${(date.getMonth() + 1).toString().padStart(2, '0')}`;
    const reps = activityDates.value.get(toDateString(date)) ?? 0;
    const workoutDone = reps > 0;
    const duration = workoutDone ? `${reps} Einheiten` : '–';
    weekDays.push({ name: days[i], date: date.toISOString(), dateDisplay, workoutDone, duration, isToday });
  }
  return weekDays;
};

const currentWeekDays = computed(() => getWeekDays(currentWeekOffset.value));
const isCurrentWeek = computed(() => currentWeekOffset.value === 0);
const previousWeek = () => { currentWeekOffset.value--; loadWeeklyActivity(); };
const nextWeek = () => { if (!isCurrentWeek.value) { currentWeekOffset.value++; loadWeeklyActivity(); } };

const weekLabel = computed(() => {
  const days = currentWeekDays.value || [];
  return `${days[0]?.dateDisplay} – ${days[6]?.dateDisplay}`;
});

const recentActivities = ref<Array<{ id: number; icon: string; title: string; time: string; xp: number; type: 'workout' | 'quest' | 'achievement' | 'level' }>>([]);

const activityIcons: Record<string, string> = {
  workout: `<circle cx='12' cy='12' r='10'/><circle cx='12' cy='12' r='6'/><circle cx='12' cy='12' r='2'/>`,
  quest: `<path d='M6 9H4.5a2.5 2.5 0 0 1 0-5H6'/><path d='M18 9h1.5a2.5 2.5 0 0 0 0-5H18'/><path d='M4 22h16'/><path d='M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22'/><path d='M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22'/><path d='M18 2H6v7a6 6 0 0 0 12 0V2Z'/>`,
  achievement: `<circle cx='12' cy='8' r='7'/><polyline points='8.21 13.89 7 23 12 20 17 23 15.79 13.88'/>`,
  level: `<polygon points='13 2 3 14 12 14 11 22 21 10 12 10 13 2'/>`,
};

function formatTimeAgo(timestamp: string): string {
  const now = new Date();
  const date = new Date(timestamp);
  const diffMs = now.getTime() - date.getTime();
  const diffMin = Math.floor(diffMs / 60000);
  const diffH = Math.floor(diffMin / 60);
  const diffD = Math.floor(diffH / 24);

  if (diffMin < 1) return 'Gerade eben';
  if (diffMin < 60) return `vor ${diffMin} Minuten`;
  if (diffH < 24) return `vor ${diffH} Stunde${diffH > 1 ? 'n' : ''}`;
  if (diffD === 1) return 'Gestern';
  if (diffD < 7) return `vor ${diffD} Tagen`;
  return date.toLocaleDateString('de-DE');
}

async function loadRecentActivities() {
  try {
    const res = await userService.getRecentActivities(10);
    recentActivities.value = (res.data as any[]).map((a: any) => ({
      id: a.id,
      icon: activityIcons[a.type] ?? activityIcons.workout ?? '',
      title: a.title,
      time: formatTimeAgo(a.timestamp),
      xp: a.xp,
      type: a.type as 'workout' | 'quest' | 'achievement' | 'level'
    }));
  } catch {
    recentActivities.value = [];
  }
}

onMounted(async () => {
  try {
    await userService.getProfile();
    user.value = JSON.parse(localStorage.getItem('user') || '{}');
    editingUsername.value = user.value.userName;
    await loadLeaderboard();

    // Achievements & Stats vom Backend laden
    try {
      const [achievementsRes, statsRes] = await Promise.all([
        achievementService.getAll(),
        achievementService.getProfileStats()
      ]);
      achievements.value = (achievementsRes.data as Achievement[]).map(a => ({
        id: a.id,
        icon: achievementIcons[a.key] || defaultAchievementIcon,
        title: a.title,
        description: a.description,
        unlocked: a.unlocked
      }));
      profileStats.value = statsRes.data;
      longestStreak.value = statsRes.data.longestStreak ?? 0;
      currentStreak.value = statsRes.data.currentStreak ?? 0;
    } catch { /* Achievements/Stats nicht verfügbar */ }

    await loadWeeklyActivity();
    await loadRecentActivities();
  } catch (err) {
    console.error('Fehler beim Laden', err);
  }
});
</script>

<style scoped>
.profile-content {
  padding: 40px;
  max-width: 1400px;
  margin: 0 auto;
}

/* ── Header ── */
.profile-summary-card {
  position: relative;
  z-index: 30;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 18px;
  margin-bottom: 24px;
  padding: 22px 24px;
  border-radius: 18px;
  background: linear-gradient(180deg, rgba(15, 23, 42, 0.76), rgba(15, 23, 42, 0.5));
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow: 0 22px 48px rgba(2, 6, 23, 0.22);
  overflow: visible;
}

.profile-summary-main {
  display: flex;
  align-items: center;
  gap: 18px;
  min-width: 0;
}

.profile-avatar-wrap {
  position: relative;
  flex-shrink: 0;
}

.profile-avatar {
  width: 76px;
  height: 76px;
  border-radius: 999px;
  overflow: hidden;
  display: grid;
  place-items: center;
  background: rgba(30, 41, 59, 0.92);
  box-shadow: 0 18px 34px rgba(236, 72, 153, 0.16);
}

.profile-avatar-image {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.avatar-edit-btn {
  position: absolute;
  right: -2px;
  bottom: -2px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 28px;
  height: 28px;
  border: 0;
  border-radius: 999px;
  background: #ec4899;
  color: white;
  padding: 0;
  cursor: pointer;
  box-shadow: 0 10px 18px rgba(236, 72, 153, 0.28);
}

.avatar-action-menu {
  position: absolute;
  left: 0;
  top: calc(100% + 12px);
  width: 220px;
  padding: 8px;
  border-radius: 16px;
  background: rgba(15, 23, 42, 0.96);
  border: 1px solid rgba(255, 255, 255, 0.1);
  box-shadow: 0 20px 44px rgba(2, 6, 23, 0.42);
  z-index: 10050;
}

.avatar-action-menu button {
  width: 100%;
  border: 0;
  border-radius: 12px;
  padding: 11px 12px;
  background: transparent;
  color: rgba(255, 255, 255, 0.86);
  cursor: pointer;
  text-align: left;
  font-weight: 700;
}

.avatar-action-menu button:hover {
  background: rgba(255, 255, 255, 0.07);
}

.avatar-action-menu .danger {
  color: #fca5a5;
}

.hidden-file-input {
  display: none;
}

.profile-summary-copy {
  min-width: 0;
}

.profile-email {
  margin: 6px 0 0;
  color: rgba(255, 255, 255, 0.58);
  font-size: 0.98rem;
}

.profile-title {
  font-size: 32px;
  font-weight: 700;
  color: white;
  margin: 0;
}

.settings-btn {
  padding: 12px 16px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.04);
  color: rgba(255, 255, 255, 0.78);
  cursor: pointer;
  display: inline-flex;
  align-items: center;
  gap: 10px;
  transition: all 0.3s ease;
  flex-shrink: 0;
}

.settings-btn span {
  font-weight: 700;
}

.settings-btn:hover {
  color: white;
  border-color: rgba(236, 72, 153, 0.32);
  background: rgba(236, 72, 153, 0.08);
}

.avatar-edit-btn:hover {
  filter: brightness(1.04);
}

/* ── Stats Overview ── */
.stats-overview {
  position: relative;
  z-index: 1;
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 32px;
}

/* ── Sections ── */
.achievements-section,
.activity-section,
.recent-section {
  margin-bottom: 48px;
  background: rgba(15, 23, 42, 0.4);
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.05);
  border-radius: 24px;
  padding: 32px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
  flex-wrap: wrap;
  gap: 12px;
}

.title-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.section-icon {
  display: flex;
  align-items: center;
  color: #ec4899;
  filter: drop-shadow(0 0 8px rgba(236, 72, 153, 0.5));
  flex-shrink: 0;
}

.section-header h2 {
  font-size: 24px;
  font-weight: 700;
  color: white;
  margin: 0;
}

.achievement-count {
  padding: 8px 16px;
  background: rgba(236, 72, 153, 0.14);
  border: 1px solid rgba(236, 72, 153, 0.3);
  border-radius: 12px;
  font-size: 14px;
  font-weight: 600;
  color: #f9a8d4;
  white-space: nowrap;
}

.week-label {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.5);
  font-weight: 500;
}

/* ── Achievements Carousel ── */
.achievements-carousel {
  display: flex;
  align-items: center;
  gap: 16px;
}

.carousel-btn {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  background: rgba(30, 41, 59, 0.6);
  color: white;
  font-size: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}

.carousel-btn:hover:not(:disabled) {
  background: rgba(236, 72, 153, 0.3);
  border-color: rgba(236, 72, 153, 0.5);
  transform: scale(1.1);
}

.carousel-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.achievements-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  grid-template-rows: repeat(2, auto);
  gap: 16px;
  flex: 1;
  min-width: 0;
}

/* Dots */
.carousel-dots {
  display: flex;
  justify-content: center;
  gap: 8px;
  margin-top: 20px;
}

.dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.2);
  cursor: pointer;
  transition: all 0.3s ease;
}

.dot.active {
  background: #ec4899;
  box-shadow: 0 0 8px rgba(236, 72, 153, 0.6);
  width: 24px;
  border-radius: 4px;
}

/* ── Weekly Calendar ── */
.activity-calendar {
  display: flex;
  align-items: stretch;
  gap: 12px;
}

.week-nav {
  width: 44px;
  min-height: 80px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  background: rgba(30, 41, 59, 0.6);
  color: white;
  font-size: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}

.week-nav:hover:not(:disabled) {
  background: rgba(59, 130, 246, 0.3);
  border-color: rgba(59, 130, 246, 0.5);
  transform: scale(1.05);
}

.week-nav:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.days-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 10px;
  flex: 1;
  min-width: 0;
}

.day-card {
  background: rgba(30, 41, 59, 0.6);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 14px;
  padding: 14px 8px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
  min-width: 0;
}

.day-card.active {
  background: rgba(34, 197, 94, 0.2);
  border-color: rgba(34, 197, 94, 0.4);
}

.day-card.today {
  border: 2px solid rgba(236, 72, 153, 0.6);
  box-shadow: 0 0 20px rgba(236, 72, 153, 0.3);
}

.day-name {
  font-size: 12px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.8);
}

.day-date {
  font-size: 10px;
  color: rgba(255, 255, 255, 0.4);
}

.day-indicator {
  width: 36px;
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.star-icon {
  display: flex;
  align-items: center;
  justify-content: center;
}

.star-icon img {
  width: 36px;
  height: 36px;
  image-rendering: pixelated;
  image-rendering: -moz-crisp-edges;
  image-rendering: crisp-edges;
  filter: drop-shadow(0 0 8px rgba(251, 191, 36, 0.5));
}

.empty-icon {
  color: rgba(255, 255, 255, 0.2);
  font-size: 24px;
}

.day-duration {
  font-size: 10px;
  color: rgba(255, 255, 255, 0.5);
}

/* ── Activities ── */
.activities-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.empty-activity-text {
  margin: 0;
  color: rgba(255, 255, 255, 0.7);
}

/* ── Settings Sidebar ── */
.settings-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.72);
  backdrop-filter: blur(10px);
  z-index: 10000;
  display: flex;
  justify-content: flex-end;
}

.settings-sidebar {
  width: 100%;
  max-width: 500px;
  background: linear-gradient(180deg, #05070d 0%, #080b14 54%, #03050a 100%);
  box-shadow: -10px 0 46px rgba(0, 0, 0, 0.72);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  border-left: 1px solid rgba(255, 255, 255, 0.07);
}

.settings-header {
  padding: 28px 28px 18px;
  background: transparent;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 14px;
}

.settings-title-row {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}

.settings-header h2 {
  font-size: 24px;
  font-weight: 700;
  color: white;
  margin: 0;
}

.settings-back-btn {
  width: 34px;
  height: 34px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(255, 255, 255, 0.04);
  color: white;
  display: grid;
  place-items: center;
  padding: 0;
  cursor: pointer;
  transition: all 0.22s ease;
}

.settings-back-btn:hover {
  border-color: rgba(236, 72, 153, 0.28);
  background: rgba(236, 72, 153, 0.12);
}

.close-btn {
  width: 32px;
  height: 32px;
  border: 0;
  background: transparent;
  color: white;
  font-size: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0;
}

.close-btn:hover {
  color: rgba(255, 255, 255, 0.75);
}

.settings-content {
  flex: 1;
  overflow-y: auto;
  padding: 0 28px 28px;
  background: transparent;
}

.settings-section {
  margin-bottom: 16px;
  padding: 18px;
  background: rgba(5, 10, 23, 0.86);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.065);
  border-radius: 18px;
}

.settings-section:last-child { margin-bottom: 0; }

.settings-section h3 {
  font-size: 17px;
  font-weight: 700;
  color: white;
  margin: 0 0 14px 0;
}

.settings-section h3::before {
  content: none;
}

.field { margin-bottom: 12px; }

.field label {
  display: block;
  font-size: 13px;
  color: rgba(255, 255, 255, 0.74);
  margin-bottom: 8px;
  font-weight: 600;
}

.field input {
  width: 100%;
  padding: 14px 16px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.09);
  background: rgba(0, 0, 0, 0.24);
  color: white;
  font-size: 15px;
  transition: all 0.3s ease;
  box-sizing: border-box;
}

.field input:focus {
  outline: none;
  border-color: rgba(236, 72, 153, 0.6);
  box-shadow: 0 0 0 3px rgba(236, 72, 153, 0.1);
}

.field input:read-only {
  opacity: 0.6;
  cursor: not-allowed;
  background: rgba(0, 0, 0, 0.3);
}

.progress-stats { display: flex; flex-direction: column; gap: 12px; }

.stat-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: rgba(255, 255, 255, 0.035);
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  transition: all 0.3s ease;
}

.stat-row:hover {
  background: rgba(255, 255, 255, 0.06);
  border-color: rgba(255, 255, 255, 0.14);
}

.settings-subtitle {
  margin: 0 0 16px;
  color: rgba(255, 255, 255, 0.62);
  font-size: 14px;
  line-height: 1.45;
}

.settings-nav-row {
  width: 100%;
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 14px;
  padding: 14px 16px;
  border-radius: 16px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(255, 255, 255, 0.035);
  color: white;
  text-align: left;
  cursor: pointer;
  transition: all 0.24s ease;
}

.settings-nav-row:hover {
  border-color: rgba(236, 72, 153, 0.28);
  background: rgba(236, 72, 153, 0.08);
}

.settings-nav-icon {
  width: 38px;
  height: 38px;
  border-radius: 12px;
  display: grid;
  place-items: center;
  color: #f9a8d4;
  background: rgba(236, 72, 153, 0.12);
}

.settings-nav-copy {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}

.settings-nav-copy strong {
  font-size: 15px;
}

.settings-nav-copy span {
  color: rgba(255, 255, 255, 0.58);
  font-size: 12px;
}

.password-panel {
  min-height: 280px;
}

.stat-label { color: rgba(255, 255, 255, 0.7); font-size: 14px; font-weight: 500; }

.stat-value {
  color: #f8fafc;
  font-weight: 700;
  font-size: 16px;
}

.btn-primary {
  width: 100%;
  padding: 14px 24px;
  border-radius: 12px;
  border: none;
  font-weight: 600;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-top: 14px;
}

.btn-primary {
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  color: white;
  box-shadow: 0 4px 12px rgba(236, 72, 153, 0.3);
}

.btn-primary:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(236, 72, 153, 0.4);
}

.btn-primary:disabled { opacity: 0.5; cursor: not-allowed; transform: none; }

.account-actions {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.account-action-btn {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px 16px;
  border-radius: 16px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(255, 255, 255, 0.035);
  color: white;
  text-align: left;
  cursor: pointer;
  transition: all 0.25s ease;
}

.account-action-btn:hover {
  border-color: rgba(236, 72, 153, 0.24);
  background: rgba(255, 255, 255, 0.06);
}

.account-action-danger:hover {
  border-color: rgba(239, 68, 68, 0.24);
}

.account-action-icon {
  width: 38px;
  height: 38px;
  border-radius: 12px;
  display: grid;
  place-items: center;
  flex-shrink: 0;
  font-size: 18px;
  font-weight: 700;
}

.logout-icon {
  background: rgba(236, 72, 153, 0.14);
  color: #fda4af;
}

.delete-icon {
  background: rgba(239, 68, 68, 0.12);
  color: #fca5a5;
}

.account-action-copy {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.account-action-copy strong {
  font-size: 15px;
}

.account-action-copy span {
  color: rgba(255, 255, 255, 0.58);
  font-size: 12px;
}

/* ── Transitions ── */
.settings-enter-active, .settings-leave-active { transition: opacity 0.3s ease; }
.settings-enter-from, .settings-leave-to { opacity: 0; }
.settings-enter-active .settings-sidebar,
.settings-leave-active .settings-sidebar { transition: transform 0.4s cubic-bezier(0.4, 0, 0.2, 1); }
.settings-enter-from .settings-sidebar,
.settings-leave-to .settings-sidebar { transform: translateX(100%); }

.settings-content::-webkit-scrollbar { width: 8px; }
.settings-content::-webkit-scrollbar-track { background: rgba(0,0,0,0.2); border-radius: 10px; }
.settings-content::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.2); border-radius: 10px; }
.settings-content::-webkit-scrollbar-thumb:hover { background: rgba(255,255,255,0.3); }

/* ════════════════════════════════
   RESPONSIVE
   ════════════════════════════════ */

/* Tablet landscape (1200px) */
@media (max-width: 1200px) {
  .stats-overview {
    grid-template-columns: repeat(2, 1fr);
  }

  .achievements-grid {
    grid-template-columns: repeat(4, 1fr);
    grid-template-rows: repeat(1, auto);
  }
}

/* Tablet portrait (1024px) */
@media (max-width: 1024px) {
  .profile-content { padding: 28px; }

  .achievements-grid {
    grid-template-columns: repeat(2, 1fr);
    grid-template-rows: repeat(2, auto);
  }

  .days-grid { gap: 8px; }

  .day-card { padding: 12px 6px; }

  .day-name { font-size: 11px; }
  .day-date { font-size: 9px; }
  .day-duration { font-size: 9px; }

  .star-icon img { width: 30px; height: 30px; }
}

/* Tablet small (768px) */
@media (max-width: 768px) {
  .profile-content { padding: 20px; }

  .profile-summary-card {
    flex-direction: column;
    gap: 12px;
    align-items: stretch;
  }

  .profile-summary-main {
    width: 100%;
  }

  .profile-title { font-size: 26px; }

  .settings-btn { justify-content: center; width: 100%; }

  .stats-overview {
    grid-template-columns: repeat(2, 1fr);
    gap: 16px;
    margin-bottom: 32px;
  }

  .achievements-section,
  .activity-section,
  .recent-section {
    padding: 20px;
    border-radius: 18px;
  }

  .section-header h2 { font-size: 20px; }

  .achievements-grid {
    grid-template-columns: repeat(2, 1fr);
    grid-template-rows: repeat(2, auto);
    gap: 12px;
  }

  /* Calendar: horizontal scroll on mobile */
  .activity-calendar {
    flex-direction: column;
    gap: 12px;
  }

  .week-nav-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .week-nav {
    width: 40px;
    height: 40px;
    min-height: unset;
  }

  .days-grid {
    display: grid;
    grid-template-columns: repeat(7, minmax(44px, 1fr));
    gap: 6px;
    overflow-x: auto;
    padding-bottom: 4px;
  }

  .day-card {
    padding: 10px 4px;
    border-radius: 10px;
    min-width: 44px;
  }

  .day-name { font-size: 10px; }
  .day-date { font-size: 9px; display: none; }
  .day-duration { font-size: 9px; display: none; }

  .day-indicator { width: 28px; height: 28px; }
  .star-icon img { width: 26px; height: 26px; }
  .empty-icon { font-size: 18px; }

  /* Borrow the nav buttons on either side in a row */
  .activity-calendar {
    flex-direction: row;
    align-items: center;
  }

  .settings-sidebar { max-width: 100%; }
}

/* Mobile (480px) */
@media (max-width: 480px) {
  .profile-content { padding: 16px; }

  .profile-title { font-size: 22px; }

  .profile-summary-card {
    padding: 18px;
  }

  .profile-avatar {
    width: 64px;
    height: 64px;
    font-size: 1.2rem;
  }

  .stats-overview {
    grid-template-columns: 1fr 1fr;
    gap: 12px;
  }

  .achievements-section,
  .activity-section,
  .recent-section {
    padding: 16px;
    margin-bottom: 24px;
  }

  .section-header { margin-bottom: 16px; }
  .section-header h2 { font-size: 17px; }

  .achievement-count { font-size: 12px; padding: 6px 10px; }

  .achievements-grid {
    grid-template-columns: repeat(2, 1fr);
    gap: 8px;
  }

  .achievement-card {
    min-height: 120px;
    padding: 14px 10px;
  }

  .achievement-title {
    font-size: 12px;
  }

  .achievement-description {
    font-size: 10px;
  }

  .achievement-icon svg {
    width: 28px;
    height: 28px;
  }

  .carousel-btn {
    width: 36px;
    height: 36px;
    font-size: 16px;
  }

  .days-grid {
    grid-template-columns: repeat(7, minmax(38px, 1fr));
    gap: 4px;
  }

  .day-card {
    padding: 8px 2px;
    gap: 4px;
    border-radius: 8px;
    min-width: 38px;
  }

  .day-name { font-size: 9px; }

  .day-indicator { width: 24px; height: 24px; }
  .star-icon img { width: 22px; height: 22px; }

  .week-nav {
    width: 34px;
    height: 34px;
    font-size: 16px;
  }

  .settings-header { padding: 20px; }
  .settings-header h2 { font-size: 22px; }
  .settings-content { padding: 20px; }
}
</style>
