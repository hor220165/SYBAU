<template>
  <!-- Header -->
  <Header></Header>

  <!-- Navigation -->
  <Navbar></Navbar>

  <!-- Main Content -->
  <main class="profile-content">
    <!-- Header with Settings Button -->
    <div class="profile-header">
      <h1 class="profile-title">Mein Profil</h1>
      <button class="settings-btn" @click="showSettings = true">
        <span class="icon">⚙️</span>
        Einstellungen
      </button>
    </div>

    <!-- Stats Overview Cards -->
    <div class="stats-overview">
      <StatCard
          icon="🎯"
          label="Workouts gesamt"
          value="124"
          cardClass="stat-purple"
      />
      <StatCard
          icon="📅"
          label="Trainingszeit"
          value="42.5h"
          cardClass="stat-blue"
      />
      <StatCard
          icon="🔥"
          label="Kalorien verbrannt"
          value="18,450"
          cardClass="stat-orange"
      />
      <StatCard
          icon="📈"
          label="Längster Streak"
          value="15 Tage"
          cardClass="stat-green"
      />
    </div>

    <!-- Achievements Section -->
    <section class="achievements-section">
      <div class="section-header">
        <div class="title-row">
          <span class="section-icon">🏆</span>
          <h2>Achievements</h2>
        </div>
        <span class="achievement-count">{{ unlockedCount }} / {{ totalAchievements }} freigeschaltet</span>
      </div>

      <div class="achievements-carousel">
        <button 
          class="carousel-btn prev" 
          @click="previousAchievements"
          :disabled="currentAchievementIndex === 0"
        >
          ←
        </button>

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

        <button 
          class="carousel-btn next" 
          @click="nextAchievements"
          :disabled="currentAchievementIndex >= achievements.length - 4"
        >
          →
        </button>
      </div>
    </section>

    <!-- Weekly Activity Calendar -->
    <section class="activity-section">
  <div class="section-header">
    <div class="title-row">
      <span class="section-icon">📅</span>
      <h2>Wöchentliche Aktivität</h2>
    </div>
  </div>

  <div class="activity-calendar">
    <button 
      class="week-nav prev" 
      @click="previousWeek"
    >
      ←
    </button>

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
          <span v-else class="empty-icon">–</span>
        </div>
        <span class="day-duration">{{ day.duration }}</span>
      </div>
    </div>

    <button 
      class="week-nav next" 
      @click="nextWeek"
      :disabled="isCurrentWeek"
    >
      →
    </button>
  </div>
</section>

    <!-- Recent Activities -->
    <section class="recent-section">
      <div class="section-header">
        <div class="title-row">
          <span class="section-icon">📊</span>
          <h2>Letzte Aktivitäten</h2>
        </div>
      </div>

      <div class="activities-list">
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
    </section>
  </main>

  <!-- Settings Sidebar Modal -->
  <Teleport to="body">
    <Transition name="settings">
      <div v-if="showSettings" class="settings-overlay" @click="showSettings = false">
        <div class="settings-sidebar" @click.stop>
          <!-- Header -->
          <div class="settings-header">
            <h2>Einstellungen</h2>
            <button class="close-btn" @click="showSettings = false">✕</button>
          </div>

          <!-- Content -->
          <div class="settings-content">
            <!-- Profile Section -->
            <section class="settings-section">
              <h3>Profil</h3>
              <div class="field">
                <label>Benutzername</label>
                <input v-model="editingUsername" />
              </div>
              <div class="field">
                <label>E-Mail</label>
                <input :value="user?.email ?? user?.Email ?? ''" readonly />
              </div>
              <button class="btn-primary" @click="saveProfile" :disabled="savingProfile">
                Speichern
              </button>
            </section>

            <!-- Progress Section -->
            <section class="settings-section">
              <h3>Fortschritt</h3>
              <div class="progress-stats">
                <div class="stat-row">
                  <span class="stat-label">Level:</span>
                  <span class="stat-value">{{ level }}</span>
                </div>
                <div class="stat-row">
                  <span class="stat-label">XP:</span>
                  <span class="stat-value">{{ experience }}</span>
                </div>
                <div class="stat-row">
                  <span class="stat-label">Absolvierte Challenges:</span>
                  <span class="stat-value">{{ completedChallenges }}</span>
                </div>
                <div class="stat-row">
                  <span class="stat-label">Leaderboard-Position:</span>
                  <span class="stat-value">{{ leaderboardPosition }}</span>
                </div>
              </div>
            </section>

            <!-- Security Section -->
            <section class="settings-section">
              <h3>Sicherheit</h3>
              <div class="field">
                <label>Altes Passwort</label>
                <input type="password" v-model="oldPassword" />
              </div>
              <div class="field">
                <label>Neues Passwort</label>
                <input type="password" v-model="newPassword" />
              </div>
              <button class="btn-primary" @click="changePassword" :disabled="changingPassword">
                Passwort ändern
              </button>
            </section>

            <!-- Danger Zone -->
            <section class="settings-section danger-zone">
              <h3>Gefahrenzone</h3>
              <p>Diese Aktion ist endgültig und kann nicht rückgängig gemacht werden.</p>
              <button class="btn-danger" @click="deleteAccount">
                Account löschen
              </button>
            </section>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import Header from '@/components/Header.vue';
