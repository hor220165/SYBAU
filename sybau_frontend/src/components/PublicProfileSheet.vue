<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue';
import { ChevronLeft, ChevronRight, Dumbbell, Flame, Timer, Trophy, X } from 'lucide-vue-next';
import { resolveMediaUrl, userService } from '@/services/api';
import noProfilePicture from '@/assets/Nopfp.png';

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
const activityMode = ref<'workouts' | 'steps'>('workouts');
const windowWidth = ref(window.innerWidth);
const onResize = () => {
  windowWidth.value = window.innerWidth;
};

onMounted(() => window.addEventListener('resize', onResize));
onUnmounted(() => window.removeEventListener('resize', onResize));

const profileImageUrl = computed(() => resolveMediaUrl(profile.value?.profileImageUrl ?? profile.value?.ProfileImageUrl ?? ''));
const avatar = computed(() => profile.value?.avatar ?? profile.value?.Avatar ?? {});
const stats = computed(() => profile.value?.stats ?? profile.value?.Stats ?? {});
const achievements = computed<any[]>(() => profile.value?.achievements ?? profile.value?.Achievements ?? []);
const rawWeeklyActivity = computed<any[]>(() => profile.value?.weeklyActivity ?? profile.value?.WeeklyActivity ?? []);
const recentActivities = computed<any[]>(() => profile.value?.recentActivities ?? profile.value?.RecentActivities ?? []);
const activityYears = computed<number[]>(() => {
  const raw = profile.value?.activityYears ?? profile.value?.ActivityYears ?? [new Date().getFullYear()];
  return (Array.isArray(raw) ? raw : [raw])
    .map((year) => Number(year))
    .filter((year) => Number.isInteger(year) && year > 2000)
    .sort((a, b) => b - a);
});
const selectedActivityYear = computed(() => activityYears.value[0] ?? new Date().getFullYear());

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

const startOfDay = (date: Date) => new Date(date.getFullYear(), date.getMonth(), date.getDate());
const addDays = (date: Date, days: number) => {
  const next = new Date(date);
  next.setDate(next.getDate() + days);
  return next;
};
const mondayOf = (date: Date) => {
  const normalized = startOfDay(date);
  const weekday = normalized.getDay() === 0 ? 7 : normalized.getDay();
  normalized.setDate(normalized.getDate() - weekday + 1);
  return normalized;
};
const monthFormatter = new Intl.DateTimeFormat('de-DE', { month: 'short' });

const activityValue = (entry: { reps: number; steps: number }) =>
  activityMode.value === 'steps' ? entry.steps : entry.reps;

const activityLevel = (value: number) => {
  if (value <= 0) return 0;
  if (activityMode.value === 'steps') {
    if (value < 2500) return 1;
    if (value < 6000) return 2;
    if (value < 10000) return 3;
    return 4;
  }
  if (value < 30) return 1;
  if (value < 60) return 2;
  if (value < 100) return 3;
  return 4;
};

const activityHeatmapWeeks = computed(() => {
  const year = selectedActivityYear.value;
  const today = startOfDay(new Date());
  const start = mondayOf(new Date(year, 0, 1));
  const lastDay = year === today.getFullYear() ? today : new Date(year, 11, 31);
  const visualEnd = windowWidth.value <= 768
    ? lastDay
    : addDays(mondayOf(new Date(year, 11, 31)), 6);
  const todayKey = dateKey(today);
  const activityByDate = new Map<string, { reps: number; steps: number }>();

  rawWeeklyActivity.value.forEach((item) => {
    const rawDate = String(item.date ?? item.Date ?? '');
    if (!rawDate) return;
    const normalizedDate = rawDate.includes('T') ? (rawDate.split('T')[0] ?? rawDate) : rawDate;
    activityByDate.set(normalizedDate, {
      reps: Number(item.reps ?? item.Reps ?? 0),
      steps: Number(item.steps ?? item.Steps ?? 0),
    });
  });

  const weeks = [];
  for (let cursor = new Date(start); cursor <= visualEnd; cursor = addDays(cursor, 7)) {
    const days = [];
    let monthLabel = '';
    for (let index = 0; index < 7; index++) {
      const day = addDays(cursor, index);
      const key = dateKey(day);
      const entry = activityByDate.get(key) ?? { reps: 0, steps: 0 };
      const value = activityValue(entry);
      const isFuture = day > today;
      if (!monthLabel && (day.getDate() === 1 || dateKey(cursor) === dateKey(start))) {
        monthLabel = monthFormatter.format(day);
      }
      days.push({
        key,
        level: isFuture ? 0 : activityLevel(value),
        isToday: key === todayKey,
        isFuture,
        title: isFuture ? '' : `${key}: ${value} ${activityMode.value === 'steps' ? 'Schritte' : 'Reps'}`,
      });
    }
    weeks.push({ start: dateKey(cursor), monthLabel, days });
  }
  return weeks;
});

