<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import { ChevronLeft, ChevronRight, Dumbbell, Flame, Timer, Trophy, X } from 'lucide-vue-next';
import { resolveMediaUrl, userService } from '@/services/api';
import noProfilePicture from '@/assets/Nopfp.png';
import starPixel from '@/assets/Star_Pixel.png';

const props = defineProps<{
  userId: number | null;
  visible: boolean;
}>();

const emit = defineEmits<{
  close: [];
}>();

const loading = ref(false);
const failed = ref(false);
const profile = ref<any>(null);
const achievementPage = ref(0);

const profileImageUrl = computed(() => resolveMediaUrl(profile.value?.profileImageUrl ?? profile.value?.ProfileImageUrl ?? ''));
const avatar = computed(() => profile.value?.avatar ?? profile.value?.Avatar ?? {});
const stats = computed(() => profile.value?.stats ?? profile.value?.Stats ?? {});
const achievements = computed<any[]>(() => profile.value?.achievements ?? profile.value?.Achievements ?? []);
const rawWeeklyActivity = computed<any[]>(() => profile.value?.weeklyActivity ?? profile.value?.WeeklyActivity ?? []);
const recentActivities = computed<any[]>(() => profile.value?.recentActivities ?? profile.value?.RecentActivities ?? []);

const unlockedAchievements = computed(() => achievements.value.filter((item) => item.unlocked ?? item.Unlocked).length);
const maxAchievementPage = computed(() => Math.max(0, Math.ceil(achievements.value.length / 4) - 1));
const visibleAchievements = computed(() => {
  const start = achievementPage.value * 4;
  return achievements.value.slice(start, start + 4);
});
const bodyStage = computed(() => avatar.value.bodyStage ?? avatar.value.BodyStage ?? '');
const level = computed(() => avatar.value.level ?? avatar.value.Level ?? profile.value?.level ?? profile.value?.Level ?? 0);
const totalXp = computed(() => profile.value?.totalXp ?? profile.value?.TotalXp ?? avatar.value.experience ?? avatar.value.Experience ?? 0);

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

const formatTime = (raw: string) => {
  if (!raw) return '';
  const date = new Date(raw);
  if (Number.isNaN(date.getTime())) return '';
  const diffMs = Date.now() - date.getTime();
  const diffMin = Math.floor(diffMs / 60000);
  const diffH = Math.floor(diffMin / 60);
  const diffD = Math.floor(diffH / 24);
  if (diffMin < 1) return 'Gerade eben';
  if (diffMin < 60) return `vor ${diffMin} Minuten`;
  if (diffH < 24) return `vor ${diffH} Stunde${diffH > 1 ? 'n' : ''}`;
  if (diffD === 1) return 'Gestern';
  if (diffD < 7) return `vor ${diffD} Tagen`;
  return date.toLocaleDateString('de-DE');
};