import Navbar from '@/components/Navbar.vue';
import StatCard from '@/components/StatCard.vue';
import AchievementCard from '@/components/AchievementCard.vue';
import ActivityItem from '@/components/ActivityItem.vue';
import { useAuth } from '@/composables/useAuth';
import { useLeaderboard } from '@/composables/useLeaderboard';
import { userService } from '@/services/api';

const router = useRouter();
const { user, logout } = useAuth();
const { sortedLeaderboard, loadLeaderboard } = useLeaderboard();

// Settings Modal
const showSettings = ref(false);

// Profile editing
const editingUsername = ref<string>(user.value?.username ?? user.value?.UserName ?? '');
const savingProfile = ref(false);

async function saveProfile() {
  savingProfile.value = true;
  try {
    await userService.updateProfile({ UserName: editingUsername.value });
    const u = { ...user.value };
    if ('username' in u) u.username = editingUsername.value;
    else u.UserName = editingUsername.value;
    user.value = u;
    localStorage.setItem('user', JSON.stringify(u));
    alert('Profil gespeichert!');
  } catch (err: any) {
    if (err.response?.status === 401) {
      alert('Session abgelaufen. Bitte melden Sie sich erneut an.');
      logout();
      router.push('/auth');
    } else {
      alert('Fehler beim Speichern: ' + (err.response?.data?.message || err.message));
    }
  } finally {
    savingProfile.value = false;
  }
}

// Progress
const level = computed(() => user.value?.avatar?.level ?? user.value?.avatar?.Level ?? 1);
const experience = computed(() => user.value?.avatar?.experience ?? user.value?.avatar?.Experience ?? 0);
const completedChallenges = ref(0);
const leaderboardPosition = computed(() => {
  const name = user.value?.username ?? user.value?.UserName ?? user.value?.userName ?? '';
  const idx = sortedLeaderboard.value.findIndex((u: any) => (u.UserName ?? u.username ?? '').toLowerCase() === name.toLowerCase());
  if (idx >= 0 && idx < sortedLeaderboard.value.length) {
    const rank = sortedLeaderboard.value[idx]?.Rank;
    return rank ?? idx + 1;
  }
  return '—';
});

// Security
const oldPassword = ref('');
const newPassword = ref('');
const changingPassword = ref(false);

async function changePassword() {
  if (!oldPassword.value || !newPassword.value) return alert('Bitte beide Felder ausfüllen.');
  changingPassword.value = true;
  try {
    await userService.changePassword(oldPassword.value, newPassword.value);
    oldPassword.value = '';
    newPassword.value = '';
    alert('Passwort erfolgreich geändert!');
  } catch (err: any) {
    if (err.response?.status === 401) {
      alert('Session abgelaufen. Bitte melden Sie sich erneut an.');
      logout();
      router.push('/auth');
    } else {
      alert(err.response?.data);
    }
  } finally {
    changingPassword.value = false;
  }
}

async function deleteAccount() {
  if (!confirm('Account wirklich löschen? Diese Aktion ist endgültig.')) return;
  try {
    await userService.deleteAccount();
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    logout();
    router.push('/auth');
  } catch (err: any) {
    alert('Fehler beim Löschen: ' + (err.response?.data?.message || err.message));
  }
}

// Achievements
const currentAchievementIndex = ref(0);