const activityTotal = computed(() =>
  rawWeeklyActivity.value.reduce((sum, item) => sum + (activityMode.value === 'steps'
    ? (Number(item.steps ?? item.Steps ?? 0) || 0)
    : (Number(item.reps ?? item.Reps ?? 0) || 0)), 0)
);
const activityTotalLabel = computed(() => activityMode.value === 'steps'
  ? `${formatCompact(activityTotal.value)} Schritte in ${selectedActivityYear.value}`
  : `${formatCompact(activityTotal.value)} Reps in ${selectedActivityYear.value}`);

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
              <div class="card-title-row">
                <div>
                  <h3>Wöchentliche Aktivität</h3>
                  <p class="muted">{{ activityTotalLabel }}</p>
                </div>
                <div class="activity-mode-toggle" :class="`mode-${activityMode}`">
                  <button type="button" :class="{ active: activityMode === 'workouts' }" @click="activityMode = 'workouts'">Workouts</button>
                  <button type="button" :class="{ active: activityMode === 'steps' }" @click="activityMode = 'steps'">Schritte</button>
                </div>
              </div>
              <div
                class="profile-heatmap"
                :class="`mode-${activityMode}`"
                :style="{ '--heatmap-week-count': activityHeatmapWeeks.length }"
              >
                <div class="heatmap-months">
                  <span class="heatmap-weekday-spacer"></span>
                  <span v-for="week in activityHeatmapWeeks" :key="`month-${week.start}`" class="heatmap-month">{{ week.monthLabel }}</span>
                </div>
                <div class="heatmap-body">
                  <div class="heatmap-weekdays">
                    <span></span>
                    <span>Mo</span>
                    <span></span>
                    <span>Mi</span>
                    <span></span>
                    <span>Fr</span>
                    <span></span>
                  </div>
                  <div class="heatmap-grid">
                    <div v-for="week in activityHeatmapWeeks" :key="week.start" class="heatmap-week">
                      <span
                        v-for="day in week.days"
                        :key="day.key"
                        class="heatmap-cell"
                        :class="[`heatmap-level-${day.level}`, { today: day.isToday, future: day.isFuture }]"
                        :title="day.title"
                      ></span>
                    </div>
                  </div>
                </div>
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
  width: 32px;
  height: 32px;
  border: 0;
  display: grid;
  place-items: center;
  color: white;
  background: transparent;
  cursor: pointer;
  padding: 0;
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

.activity-mode-toggle {
  display: inline-flex;
  flex: 0 0 auto;
  padding: 4px;
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.06);
}

.activity-mode-toggle button {
  border: 0;
  border-radius: 12px;
  padding: 7px 12px;
  background: transparent;
  color: rgba(255, 255, 255, 0.64);
  font: inherit;
  font-size: 12px;
  font-weight: 800;
  cursor: pointer;
}

.activity-mode-toggle button.active {
  color: white;
  background: rgba(236, 72, 153, 0.28);
  box-shadow: 0 0 18px rgba(236, 72, 153, 0.2);
}