const dateKey = (date: Date) =>
  `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;

const weeklyActivity = computed(() => {
  const today = new Date();
  const normalizedToday = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  const monday = new Date(normalizedToday);
  monday.setDate(normalizedToday.getDate() - normalizedToday.getDay() + (normalizedToday.getDay() === 0 ? -6 : 1));
  const repsByDate = new Map<string, number>();

  rawWeeklyActivity.value.forEach((item) => {
    const rawDate = String(item.date ?? item.Date ?? '');
    if (!rawDate) return;
    const normalizedDate = rawDate.includes('T') ? (rawDate.split('T')[0] ?? rawDate) : rawDate;
    repsByDate.set(normalizedDate, Number(item.reps ?? item.Reps ?? 0));
  });

  const names = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  const todayKey = dateKey(normalizedToday);
  return Array.from({ length: 7 }, (_, index) => {
    const day = new Date(monday);
    day.setDate(monday.getDate() + index);
    const key = dateKey(day);
    const reps = repsByDate.get(key) ?? 0;
    return {
      key,
      name: names[index] ?? '',
      dateDisplay: `${String(day.getDate()).padStart(2, '0')}.${String(day.getMonth() + 1).padStart(2, '0')}`,
      reps,
      workoutDone: reps > 0,
      isToday: key === todayKey,
    };
  });
});

const weekLabel = computed(() => {
  if (!weeklyActivity.value.length) return '';
  const first = weeklyActivity.value[0];
  const last = weeklyActivity.value[weeklyActivity.value.length - 1];
  return `${first?.dateDisplay ?? ''} - ${last?.dateDisplay ?? ''}`;
});

const statCards = computed(() => [
  { label: 'Workouts gesamt', value: String(stats.value.totalWorkouts ?? stats.value.TotalWorkouts ?? 0), icon: Dumbbell, color: '#a855f7' },
  { label: 'Trainingszeit', value: `${Number(stats.value.trainingHours ?? stats.value.TrainingHours ?? 0).toFixed(1)}h`, icon: Timer, color: '#60a5fa' },
  { label: 'Kalorien', value: String(stats.value.caloriesBurned ?? stats.value.CaloriesBurned ?? 0), icon: Flame, color: '#f97316' },
  { label: 'Längster Streak', value: `${stats.value.longestStreak ?? stats.value.LongestStreak ?? 0} Tage`, icon: Trophy, color: '#22c55e' },
]);

watch(
  () => [props.visible, props.userId] as const,
  async ([visible, userId]) => {
    if (!visible || !userId) return;
    loading.value = true;
    failed.value = false;
    try {
      const { data } = await userService.getPublicProfile(userId);
      profile.value = data;
      achievementPage.value = 0;
    } catch {
      failed.value = true;
      profile.value = null;
    } finally {
      loading.value = false;
    }
  },
  { immediate: true },
);
</script>

<template>
  <Teleport to="body">
    <Transition name="sheet">
      <div v-if="visible" class="sheet-backdrop" @click.self="emit('close')">
        <section class="profile-sheet">
          <div class="sheet-handle"></div>
          <button class="close-btn" type="button" @click="emit('close')" aria-label="Schließen">
            <X :size="18" />
          </button>

          <div v-if="loading" class="sheet-state">Profil wird geladen...</div>
          <div v-else-if="failed" class="sheet-state">Profil konnte nicht geladen werden.</div>
          <template v-else-if="profile">
            <header class="profile-head">
              <img :src="profileImageUrl || noProfilePicture" alt="" class="profile-image" />
              <div class="profile-copy">
                <h2>{{ profile.userName ?? profile.UserName }}</h2>
                <p>Level {{ level }} • {{ formatCompact(totalXp) }} XP</p>
                <span v-if="bodyStage" class="body-pill">{{ bodyStage }}</span>
              </div>
            </header>

            <section class="sheet-card">
              <h3>Statistiken</h3>
              <div class="stats-grid">
                <article v-for="item in statCards" :key="item.label" class="stat-card">
                  <component :is="item.icon" :size="22" :style="{ color: item.color }" />
                  <div>
                    <span>{{ item.label }}</span>
                    <strong>{{ item.value }}</strong>
                  </div>
                </article>
              </div>
            </section>

            <section class="sheet-card">
              <div class="card-title-row">
                <div>
                  <h3>Achievements</h3>
                  <p class="muted">{{ unlockedAchievements }} / {{ achievements.length }} freigeschaltet</p>
                </div>
                <div v-if="achievements.length > 4" class="pager-actions">
                  <button type="button" :disabled="achievementPage === 0" @click="achievementPage--" aria-label="Vorherige Achievements">
                    <ChevronLeft :size="20" />
                  </button>
                  <button type="button" :disabled="achievementPage >= maxAchievementPage" @click="achievementPage++" aria-label="Nächste Achievements">
                    <ChevronRight :size="20" />
                  </button>
                </div>
              </div>
              <div v-if="visibleAchievements.length" class="achievements-grid">
                <article
                  v-for="achievement in visibleAchievements"
                  :key="achievement.id ?? achievement.Id ?? achievement.key ?? achievement.Key"
                  class="achievement-card"
                  :class="{ unlocked: achievement.unlocked ?? achievement.Unlocked }"
                >
                  <strong>{{ achievement.title ?? achievement.Title }}</strong>
                  <span>{{ achievement.description ?? achievement.Description }}</span>
                </article>
              </div>
              <p v-else class="muted">Noch keine Achievements vorhanden.</p>
            </section>

            <section class="sheet-card">
              <h3>Wöchentliche Aktivität</h3>
              <p class="muted">{{ weekLabel }}</p>
              <div class="week-row">
                <article
                  v-for="day in weeklyActivity"
                  :key="day.key"
                  class="day-card"
                  :class="{ today: day.isToday, done: day.workoutDone }"
                >
                  <strong>{{ day.name }}</strong>
                  <span>{{ day.dateDisplay }}</span>
                  <img v-if="day.workoutDone" :src="starPixel" alt="" />
                  <em v-else>-</em>
                  <small>{{ day.reps ? `${day.reps} Reps` : '-' }}</small>
                </article>
              </div>
            </section>

            <section class="sheet-card">
              <h3>Letzte Aktivitäten</h3>
              <div v-if="recentActivities.length" class="recent-list">
                <article v-for="activity in recentActivities" :key="activity.id ?? activity.Id">
                  <div>
                    <strong>{{ activity.title ?? activity.Title }}</strong>
                    <span>{{ formatTime(activity.timestamp ?? activity.Timestamp) }}</span>
                  </div>
                  <b>{{ formatCompact(activity.xp ?? activity.Xp ?? 0) }} XP</b>
                </article>
              </div>
              <p v-else class="muted">Noch keine letzten Aktivitäten vorhanden.</p>
            </section>
          </template>
        </section>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.sheet-backdrop {
  position: fixed;
  inset: 0;
  z-index: 5000;
  display: flex;
  align-items: flex-end;
  justify-content: center;
  background: rgba(2, 6, 23, 0.64);
  backdrop-filter: blur(8px);
}

.profile-sheet {
  position: relative;
  width: min(760px, 100%);
  max-height: 90vh;
  overflow-y: auto;
  padding: 14px 28px 28px 18px;
  border-radius: 24px 24px 0 0;
  background: #0f172a;
  border: 1px solid rgba(255, 255, 255, 0.08);
  color: white;
}

.sheet-handle {
  width: 44px;
  height: 4px;
  margin: 0 auto 18px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.16);
}

.close-btn {
  position: absolute;
  top: 14px;
  right: 34px;
  z-index: 4;
  width: 36px;
  height: 36px;
  border: 0;
  border-radius: 999px;
  display: grid;
  place-items: center;
  color: white;
  background: rgba(255, 255, 255, 0.08);
  cursor: pointer;
}

.profile-head {
  display: flex;
  align-items: center;
  gap: 18px;
  margin-bottom: 18px;
}

.profile-image {
  width: 92px;
  height: 92px;
  border-radius: 50%;
  object-fit: cover;
}

.profile-copy h2 {
  margin: 0 0 8px;
  font-size: 2rem;
}

.profile-copy p {
  margin: 0 0 10px;
  color: rgba(255, 255, 255, 0.66);
  font-weight: 700;
}

.body-pill {
  display: inline-flex;
  border-radius: 999px;
  padding: 6px 12px;
  color: rgba(255, 255, 255, 0.72);
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.08);
  font-weight: 800;
}

.sheet-card {
  margin-top: 12px;
  padding: 20px;
  border-radius: 18px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.08);
}

.sheet-card h3 {
  margin: 0 0 12px;
  font-size: 1.25rem;
}

.card-title-row {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 16px;
  margin-bottom: 12px;
}

.card-title-row h3,
.card-title-row .muted {
  margin-bottom: 0;
}

.pager-actions {
  display: flex;
  gap: 10px;
  flex: 0 0 auto;
}

.pager-actions button {
  width: 42px;
  height: 42px;
  padding: 0;
  display: grid;
  place-items: center;
  border: 1px solid rgba(255, 255, 255, 0.14);
  border-radius: 999px;
  color: white;
  background: rgba(255, 255, 255, 0.075);
  cursor: pointer;
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.05);
  transition: background 0.2s ease, border-color 0.2s ease, transform 0.2s ease, opacity 0.2s ease;
}

.pager-actions button:not(:disabled):hover {
  background: rgba(236, 72, 153, 0.18);
  border-color: rgba(236, 72, 153, 0.4);
  transform: translateY(-1px);
}

.pager-actions button:disabled {
  opacity: 0.42;
  cursor: default;
}

.muted {
  margin: 0 0 12px;
  color: rgba(255, 255, 255, 0.66);
  font-weight: 700;
}

.stats-grid,
.achievements-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
}

.stat-card,
.achievement-card {
  min-height: 96px;
  padding: 16px;
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.08);
}

.stat-card {
  display: flex;
  align-items: center;
  gap: 14px;
}

.stat-card span,
.achievement-card span,
.recent-list span {
  display: block;
  color: rgba(255, 255, 255, 0.62);
}

.stat-card strong {
  display: block;
  margin-top: 6px;
  font-size: 1.25rem;
}

.achievement-card {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.achievement-card.unlocked {
  background: rgba(251, 191, 36, 0.12);
  border-color: rgba(251, 191, 36, 0.38);
}

.week-row {
  display: flex;
  gap: 8px;
  overflow-x: auto;
}

.day-card {
  width: 104px;
  flex: 0 0 104px;
  padding: 12px 8px;
  border-radius: 14px;
  text-align: center;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.08);
}

.day-card.today {
  border-color: #fbbf24;
}

.day-card.done {
  background: rgba(20, 83, 45, 0.42);
}

.day-card span,
.day-card small,
.day-card em {
  display: block;
  margin-top: 6px;
  color: rgba(255, 255, 255, 0.62);
  font-style: normal;
}

.day-card img {
  width: 22px;
  height: 22px;
  margin-top: 10px;
}

.recent-list {
  display: grid;
  gap: 12px;
}

.recent-list article {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.recent-list b {
  flex: 0 0 auto;
  color: #fde047;
}

.sheet-state {
  padding: 48px 16px;
  text-align: center;
  color: rgba(255, 255, 255, 0.72);
}

.sheet-enter-active,
.sheet-leave-active {
  transition: opacity 0.2s ease;
}

.sheet-enter-from,
.sheet-leave-to {
  opacity: 0;
}

.sheet-enter-active .profile-sheet,
.sheet-leave-active .profile-sheet {
  transition: transform 0.22s ease;
}

.sheet-enter-from .profile-sheet,
.sheet-leave-to .profile-sheet {
  transform: translateY(28px);
}

@media (max-width: 640px) {
  .stats-grid,
  .achievements-grid {
    grid-template-columns: 1fr;
  }

  .profile-image {
    width: 74px;
    height: 74px;
  }

  .profile-copy h2 {
    font-size: 1.5rem;
  }
}
</style>