const achievements = ref([
  { id: 1, icon: '🏃', title: 'Speedster', description: 'Laufe 5km unter 25 Min', unlocked: true },
  { id: 2, icon: '💪', title: 'Iron Body', description: 'Hebe 1000kg gesamt', unlocked: true },
  { id: 3, icon: '🔥', title: 'On Fire', description: '5-Tage Streak', unlocked: true },
  { id: 4, icon: '🎯', title: 'Quest Hunter', description: '10 Quests abschließen', unlocked: true },
  { id: 5, icon: '⭐', title: 'Rising Star', description: 'Level 10 erreichen', unlocked: true },
  { id: 6, icon: '👑', title: 'Champion', description: 'Platz 1 im Leaderboard', unlocked: false },
  { id: 7, icon: '🏆', title: 'Legend', description: 'Level 25 erreichen', unlocked: false },
  { id: 8, icon: '💯', title: 'Perfectionist', description: 'Alle Daily Quests 30 Tage', unlocked: false },
  { id: 9, icon: '🚀', title: 'Sky Rocket', description: 'Erreiche Level 50', unlocked: true },
  { id: 10, icon: '💎', title: 'Diamond Grind', description: 'Trainiere 100 Tage in Folge', unlocked: true },
  { id: 11, icon: '⚡', title: 'Speed Demon', description: '10km unter 40 Minuten', unlocked: false },
  { id: 12, icon: '🎖️', title: 'Workout Warrior', description: '500 Workouts absolviert', unlocked: false },
  { id: 13, icon: '🔱', title: 'Triathlon Master', description: 'Schwimmen, Laufen ... in einer Woche', unlocked: false },
  { id: 14, icon: '🌟', title: 'Shining Star', description: '60-Tage Streak', unlocked: false },
  { id: 15, icon: '🦾', title: 'Bionic', description: '1000 Liegestütze in 7 Tagen', unlocked: false },
  { id: 16, icon: '🏅', title: 'Elite Athlete', description: 'Alle Monthly Quests 3 Monate', unlocked: false }
]);

const visibleAchievements = computed(() => {
  return achievements.value.slice(currentAchievementIndex.value, currentAchievementIndex.value + 8);
});

const unlockedCount = computed(() => achievements.value.filter(a => a.unlocked).length);
const totalAchievements = computed(() => achievements.value.length);

const previousAchievements = () => {
  if (currentAchievementIndex.value > 0) currentAchievementIndex.value -= 8;
};

const nextAchievements = () => {
  if (currentAchievementIndex.value < achievements.value.length - 8) currentAchievementIndex.value += 8;
};

// Weekly Activity
const currentWeekOffset = ref(0);

const getWeekDays = (offset: number) => {
  const today = new Date();
  const currentDay = today.getDay();
  const monday = new Date(today);
  monday.setDate(today.getDate() - currentDay + (currentDay === 0 ? -6 : 1) + (offset * 7));

  const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  const weekDays = [];

  for (let i = 0; i < 7; i++) {
    const date = new Date(monday);
    date.setDate(monday.getDate() + i);
    
    const isToday = date.toDateString() === today.toDateString();
    
    // Datum formatieren (DD.MM)
    const dateDisplay = `${date.getDate().toString().padStart(2, '0')}.${(date.getMonth() + 1).toString().padStart(2, '0')}`;
    
    // Dummy data - später vom Backend
    const workoutDone = i < 5 && offset === 0;
    const duration = workoutDone ? '45 min' : '–';

    weekDays.push({
      name: days[i],
      date: date.toISOString(),
      dateDisplay, // ← NEU
      workoutDone,
      duration,
      isToday
    });
  }

  return weekDays;
};

const currentWeekDays = computed(() => getWeekDays(currentWeekOffset.value));
const isCurrentWeek = computed(() => currentWeekOffset.value === 0);

const previousWeek = () => { currentWeekOffset.value--; };
const nextWeek = () => { if (!isCurrentWeek.value) currentWeekOffset.value++; };

// Recent Activities
const recentActivities = ref([
  { id: 1, icon: '🎯', title: 'HIIT Blast absolviert', time: 'vor 2 Stunden', xp: 350, type: 'workout' },
  { id: 2, icon: '🏆', title: "Quest 'Cardio Champion' abgeschlossen", time: 'vor 5 Stunden', xp: 500, type: 'quest' },
  { id: 3, icon: '🏅', title: "Achievement 'On Fire' freigeschaltet", time: 'Heute', xp: 200, type: 'achievement' },
  { id: 4, icon: '⚡', title: 'Level 12 erreicht!', time: 'Gestern', xp: 0, type: 'level' }
]);