.activity-mode-toggle.mode-steps button.active {
  background: rgba(251, 146, 60, 0.28);
  box-shadow: 0 0 18px rgba(251, 146, 60, 0.18);
}

.profile-heatmap {
  --heatmap-week-count: 53;
  --heatmap-cell-size: clamp(7px, calc((100vw - 260px) / var(--heatmap-week-count)), 16px);
  overflow-x: auto;
  overflow-y: hidden;
  padding: 10px;
  border-radius: 16px;
  border: 1px solid rgba(236, 72, 153, 0.16);
  background: rgba(2, 6, 23, 0.28);
}

.heatmap-months,
.heatmap-body {
  width: max-content;
  min-width: 100%;
}

.heatmap-months {
  display: flex;
  gap: 4px;
  margin-bottom: 8px;
}

.heatmap-weekday-spacer,
.heatmap-weekdays {
  width: 32px;
  flex: 0 0 32px;
}

.heatmap-month {
  width: var(--heatmap-cell-size);
  min-height: 14px;
  color: rgba(255, 255, 255, 0.68);
  font-size: 11px;
  font-weight: 800;
  text-transform: capitalize;
}

.heatmap-body {
  display: flex;
  gap: 8px;
}

.heatmap-weekdays {
  display: grid;
  grid-template-rows: repeat(7, var(--heatmap-cell-size));
  gap: 4px;
  color: rgba(255, 255, 255, 0.66);
  font-size: 10px;
  font-weight: 800;
  line-height: var(--heatmap-cell-size);
}

.heatmap-grid {
  display: flex;
  gap: 4px;
}

.heatmap-week {
  display: grid;
  grid-template-rows: repeat(7, var(--heatmap-cell-size));
  gap: 4px;
}

.heatmap-cell {
  width: var(--heatmap-cell-size);
  height: var(--heatmap-cell-size);
  border-radius: 3px;
  border: 1px solid rgba(255, 255, 255, 0.05);
  background: rgba(255, 255, 255, 0.06);
}

.heatmap-level-1 { background: rgba(157, 23, 77, 0.5); border-color: rgba(236, 72, 153, 0.16); }
.heatmap-level-2 { background: rgba(219, 39, 119, 0.7); border-color: rgba(244, 114, 182, 0.22); }
.heatmap-level-3 { background: rgba(236, 72, 153, 0.94); border-color: rgba(244, 114, 182, 0.32); }
.heatmap-level-4 { background: #ff4fb3; border-color: rgba(251, 207, 232, 0.55); box-shadow: 0 0 10px rgba(236, 72, 153, 0.32); }

.mode-steps .heatmap-level-1 { background: rgba(154, 52, 18, 0.54); border-color: rgba(251, 146, 60, 0.18); }
.mode-steps .heatmap-level-2 { background: rgba(234, 88, 12, 0.72); border-color: rgba(251, 146, 60, 0.24); }
.mode-steps .heatmap-level-3 { background: rgba(249, 115, 22, 0.9); border-color: rgba(253, 186, 116, 0.32); }
.mode-steps .heatmap-level-4 { background: #fb923c; border-color: rgba(254, 215, 170, 0.55); box-shadow: 0 0 10px rgba(249, 115, 22, 0.3); }

.heatmap-cell.today {
  outline: 2px solid rgba(255, 255, 255, 0.72);
  outline-offset: 1px;
}

.heatmap-cell.future {
  opacity: 0.22;
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
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 8px;
  }

  .stat-card,
  .achievement-card {
    min-height: 76px;
    padding: 10px;
  }

  .stat-card {
    gap: 9px;
  }

  .stat-card strong {
    font-size: 1rem;
  }

  .achievement-card span {
    font-size: 0.78rem;
    line-height: 1.25;
  }

  .profile-heatmap {
    --heatmap-cell-size: 14px;
    padding: 12px;
  }

  .heatmap-weekday-spacer,
  .heatmap-weekdays {
    width: 28px;
    flex-basis: 28px;
  }

  .heatmap-weekdays {
    font-size: 10px;
    line-height: var(--heatmap-cell-size);
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