onMounted(async () => {
  try {
    await userService.getProfile();
    user.value = JSON.parse(localStorage.getItem('user') || '{}');
    editingUsername.value = user.value.userName;
    await loadLeaderboard();
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

/* Profile Header */
.profile-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 40px;
}

.profile-title {
  font-size: 32px;
  font-weight: 700;
  color: white;
  margin: 0;
}

.settings-btn {
  padding: 12px 24px;
  border-radius: 12px;
  border: none;
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  color: white;
  font-weight: 600;
  font-size: 16px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.3s ease;
}

.settings-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(236, 72, 153, 0.3);
}

/* Stats Overview */
.stats-overview {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 24px;
  margin-bottom: 48px;
}

/* Section Styles */
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
}

.title-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.section-icon {
  font-size: 28px;
}

.section-header h2 {
  font-size: 24px;
  font-weight: 700;
  color: white;
  margin: 0;
}

.achievement-count {
  padding: 8px 16px;
  background: rgba(168, 85, 247, 0.2);
  border: 1px solid rgba(168, 85, 247, 0.4);
  border-radius: 12px;
  font-size: 14px;
  font-weight: 600;
  color: #a855f7;
}

/* Achievements Carousel */
.achievements-carousel {
  display: flex;
  align-items: center;
  gap: 20px;
}

.carousel-btn {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  background: rgba(30, 41, 59, 0.6);
  color: white;
  font-size: 24px;
  cursor: pointer;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
  flex-shrink: 0;
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
  grid-template-rows: repeat(2, 1fr);
  gap: 20px;
  flex: 1;
}

/* Activity Calendar */
.activity-calendar {
  display: flex;
  align-items: center;
  gap: 20px;
}

.week-nav {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  background: rgba(30, 41, 59, 0.6);
  color: white;
  font-size: 24px;
  cursor: pointer;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
  flex-shrink: 0;
}

.week-nav:hover:not(:disabled) {
  background: rgba(59, 130, 246, 0.3);
  border-color: rgba(59, 130, 246, 0.5);
  transform: scale(1.1);
}

.week-nav:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.days-grid {
  display: grid;
  grid-template-columns: repeat(7, 1fr);
  gap: 16px;
  flex: 1;
}

.day-card {
  background: rgba(30, 41, 59, 0.6);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  padding: 16px 12px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
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
  font-size: 13px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.8);
}

.day-date {
  font-size: 10px;
  color: rgba(255, 255, 255, 0.4);
  margin-top: -4px;
}

.day-indicator {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
}

.star-icon {
  filter: drop-shadow(0 0 10px rgba(251, 191, 36, 0.5));
  display: flex;
  align-items: center;
  justify-content: center;
}

.star-icon img {
  width: 32px;
  height: 32px;
  image-rendering: pixelated;
  image-rendering: -moz-crisp-edges;
  image-rendering: crisp-edges;
  filter: drop-shadow(0 0 10px rgba(251, 191, 36, 0.5));
}

.empty-icon {
  color: rgba(255, 255, 255, 0.2);
  font-size: 32px;
}

.day-duration {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.6);
}

/* Activities List */
.activities-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

/* Settings Sidebar */
.settings-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.8);
  backdrop-filter: blur(8px);
  z-index: 10000;
  display: flex;
  justify-content: flex-end;
}

.settings-sidebar {
  width: 100%;
  max-width: 500px;
  background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
  box-shadow: -8px 0 40px rgba(0, 0, 0, 0.6);
  display: flex;
  flex-direction: column;
  overflow: hidden;
  border-left: 1px solid rgba(255, 255, 255, 0.1);
}

.settings-header {
  padding: 28px 32px;
  background: rgba(30, 41, 59, 0.8);
  backdrop-filter: blur(20px);
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.settings-header h2 {
  font-size: 28px;
  font-weight: 700;
  color: white;
  margin: 0;
}

.close-btn {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  border: none;
  background: rgba(255, 255, 255, 0.1);
  color: white;
  font-size: 24px;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  justify-content: center;
}

.close-btn:hover {
  background: rgba(255, 255, 255, 0.2);
}

.settings-content {
  flex: 1;
  overflow-y: auto;
  padding: 32px;
  background: linear-gradient(180deg, rgba(15, 23, 42, 0.95) 0%, rgba(15, 23, 42, 1) 100%);
}

.settings-section {
  margin-bottom: 32px;
  padding: 24px;
  background: rgba(30, 41, 59, 0.5);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 20px;
}

.settings-section:last-child {
  margin-bottom: 0;
}

.settings-section h3 {
  font-size: 20px;
  font-weight: 700;
  color: white;
  margin: 0 0 20px 0;
  display: flex;
  align-items: center;
  gap: 10px;
}

.settings-section h3::before {
  content: '';
  width: 4px;
  height: 20px;
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  border-radius: 999px;
}

.field {
  margin-bottom: 20px;
}

.field label {
  display: block;
  font-size: 14px;
  color: #93c5fd;
  margin-bottom: 10px;
  font-weight: 600;
}

.field input {
  width: 100%;
  padding: 14px 18px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: rgba(0, 0, 0, 0.4);
  color: white;
  font-size: 15px;
  transition: all 0.3s ease;
}

.field input:focus {
  outline: none;
  border-color: rgba(236, 72, 153, 0.6);
  box-shadow: 0 0 0 3px rgba(236, 72, 153, 0.1);
}

.field input:read-only {
  opacity: 0.6;
  cursor: not-allowed;
  background: rgba(0, 0, 0, 0.2);
}

.progress-stats {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.stat-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  transition: all 0.3s ease;
}

.stat-row:hover {
  background: rgba(255, 255, 255, 0.08);
  border-color: rgba(236, 72, 153, 0.3);
}

.stat-label {
  color: rgba(255, 255, 255, 0.7);
  font-size: 14px;
  font-weight: 500;
}

.stat-value {
  color: white;
  font-weight: 700;
  font-size: 16px;
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.btn-primary,
.btn-danger {
  width: 100%;
  padding: 14px 24px;
  border-radius: 12px;
  border: none;
  font-weight: 600;
  font-size: 16px;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-top: 20px;
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

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  transform: none;
}

.btn-danger {
  background: linear-gradient(135deg, #ef4444, #b91c1c);
  color: white;
  box-shadow: 0 4px 12px rgba(239, 68, 68, 0.3);
}

.btn-danger:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 20px rgba(239, 68, 68, 0.4);
}

.danger-zone {
  background: rgba(239, 68, 68, 0.08);
  border: 1px solid rgba(239, 68, 68, 0.3);
  border-radius: 16px;
  padding: 24px;
}

.danger-zone h3::before {
  background: linear-gradient(135deg, #ef4444, #b91c1c);
}

.danger-zone p {
  color: rgba(255, 255, 255, 0.8);
  font-size: 14px;
  margin: 0 0 16px 0;
  line-height: 1.6;
}

/* Transitions */
.settings-enter-active,
.settings-leave-active {
  transition: opacity 0.3s ease;
}

.settings-enter-from,
.settings-leave-to {
  opacity: 0;
}

.settings-enter-active .settings-sidebar,
.settings-leave-active .settings-sidebar {
  transition: transform 0.4s cubic-bezier(0.4, 0, 0.2, 1);
}

.settings-enter-from .settings-sidebar,
.settings-leave-to .settings-sidebar {
  transform: translateX(100%);
}

/* Scrollbar Styling */
.settings-content::-webkit-scrollbar {
  width: 8px;
}

.settings-content::-webkit-scrollbar-track {
  background: rgba(0, 0, 0, 0.2);
  border-radius: 10px;
}

.settings-content::-webkit-scrollbar-thumb {
  background: rgba(255, 255, 255, 0.2);
  border-radius: 10px;
}

.settings-content::-webkit-scrollbar-thumb:hover {
  background: rgba(255, 255, 255, 0.3);
}

/* Responsive */
@media (max-width: 1200px) {
  .achievements-grid {
    grid-template-columns: repeat(2, 1fr);
    grid-template-rows: repeat(4, 1fr);
  }
}

@media (max-width: 768px) {
  .profile-content {
    padding: 20px;
  }

  .profile-header {
    flex-direction: column;
    gap: 16px;
    align-items: stretch;
  }

  .achievements-grid {
    grid-template-columns: 1fr;
    grid-template-rows: auto;
  }

  .days-grid {
    gap: 8px;
  }

  .day-card {
    padding: 10px 6px;
  }

  .settings-sidebar {
    max-width: 100%;
  }

  .stats-overview,
  .achievements-section,
  .activity-section,
  .recent-section {
    padding: 20px;
  }
}
</style>