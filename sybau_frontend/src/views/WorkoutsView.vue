<template>
  <!-- Header -->
  <Header></Header>

  <!-- Navigation -->
  <Navbar></Navbar>

  <!-- Main Content -->
  <main class="workouts-content">
    <section class="page-heading">
      <h1 class="page-title">{{ text('Deine Übungen', 'Your Exercises') }}</h1>
      <p class="page-subtitle">{{ text('Wähle eine Übung und trage deine Wiederholungen ein.', 'Choose an exercise and log your progress.') }}</p>
    </section>

    <section class="mobile-stats-panel">
      <div class="stats-grid">
        <article class="stat-card">
          <span class="stat-icon stat-icon-blue">
            <CalendarDays :size="24" />
          </span>
          <span class="stat-copy">
            <span class="stat-label">{{ text('Heute', 'Today') }}</span>
            <span class="stat-value">{{ formatNumber(todayReps) }} {{ text('Einheiten', 'units') }}</span>
          </span>
        </article>
        <article class="stat-card">
          <span class="stat-icon stat-icon-purple">
            <BarChart3 :size="24" />
          </span>
          <span class="stat-copy">
            <span class="stat-label">{{ text('Gesamt', 'Total') }}</span>
            <span class="stat-value">{{ formatNumber(totalExercises) }} {{ text('Einheiten', 'units') }}</span>
          </span>
        </article>
        <article class="stat-card">
          <span class="stat-icon stat-icon-yellow">
            <Zap :size="24" />
          </span>
          <span class="stat-copy">
            <span class="stat-label">{{ text('XP Heute', 'XP Today') }}</span>
            <span class="stat-value">+{{ formatNumber(todayXp) }} XP</span>
          </span>
        </article>
      </div>
    </section>

    <section class="health-grid">
      <article class="health-card">
        <Flame class="health-flame" :size="30" />
        <div>
          <span class="health-label">{{ text('Schritte heute', 'Steps today') }}</span>
          <strong>{{ formatNumber(todayActivity.steps) }}</strong>
        </div>
      </article>
      <article class="health-card">
        <Flame class="health-flame" :size="30" />
        <div>
          <span class="health-label">{{ text('Kilometer heute', 'Kilometers today') }}</span>
          <strong>{{ Number(todayActivity.kilometers || 0).toFixed(1) }} km</strong>
        </div>
      </article>
    </section>

    <!-- Filter Buttons -->
    <div class="filter-section">
      <button
          v-for="filter in filters"
          :key="filter"
          class="filter-btn"
          :class="{ active: activeFilter === filter }"
          @click="activeFilter = filter"
      >
        {{ translate(filter) }}
      </button>
    </div>

    <!-- Workouts Grid -->
    <div class="workouts-grid">
      <WorkoutCard
          v-for="exercise in filteredExercises"
          :key="exercise.id"
          :category="translate(exercise.category)"
          :title="translate(exercise.name)"
          :duration="0"
          :calories="0"
          :exercises="[translate(exercise.description)]"
          :difficulty="exercise.difficulty"
          :xp="exercise.xpPerRep"
          :unit="exercise.unit"
          :completed="exercise.todayCount >= exercise.dailyLimit"
          :editor-open="activeExerciseEditorId === exercise.id"
          :draft-reps="logAmountFor(exercise)"
          :draft-time="timeDraftFor(exercise)"
          :draft-distance="distanceDraftFor(exercise)"
          :distance-unit="distanceUnitFor(exercise)"
          :remaining="remainingFor(exercise)"
          @open-editor="openRepEditor(exercise)"
          @close-editor="closeRepEditor"
          @change-draft="changeDraft(exercise, $event)"
          @set-reps="setRepsDraft(exercise, $event)"
          @set-time="setTimeDraft(exercise, $event)"
          @set-distance="setDistanceDraft(exercise, $event)"
          @set-distance-unit="setDistanceUnit(exercise, $event)"
          @submit-log="exercise.unit === 'Distance' ? submitInlineExercise(exercise) : openTimerFor(exercise)"
      />
    </div>

    <!-- Create Custom Workout Card -->
    <div class="custom-workout-card">
      <div class="custom-content">
        <h3>{{ text('Erstelle dein eigenes Workout', 'Create your own workout') }}</h3>
        <p>{{ text('Kombiniere Übungen und verdiene Bonus-XP', 'Combine exercises and earn bonus XP') }}</p>
      </div>
      <button class="create-btn" @click="showCreateWorkout = true">
        {{ text('Workout erstellen', 'Create workout') }}
      </button>
    </div>

    <!-- Saved Workouts Section -->
    <div v-if="workouts.length > 0" class="workouts-section">
      <h2 class="section-title">{{ text('Deine Workouts', 'Your Workouts') }}</h2>
      <div class="workouts-grid">
        <div v-for="wo in filteredWorkouts" :key="wo.id" class="workout-plan-card" @click="toggleWorkoutExpand(wo.id)">
          <div class="workout-plan-header">
            <div class="category-badge" :class="`category-${mapCategory(wo.category).toLowerCase()}`">
              {{ mapCategory(wo.category) }}
            </div>
            <h3>{{ wo.name }}</h3>
            <p v-if="wo.description" class="workout-plan-desc">{{ wo.description }}</p>
          </div>
          <div class="workout-plan-meta">
            <span class="asset-meta">
              <img src="../assets/Pixel_Hantel.png" alt="" />
              {{ wo.exercises?.length ?? 0 }} {{ text('Übungen', 'exercises') }}
            </span>
            <span class="expand-icon">{{ expandedWorkout === wo.id ? '▲' : '▼' }}</span>
          </div>
          <div v-if="expandedWorkout === wo.id" class="workout-exercises-list">
            <div v-for="ex in wo.exercises" :key="ex.exerciseId" class="workout-exercise-item">
              <span class="exercise-name-label">{{ translate(ex.exerciseName) }}</span>
              <span class="exercise-meta-label">{{ translate(mapDifficulty(ex.difficulty)) }} · {{ text('Limit', 'Limit') }}: {{ ex.dailyLimit }}</span>
            </div>
            <button class="start-workout-btn" @click.stop="startWorkoutSession(wo)">
              {{ text('Workout starten', 'Start workout') }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </main>

   <!-- Footer -->
    <FooterComponent />

  <!-- Create Workout Modal -->
  <div v-if="showCreateWorkout" class="workout-modal-overlay" @click.self="showCreateWorkout = false">
    <div class="create-workout-modal">
      <div class="modal-header-cw">
        <h2>{{ text('Neues Workout erstellen', 'Create new workout') }}</h2>
        <button class="close-btn-cw" type="button" aria-label="Schließen" data-tooltip="Schließen" @click="showCreateWorkout = false">&times;</button>
      </div>
      <form @submit.prevent="handleCreateWorkout">
        <div class="form-group-cw">
          <label>{{ text('Name', 'Name') }}</label>
          <input v-model="newWorkout.name" type="text" required :placeholder="text('z.B. Oberkörper Power', 'e.g. Upper body power')">
        </div>
        <div class="form-group-cw">
          <label>{{ text('Beschreibung', 'Description') }}</label>
          <input v-model="newWorkout.description" type="text" :placeholder="text('Optional', 'Optional')">
        </div>
        <div class="form-group-cw">
          <label>{{ text('Kategorie', 'Category') }}</label>
          <select v-model.number="newWorkout.category" required>
            <option value="" disabled>-- {{ text('Wähle Kategorie', 'Choose category') }} --</option>
            <option :value="0">Strength</option>
            <option :value="1">Core</option>
            <option :value="2">Cardio</option>
            <option :value="3">Flexibility</option>
          </select>
        </div>
        <div class="form-group-cw">
          <label>{{ text('Übungen', 'Exercises') }}</label>
          <div v-for="(entry, idx) in newWorkout.exercises" :key="idx" class="exercise-row-cw">
            <select v-model.number="entry.exerciseId" required>
              <option value="0" disabled>-- {{ text('Übung wählen', 'Choose exercise') }} --</option>
              <option v-for="ex in exercises" :key="ex.id" :value="ex.id">{{ translate(ex.name) }}</option>
            </select>
            <input v-model.number="entry.dailyLimit" type="number" min="1" :placeholder="text('Limit', 'Limit')" class="limit-input-cw">
            <button type="button" class="remove-btn-cw" @click="newWorkout.exercises.splice(idx, 1)" v-if="newWorkout.exercises.length > 1">✕</button>
          </div>
          <button type="button" class="add-exercise-btn" @click="newWorkout.exercises.push({ exerciseId: 0, dailyLimit: 50 })">+ {{ text('Übung hinzufügen', 'Add exercise') }}</button>
        </div>
        <div class="modal-actions-cw">
          <button type="button" class="btn-cancel-cw" @click="showCreateWorkout = false">{{ text('Abbrechen', 'Cancel') }}</button>
          <button type="submit" class="btn-create-cw">{{ text('Erstellen', 'Create') }}</button>
        </div>
      </form>
    </div>
  </div>

  <!-- Workout Session Modal -->
  <div v-if="workoutSession" class="workout-modal-overlay" @click.self="closeWorkoutSession">
    <div class="create-workout-modal workout-session-modal">

      <!-- ===== ABSCHLUSS-SCREEN ===== -->
      <template v-if="sessionFinished">
        <div class="session-finish-screen">
          <div class="finish-icon">
            <img src="../assets/Star_Pixel.png" alt="" />
          </div>
          <h2 class="finish-title">{{ text('Workout abgeschlossen!', 'Workout complete!') }}</h2>
          <p class="finish-subtitle">{{ workoutSession.name }}</p>

          <div class="finish-stats">
            <div class="finish-stat">
              <span class="finish-stat-icon">
                <img src="../assets/XP_Pixel.png" alt="" />
              </span>
              <span class="finish-stat-value">+{{ sessionTotalXp }}</span>
              <span class="finish-stat-label">{{ text('XP verdient', 'XP earned') }}</span>
            </div>
            <div class="finish-stat">
              <span class="finish-stat-icon">
                <img src="../assets/SYBAU_Coin.png" alt="" />
              </span>
              <span class="finish-stat-value">+{{ sessionTotalCoins }}</span>
              <span class="finish-stat-label">{{ text('Coins verdient', 'Coins earned') }}</span>
            </div>
          </div>

          <div class="finish-details">
            <div class="finish-detail-row">
              <span>{{ text('Übungen abgeschlossen', 'Exercises completed') }}</span>
              <span>{{ sessionActiveCount }}</span>
            </div>
            <div v-if="sessionSkippedCount > 0" class="finish-detail-row finish-detail-skipped">
              <span>{{ text('Übersprungen (Limit erreicht)', 'Skipped (limit reached)') }}</span>
              <span>{{ sessionSkippedCount }}</span>
            </div>
          </div>

          <!-- Einzelne Ergebnisse -->
          <div class="finish-exercises">
            <div v-for="ex in workoutSession.exercises" :key="ex.exerciseId" class="finish-exercise-row">
              <span class="finish-ex-name">{{ translate(ex.exerciseName) }}</span>
              <template v-if="ex.skipped">
                <span class="finish-ex-skipped">{{ text('Limit erreicht', 'Limit reached') }}</span>
              </template>
              <template v-else>
                <span class="finish-ex-reward">{{ formatSessionAmount(ex) }} · +{{ ex.xpEarned }} XP · +{{ ex.coinsEarned }} Coins</span>
              </template>
            </div>
          </div>

          <button class="finish-close-btn" @click="closeWorkoutSession">{{ text('Fertig', 'Done') }}</button>
        </div>
      </template>

      <!-- ===== AKTIVE SESSION ===== -->
      <template v-else>
        <div class="modal-header-cw">
          <h2>{{ workoutSession.name }}</h2>
          <button class="close-btn-cw" type="button" aria-label="Schließen" data-tooltip="Schließen" @click="closeWorkoutSession">&times;</button>
        </div>

        <!-- Limit-Hinweis oben -->
        <div v-if="sessionSkippedCount > 0" class="session-limit-notice">
          ⚠️ {{ sessionSkippedNotice }}
        </div>

        <div class="session-exercises">
          <div v-for="(ex, idx) in workoutSession.exercises" :key="ex.exerciseId" 
               class="session-exercise-item" :class="{ 'session-done': ex.logged, 'session-skipped': ex.skipped }">
            <div class="session-exercise-info">
              <span class="session-exercise-num">{{ Number(idx) + 1 }}</span>
              <div>
                <span class="session-exercise-name">{{ translate(ex.exerciseName) }}</span>
                <span class="session-exercise-detail">{{ translate(mapDifficulty(ex.difficulty)) }} · {{ text('Limit', 'Limit') }}: {{ formatSessionLimit(ex) }}</span>
              </div>
            </div>
            <div class="session-exercise-action">
              <!-- Limit erreicht -->
              <template v-if="ex.skipped">
                <span class="session-limit-badge">{{ text('Limit erreicht', 'Limit reached') }}</span>
              </template>
              <!-- Bereits geloggt -->
              <template v-else-if="ex.logged">
                <span class="session-check">{{ formatSessionAmount(ex) }}</span>
                <span class="session-reward">+{{ ex.xpEarned }} XP · +{{ ex.coinsEarned }} Coins</span>
              </template>
              <!-- Noch offen -->
              <template v-else>
                <span v-if="ex.remaining < ex.dailyLimit" class="session-remaining-hint">
                  {{ text('Noch', 'Still') }} {{ formatSessionRemaining(ex) }} {{ text('möglich', 'possible') }}
                </span>
                <div v-if="ex.unit === 'Reps'" class="session-input-row">
                  <input v-model.number="ex.repsInput" type="number" min="1" :max="ex.remaining" 
                         :placeholder="text('Reps', 'Reps')" class="session-reps-input">
                  <button class="session-log-btn" @click="logWorkoutExercise(ex)" :disabled="!ex.repsInput || ex.repsInput < 1">
                    {{ text('Eintragen', 'Log') }}
                  </button>
                </div>
                <div v-else-if="ex.unit === 'Time'" class="session-input-row">
                  <input :value="ex.timeInput" inputmode="numeric" maxlength="8" placeholder="00:00:00"
                         class="session-reps-input session-time-input"
                         @input="ex.timeInput = formatTimeInput(($event.target as HTMLInputElement).value)">
                  <button class="session-log-btn" @click="logWorkoutExercise(ex)" :disabled="!ex.timeInput || ex.timeInput === '00:00:00'">
                    {{ text('Eintragen', 'Log') }}
                  </button>
                </div>
                <div v-else class="session-input-row session-distance-row">
                  <input v-model.number="ex.distanceInput" type="number" min="0" step="0.01"
                         :placeholder="text('Distanz', 'Distance')" class="session-reps-input">
                  <select v-model="ex.distanceUnit" class="session-distance-select">
                    <option value="m">m</option>
                    <option value="km">km</option>
                  </select>
                  <button class="session-log-btn" @click="logWorkoutExercise(ex)" :disabled="!ex.distanceInput || ex.distanceInput <= 0">
                    {{ text('Eintragen', 'Log') }}
                  </button>
                </div>
              </template>
            </div>
          </div>
        </div>

        <!-- Session Summary -->
        <div class="session-summary">
          <div class="session-summary-row">
            <span>{{ text('Fortschritt', 'Progress') }}</span>
            <span>{{ sessionCompletedCount }} / {{ workoutSession.exercises.length }} {{ text('Übungen', 'exercises') }}</span>
          </div>
          <div class="session-progress-bar">
            <div class="session-progress-fill" :style="{ width: sessionProgressPercent + '%' }"></div>
          </div>
          <div class="session-summary-row">
            <span>{{ text('Gesamt XP', 'Total XP') }}</span>
            <span class="session-total-xp">+{{ sessionTotalXp }}</span>
          </div>
          <div class="session-summary-row">
            <span>{{ text('Gesamt Coins', 'Total Coins') }}</span>
            <span class="session-total-coins">+{{ sessionTotalCoins }}</span>
          </div>
        </div>

        <div class="modal-actions-cw">
          <button class="btn-cancel-cw" @click="closeWorkoutSession">{{ text('Schließen', 'Close') }}</button>
          <button v-if="sessionCompletedCount === workoutSession.exercises.length" class="btn-create-cw" @click="finishWorkoutSession">
            {{ text('Workout abgeschlossen', 'Workout completed') }}
          </button>
        </div>
      </template>
    </div>
  </div>

  <ExerciseTimerOverlay
    v-if="timerExercise"
    :is-open="timerOpen"
    :exercise-name="timerExercise?.name ?? ''"
    :exercise-type="timerExercise?.unit === 'Time' ? 'Time' : 'Reps'"
    :xp-per-rep="timerExercise?.xpPerRep ?? 1"
    :max-reps="timerExercise?.dailyLimit ?? 200"
    :remaining="timerExercise ? remainingFor(timerExercise) : 0"
    @close="timerOpen = false"
    @confirm="handleTimerConfirm"
  />
  <Teleport to="body">
    <MessagePopup
      v-if="popupMessage"
      :message="popupMessage"
      :type="popupType"
      @close="popupMessage = ''"
    />
  </Teleport>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import Header from '@/components/Header.vue';
import Navbar from '@/components/Navbar.vue';
import WorkoutCard from '@/components/WorkoutCard.vue';
import FooterComponent from '@/components/FooterComponent.vue';
import MessagePopup from '@/components/MessagePopup.vue';
import ExerciseTimerOverlay from '@/components/ExerciseTimerOverlay.vue';
import { workoutService, achievementService, questService } from '@/services/api';
import { useAuth } from '@/composables/useAuth';
import { useLanguage } from '@/composables/useLanguage';
import { BarChart3, CalendarDays, Flame, Zap } from 'lucide-vue-next';

const { refreshProfile } = useAuth();
const { text, translate, locale } = useLanguage();

const activeFilter = ref('Alle');
const loading = ref(true);

const popupMessage = ref('');
const popupType = ref<'success' | 'error'>('success');

const filters = ['Alle', 'Cardio', 'Strength', 'Core', 'Flexibility'];

// Difficulty → XP pro Wiederholung
const difficultyXp: Record<string, number> = {
  Easy: 1,
  Medium: 2,
  Hard: 5
};

// Difficulty → Standard Daily Limit
const difficultyDailyLimit: Record<string, number> = {
  Easy: 300,
  Medium: 200,
  Hard: 100
};

interface ExerciseLocal {
  id: number;
  name: string;
  description: string;
  category: string;
  icon: string;
  xpPerRep: number;
  dailyLimit: number;
  todayCount: number;
  difficulty: 'Easy' | 'Medium' | 'Hard';
  unit: 'Reps' | 'Time' | 'Distance';
}

const exercises = ref<ExerciseLocal[]>([]);
const workouts = ref<any[]>([]);
const showCreateWorkout = ref(false);
const totalExercises = ref(0);
const todayActivity = ref({ steps: 0, kilometers: 0 });
const expandedWorkout = ref<number | null>(null);
const workoutSession = ref<any>(null);
const activeExerciseEditorId = ref<number | null>(null);

// Timer-based exercise flow
const timerOpen = ref(false);
const timerExercise = ref<ExerciseLocal | null>(null);
const repsDrafts = ref<Record<number, number>>({});
const timeDrafts = ref<Record<number, string>>({});
const distanceDrafts = ref<Record<number, number>>({});
const distanceUnits = ref<Record<number, 'm' | 'km'>>({});
const newWorkout = ref({
  name: '',
  description: '',
  category: '' as number | '',
  exercises: [{ exerciseId: 0, dailyLimit: 50 }] as { exerciseId: number; dailyLimit: number }[]
});

onMounted(async () => {
  await Promise.all([loadExercises(), loadWorkouts(), loadProfileStats(), loadTodayActivity()]);
});

async function loadProfileStats() {
  try {
    const res = await achievementService.getProfileStats();
    totalExercises.value = res.data?.totalExercises ?? 0;
  } catch (e) {
    console.error('Fehler beim Laden der Profil-Stats', e);
  }
}

async function loadTodayActivity() {
  try {
    const res = await questService.getTodayActivity();
    todayActivity.value = {
      steps: Number(res.data?.steps ?? 0),
      kilometers: Number(res.data?.kilometers ?? 0)
    };
  } catch (e) {
    console.error('Fehler beim Laden der Health-Stats', e);
  }
}

function formatNumber(value: number) {
  if (Math.abs(value) < 1000) return value.toLocaleString(locale.value);
  const units = [
    { amount: 1_000_000_000, suffix: 'B' },
    { amount: 1_000_000, suffix: 'M' },
    { amount: 1_000, suffix: 'K' }
  ];
  const unit = units.find((u) => Math.abs(value) >= u.amount);
  if (!unit) return value.toLocaleString(locale.value);
  const compact = value / unit.amount;
  const digits = compact >= 100 || Number.isInteger(compact) ? 0 : 1;
  return `${compact.toFixed(digits).replace('.', ',')}${unit.suffix}`;
}

// Stats berechnen
const todayReps = computed(() => exercises.value.reduce((sum, e) => sum + e.todayCount, 0));
const todayXp = computed(() => exercises.value.reduce((sum, e) => sum + (e.todayCount * e.xpPerRep), 0));
const sessionSkippedNotice = computed(() =>
  text(
    `${sessionSkippedCount.value} Übung${sessionSkippedCount.value > 1 ? 'en' : ''} übersprungen - Tageslimit bereits erreicht`,
    `${sessionSkippedCount.value} exercise${sessionSkippedCount.value > 1 ? 's' : ''} skipped - daily limit already reached`
  )
);

function remainingFor(exercise: ExerciseLocal) {
  return Math.max(0, Number(exercise.dailyLimit ?? 0) - Number(exercise.todayCount ?? 0));
}

function secondsToTime(value: number) {
  const seconds = Math.max(0, Math.floor(value));
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const rest = seconds % 60;
  return [hours, minutes, rest].map((part) => String(part).padStart(2, '0')).join(':');
}

function formatTimeInput(value: string) {
  const digits = value.replace(/\D/g, '').slice(-6);
  if (!digits) return '00:00:00';

  const padded = digits.padStart(6, '0');
  const hours = Number(padded.slice(0, 2));
  const minutes = Number(padded.slice(2, 4));
  const seconds = Number(padded.slice(4, 6));

  return secondsToTime(hours * 3600 + minutes * 60 + seconds);
}

function parseTime(value: string) {
  const parts = value.trim().split(':').map((part) => Number(part));
  if (parts.length !== 3 || parts.some((part) => !Number.isFinite(part) || part < 0)) return 0;
  const hours = parts[0] ?? 0;
  const minutes = parts[1] ?? 0;
  const seconds = parts[2] ?? 0;
  return Math.round(hours * 3600 + minutes * 60 + seconds);
}

function draftFor(exercise: ExerciseLocal) {
  const remaining = remainingFor(exercise);
  if (remaining <= 0) return 0;
  return repsDrafts.value[exercise.id] ?? Math.min(10, remaining);
}

function timeDraftFor(exercise: ExerciseLocal) {
  return timeDrafts.value[exercise.id] ?? secondsToTime(Math.min(60, remainingFor(exercise)));
}

function distanceDraftFor(exercise: ExerciseLocal) {
  const unit = distanceUnitFor(exercise);
  const raw = distanceDrafts.value[exercise.id] ?? Math.min(100, remainingFor(exercise));
  return unit === 'km' ? Number((raw / 1000).toFixed(2)) : raw;
}

function distanceUnitFor(exercise: ExerciseLocal): 'm' | 'km' {
  return distanceUnits.value[exercise.id] ?? 'm';
}

function logAmountFor(exercise: ExerciseLocal) {
  if (exercise.unit === 'Time') return parseTime(timeDraftFor(exercise));
  if (exercise.unit === 'Distance') {
    const raw = distanceDraftFor(exercise);
    return Math.round(raw * (distanceUnitFor(exercise) === 'km' ? 1000 : 1));
  }
  return draftFor(exercise);
}

function openRepEditor(exercise: ExerciseLocal) {
  if (remainingFor(exercise) <= 0) return;
  if (exercise.unit !== 'Distance') {
    openTimerFor(exercise);
    return;
  }
  activeExerciseEditorId.value = exercise.id;
  repsDrafts.value = {
    ...repsDrafts.value,
    [exercise.id]: draftFor(exercise)
  };
  timeDrafts.value = {
    ...timeDrafts.value,
    [exercise.id]: timeDraftFor(exercise)
  };
  distanceDrafts.value = {
    ...distanceDrafts.value,
    [exercise.id]: logAmountFor({ ...exercise, unit: 'Distance' })
  };
}

function closeRepEditor() {
  activeExerciseEditorId.value = null;
}

function openTimerFor(exercise: ExerciseLocal) {
  timerExercise.value = exercise;
  timerOpen.value = true;
}

async function handleTimerConfirm(data: { reps: number; elapsedSeconds: number }) {
  const exercise = timerExercise.value;
  if (!exercise) return;
  try {
    const res = await workoutService.logExercise(exercise.id, data.reps, data.elapsedSeconds);
    const result = res.data;
    const rewards = rewardTotals(result, data.reps * exercise.xpPerRep);
    exercise.todayCount += data.reps;
    const remaining = remainingFor(exercise);
    repsDrafts.value = { ...repsDrafts.value, [exercise.id]: remaining <= 0 ? 0 : Math.min(data.reps, remaining) };
    activeExerciseEditorId.value = null;
    let msg = `${exercise.name}: ${formatAmount(data.reps, exercise.unit)} eingetragen!`;
    msg += ` +${rewards.xp} XP`;
    if (rewards.coins > 0) msg += `, +${rewards.coins} Coins`;
    popupType.value = 'success';
    popupMessage.value = msg;
    await refreshProfile();
    flashHeaderReward(rewards);
    refreshQuestBadge();
  } catch (err: any) {
    const errorMsg = err.response?.data || text('Fehler beim Eintragen', 'Could not log exercise');
    popupType.value = 'error';
    popupMessage.value = errorMsg;
  }
}

function setTimeDraft(exercise: ExerciseLocal, value: string) {
  timeDrafts.value = { ...timeDrafts.value, [exercise.id]: formatTimeInput(value) };
}

function setDistanceDraft(exercise: ExerciseLocal, value: number) {
  const multiplier = distanceUnitFor(exercise) === 'km' ? 1000 : 1;
  const meters = Math.max(0, Math.round(Number(value || 0) * multiplier));
  distanceDrafts.value = { ...distanceDrafts.value, [exercise.id]: meters };
}

function setDistanceUnit(exercise: ExerciseLocal, value: 'm' | 'km') {
  distanceUnits.value = { ...distanceUnits.value, [exercise.id]: value };
}

function changeDraft(exercise: ExerciseLocal, delta: number) {
  const remaining = remainingFor(exercise);
  if (remaining <= 0) return;
  const next = Math.min(remaining, Math.max(1, draftFor(exercise) + delta));
  repsDrafts.value = {
    ...repsDrafts.value,
    [exercise.id]: next
  };
}

function setRepsDraft(exercise: ExerciseLocal, value: number) {
  const remaining = remainingFor(exercise);
  if (remaining <= 0) return;
  const next = Math.min(remaining, Math.max(1, Math.round(Number(value || 0))));
  repsDrafts.value = {
    ...repsDrafts.value,
    [exercise.id]: next
  };
}

async function loadExercises() {
  loading.value = true;
  try {
    const res = await workoutService.getExercises();
    const data = res.data ?? [];
    exercises.value = data.map((e: any) => {
      const diff = mapDifficulty(e.difficulty);
      const cat = mapCategory(e.category);
      return {
        id: e.id,
        name: e.name,
        description: e.description ?? '',
        category: cat,
        icon: '',
        xpPerRep: e.xpPerRep ?? difficultyXp[diff] ?? 2,
        dailyLimit: e.dailyLimit ?? difficultyDailyLimit[diff] ?? 200,
        todayCount: e.todayCount ?? 0,
        difficulty: diff,
        unit: mapUnit(e.unit ?? e.Unit)
      };
    });
  } catch (e) {
    console.error('Fehler beim Laden der Übungen', e);
  }
  loading.value = false;
}

function mapUnit(val: any): 'Reps' | 'Time' | 'Distance' {
  if (typeof val === 'number') {
    if (val === 1) return 'Time';
    if (val === 2) return 'Distance';
    return 'Reps';
  }
  const s = String(val ?? '').toLowerCase();
  if (s === 'time') return 'Time';
  if (s === 'distance') return 'Distance';
  return 'Reps';
}

function formatAmount(value: number, unit: ExerciseLocal['unit']) {
  if (unit === 'Time') return secondsToTime(value);
  if (unit === 'Distance') {
    return value >= 1000
      ? `${(value / 1000).toLocaleString(locale.value, { maximumFractionDigits: 2 })} km`
      : `${value.toLocaleString(locale.value)} m`;
  }
  return `${value.toLocaleString(locale.value)} Reps`;
}

function numberFromResult(result: any, ...keys: string[]) {
  for (const key of keys) {
    const value = result?.[key];
    if (value !== undefined && value !== null) return Number(value) || 0;
  }
  return 0;
}

function rewardTotals(result: any, fallbackXp = 0) {
  const baseXp = result?.xpEarned ?? result?.XpEarned ?? fallbackXp;
  return {
    xp: Math.max(0, (Number(baseXp) || 0) + numberFromResult(result, 'bonusXp', 'BonusXp')),
    coins: Math.max(0, numberFromResult(result, 'coinsEarned', 'CoinsEarned') + numberFromResult(result, 'bonusCoins', 'BonusCoins'))
  };
}

function flashHeaderReward(rewards: { xp: number; coins: number }) {
  if (rewards.xp <= 0 && rewards.coins <= 0) return;
  window.dispatchEvent(new CustomEvent('sybau:reward-flash', { detail: rewards }));
}

function refreshQuestBadge() {
  window.dispatchEvent(new CustomEvent('sybau:quests-updated'));
}

// Backend gibt Enums als camelCase Strings zurück (z.B. "easy", "strength")
function mapDifficulty(val: any): 'Easy' | 'Medium' | 'Hard' {
  const s = String(val).toLowerCase();
  if (s === 'easy') return 'Easy';
  if (s === 'hard') return 'Hard';
  return 'Medium';
}

function mapCategory(val: any): string {
  const s = String(val).toLowerCase();
  if (s === 'strength') return 'Strength';
  if (s === 'core') return 'Core';
  if (s === 'cardio') return 'Cardio';
  if (s === 'flexibility') return 'Flexibility';
  return 'Strength';
}


const filteredExercises = computed(() => {
  if (activeFilter.value === 'Alle') {
    return exercises.value;
  }
  
  return exercises.value.filter(e => e.category === activeFilter.value);
});

const filteredWorkouts = computed(() => {
  if (activeFilter.value === 'Alle') return workouts.value;
  return workouts.value.filter(w => mapCategory(w.category) === activeFilter.value);
});

async function loadWorkouts() {
  try {
    const res = await workoutService.getWorkouts();
    workouts.value = res.data ?? [];
  } catch (e) {
    console.error('Fehler beim Laden der Workouts', e);
  }
}

function toggleWorkoutExpand(id: number) {
  expandedWorkout.value = expandedWorkout.value === id ? null : id;
}

async function handleCreateWorkout() {
  const validExercises = newWorkout.value.exercises.filter(e => e.exerciseId > 0);
  if (validExercises.length === 0) {
    popupType.value = 'error';
    popupMessage.value = 'Bitte mindestens eine Übung hinzufügen';
    return;
  }
  try {
    await workoutService.createWorkout({
      name: newWorkout.value.name,
      description: newWorkout.value.description || null,
      category: newWorkout.value.category,
      exercises: validExercises
    });
    showCreateWorkout.value = false;
    newWorkout.value = {
      name: '',
      description: '',
      category: '',
      exercises: [{ exerciseId: 0, dailyLimit: 50 }]
    };
    await loadWorkouts();
  } catch (err: any) {
    popupType.value = 'error';
    popupMessage.value = err.response?.data || text('Fehler beim Erstellen des Workouts', 'Could not create workout');
  }
}

// ===== WORKOUT SESSION =====
const sessionFinished = ref(false);

function startWorkoutSession(wo: any) {
  sessionFinished.value = false;
  workoutSession.value = {
    id: wo.id,
    name: wo.name,
    exercises: wo.exercises.map((ex: any) => {
      const localEx = exercises.value.find(e => e.id === ex.exerciseId);
      const todayCount = localEx?.todayCount ?? 0;
      const limit = localEx?.dailyLimit ?? ex.dailyLimit;
      const remaining = Math.max(0, limit - todayCount);
      const limitReached = remaining === 0;
      const unit = localEx?.unit ?? mapUnit(ex.unit ?? ex.Unit) ?? 'Reps';
      return {
        ...ex,
        unit,
        repsInput: unit === 'Reps' ? remaining : 0,
        timeInput: unit === 'Time' ? secondsToTime(Math.min(60, remaining)) : '00:00:00',
        distanceInput: unit === 'Distance' ? (remaining >= 1000 ? Number((remaining / 1000).toFixed(2)) : remaining) : 0,
        distanceUnit: unit === 'Distance' ? (remaining >= 1000 ? 'km' : 'm') : 'm',
        remaining,
        limitReached,
        logged: false,
        skipped: limitReached,
        repsLogged: 0,
        xpEarned: 0,
        coinsEarned: 0
      };
    })
  };
}

function finishWorkoutSession() {
  sessionFinished.value = true;
}

function closeWorkoutSession() {
  workoutSession.value = null;
  sessionFinished.value = false;
  loadExercises();
}

const sessionCompletedCount = computed(() => 
  workoutSession.value?.exercises.filter((e: any) => e.logged || e.skipped).length ?? 0
);
const sessionActiveCount = computed(() =>
  workoutSession.value?.exercises.filter((e: any) => !e.skipped).length ?? 0
);
const sessionSkippedCount = computed(() =>
  workoutSession.value?.exercises.filter((e: any) => e.skipped).length ?? 0
);
const sessionProgressPercent = computed(() => {
  if (!workoutSession.value) return 0;
  return Math.round((sessionCompletedCount.value / workoutSession.value.exercises.length) * 100);
});
const sessionTotalXp = computed(() => 
  workoutSession.value?.exercises.reduce((sum: number, e: any) => sum + (e.xpEarned ?? 0), 0) ?? 0
);
const sessionTotalCoins = computed(() => 
  workoutSession.value?.exercises.reduce((sum: number, e: any) => sum + (e.coinsEarned ?? 0), 0) ?? 0
);

async function logWorkoutExercise(ex: any) {
  let reps: number;
  if (ex.unit === 'Time') {
    reps = parseTime(ex.timeInput);
    if (reps <= 0) return;
  } else if (ex.unit === 'Distance') {
    const multiplier = ex.distanceUnit === 'km' ? 1000 : 1;
    reps = Math.round(Math.max(1, Number(ex.distanceInput || 0) * multiplier));
    if (reps <= 0) return;
  } else {
    if (!ex.repsInput || ex.repsInput < 1) return;
    reps = ex.repsInput;
  }
  try {
    const res = await workoutService.logExercise(ex.exerciseId, reps);
    const result = res.data;
    const rewards = rewardTotals(result);
    ex.logged = true;
    ex.repsLogged = reps;
    ex.xpEarned = rewards.xp;
    ex.coinsEarned = rewards.coins;

    // Lokalen Exercise-Counter auch updaten
    const localEx = exercises.value.find(e => e.id === ex.exerciseId);
    if (localEx) localEx.todayCount += reps;

    await refreshProfile();
    flashHeaderReward(rewards);
    refreshQuestBadge();
  } catch (err: any) {
    popupType.value = 'error';
    popupMessage.value = err.response?.data || text('Fehler beim Eintragen', 'Could not log exercise');
  }
}

function formatSessionAmount(ex: any): string {
  const reps = ex.repsLogged;
  const unit = ex.unit ?? 'Reps';
  return formatAmount(reps, unit);
}

function formatSessionRemaining(ex: any): string {
  return formatAmount(ex.remaining, ex.unit ?? 'Reps');
}

function formatSessionLimit(ex: any): string {
  return formatAmount(ex.dailyLimit, ex.unit ?? 'Reps');
}

const submitInlineExercise = async (exercise: ExerciseLocal) => {
  const reps = logAmountFor(exercise);
  if (reps <= 0) {
    popupType.value = 'error';
    popupMessage.value = exercise.unit === 'Time'
      ? 'Bitte gib die Zeit im Format 00:00:00 ein.'
      : 'Bitte gib einen gültigen Wert ein.';
    return;
  }

  try {
    const res = await workoutService.logExercise(exercise.id, reps);
    const result = res.data;
    const rewards = rewardTotals(result, reps * exercise.xpPerRep);
    const bonusXp = numberFromResult(result, 'bonusXp', 'BonusXp');
    const bonusCoins = numberFromResult(result, 'bonusCoins', 'BonusCoins');

    exercise.todayCount += reps;
    const remaining = remainingFor(exercise);
    repsDrafts.value = {
      ...repsDrafts.value,
      [exercise.id]: remaining <= 0 ? 0 : Math.min(reps, remaining)
    };
    activeExerciseEditorId.value = null;

    let msg = `${exercise.name}: ${formatAmount(reps, exercise.unit)} eingetragen!\n`;
    msg += `+${rewards.xp} XP`;
    if (bonusXp > 0) msg += ` (+${bonusXp} Bonus, ${result.boostPercent ?? result.BoostPercent}% Boost)`;
    if (rewards.coins > 0) {
      msg += `\n+${rewards.coins} Coins`;
      if (bonusCoins > 0) msg += ` (+${bonusCoins} Bonus, ${result.coinBoostPercent ?? result.CoinBoostPercent}% Boost)`;
    }
    popupType.value = 'success';
    popupMessage.value = msg;

    // Header aktualisieren (Level, XP, Coins)
    await refreshProfile();
    flashHeaderReward(rewards);
    refreshQuestBadge();
  } catch (err: any) {
    const errorMsg = err.response?.data || text('Fehler beim Eintragen', 'Could not log exercise');
    popupType.value = 'error';
    popupMessage.value = errorMsg;
  }
};
</script>

<style scoped>
.workouts-content {
  padding: 40px;
  max-width: 1400px;
  margin: 0 auto;
}

.page-heading {
  margin-bottom: 24px;
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
  margin-bottom: 24px;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 18px;
}

.stat-card {
  min-height: 148px;
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

.stat-icon-blue {
  color: #60a5fa;
}

.stat-icon-purple {
  color: #a855f7;
}

.stat-icon-yellow {
  color: #fbbf24;
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
  font-size: 26px;
  font-weight: 800;
  color: white;
  text-shadow: none;
}

.health-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 18px;
  margin-bottom: 18px;
}

.health-card {
  position: relative;
  min-height: 176px;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: center;
  gap: 18px;
  padding: 28px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 24px;
}

.health-flame {
  color: #ff6b1a;
  flex: 0 0 auto;
  filter: drop-shadow(0 0 8px rgba(255, 107, 26, 0.25));
}

.health-label {
  display: block;
  color: rgba(255, 255, 255, 0.66);
  font-size: 20px;
  font-weight: 700;
  margin-bottom: 12px;
}

.health-card strong {
  color: white;
  font-size: 32px;
  font-weight: 800;
}

/* Filter Section */
.filter-section {
  display: flex;
  gap: 12px;
  margin-bottom: 32px;
  flex-wrap: wrap;
}

.filter-btn {
  padding: 12px 24px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(30, 41, 59, 0.6);
  color: rgba(255, 255, 255, 0.7);
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
}

.filter-btn:hover {
  background: rgba(255, 255, 255, 0.08);
  color: white;
  border-color: rgba(236, 72, 153, 0.3);
}

.filter-btn.active {
  background: linear-gradient(135deg, rgba(236, 72, 153, 0.3), rgba(168, 85, 247, 0.3));
  color: white;
  border-color: rgba(236, 72, 153, 0.5);
  box-shadow: 0 4px 12px rgba(236, 72, 153, 0.3);
}

/* Workouts Grid */
.workouts-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(350px, 1fr));
  gap: 24px;
  margin-bottom: 40px;
}

/* Custom Workout Card */
.custom-workout-card {
  background: rgba(30, 41, 59, 0.6);
  border: 2px solid rgba(236, 72, 153, 0.3);
  border-radius: 20px;
  padding: 40px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  backdrop-filter: blur(10px);
  transition: all 0.3s ease;
}

.custom-workout-card:hover {
  border-color: rgba(236, 72, 153, 0.5);
  background: rgba(30, 41, 59, 0.8);
  box-shadow: 0 8px 24px rgba(236, 72, 153, 0.2);
}

.custom-content h3 {
  font-size: 24px;
  font-weight: 700;
  margin: 0 0 8px 0;
  color: white;
}

.custom-content p {
  font-size: 14px;
  margin: 0;
  color: rgba(255, 255, 255, 0.7);
}

.create-btn {
  padding: 14px 32px;
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
  box-shadow: 0 4px 12px rgba(236, 72, 153, 0.3);
}

.create-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(236, 72, 153, 0.4);
}

/* Responsive */

/* Tablet (1024px und kleiner) */
@media (max-width: 1024px) {
  .workouts-content {
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
    min-height: 128px;
    padding: 18px;
  }

  .stat-value {
    font-size: 22px;
  }

  .workouts-grid {
    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
  }
}

/* Mobile (768px und kleiner) */
@media (max-width: 768px) {
  .workouts-content {
    padding: 24px 16px;
  }

  .page-title {
    font-size: 28px;
  }

  .page-subtitle {
    font-size: 14px;
  }

  .stats-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 12px;
  }

  .health-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 10px;
  }

  .health-card {
    min-height: 108px;
    gap: 9px;
    padding: 16px 14px;
    border-radius: 18px;
  }

  .health-flame {
    width: 20px;
    height: 20px;
  }

  .health-label {
    font-size: 13px;
    line-height: 1.15;
    margin-bottom: 6px;
  }

  .health-card strong {
    font-size: 20px;
    line-height: 1.05;
  }

  .stat-label {
    font-size: 15px;
  }

  .stat-value {
    font-size: 18px;
    line-height: 1.12;
  }

  .filter-section {
    gap: 8px;
  }

  .filter-btn {
    padding: 10px 18px;
    font-size: 14px;
  }

  .workouts-grid {
    grid-template-columns: 1fr;
    gap: 16px;
  }

  .custom-workout-card {
    flex-direction: column;
    gap: 20px;
    text-align: center;
    padding: 24px;
  }

  .custom-content h3 {
    font-size: 20px;
  }

  .create-btn {
    width: 100%;
    justify-content: center;
  }
}

/* Small Mobile (480px und kleiner) */
@media (max-width: 480px) {
  .workouts-content {
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
    border-radius: 16px;
    gap: 8px;
  }

  .mobile-stats-panel {
    border-radius: 18px;
    padding: 10px;
  }

  .stats-grid {
    gap: 8px;
  }

  .health-grid {
    gap: 8px;
  }

  .health-card {
    min-height: 92px;
    padding: 12px 10px;
    border-radius: 16px;
  }

  .health-label {
    font-size: 11px;
  }

  .health-card strong {
    font-size: 17px;
  }

  .stat-icon {
    width: 21px;
    height: 21px;
  }

  .stat-copy {
    gap: 3px;
  }

  .stat-label {
    font-size: 0.6rem;
    line-height: 1.05;
  }

  .stat-value {
    font-size: 0.72rem;
    line-height: 1.08;
  }

  .filter-btn {
    padding: 8px 14px;
    font-size: 13px;
  }

  .custom-workout-card {
    padding: 20px;
  }

  .custom-content h3 {
    font-size: 18px;
  }

  .custom-content p {
    font-size: 13px;
  }

  .create-btn {
    padding: 12px 24px;
    font-size: 14px;
  }
}

/* Workouts Section */
.workouts-section {
  margin-top: 48px;
}

.section-title {
  font-size: 24px;
  font-weight: 700;
  color: white;
  margin: 0 0 24px 0;
}

.workout-plan-card {
  background: rgba(30, 41, 59, 0.6);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  padding: 20px;
  cursor: pointer;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
}

.workout-plan-card:hover {
  border-color: rgba(168, 85, 247, 0.4);
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(0, 0, 0, 0.3);
}

.workout-plan-header h3 {
  margin: 10px 0 4px;
  font-size: 18px;
  color: white;
}

.workout-plan-desc {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.6);
  margin: 0 0 8px;
}

.workout-plan-meta {
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: 14px;
  color: rgba(255, 255, 255, 0.7);
  margin-top: 8px;
}

.asset-meta {
  display: inline-flex;
  align-items: center;
  gap: 6px;
}

.asset-meta img {
  width: 18px;
  height: 18px;
  object-fit: contain;
}

.expand-icon {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.4);
}

.workout-exercises-list {
  margin-top: 16px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  padding-top: 12px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.workout-exercise-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 12px;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 8px;
}

.exercise-name-label {
  font-weight: 600;
  color: white;
  font-size: 14px;
}

.exercise-meta-label {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.5);
}

/* Create Workout Modal */
.workout-modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.7);
  backdrop-filter: blur(8px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
}

.create-workout-modal {
  background: #1e293b;
  border: 1px solid rgba(168, 85, 247, 0.3);
  border-radius: 20px;
  padding: 32px;
  width: 100%;
  max-width: 520px;
  max-height: 90vh;
  overflow-y: auto;
  color: white;
}

.modal-header-cw {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 24px;
}

.modal-header-cw h2 {
  margin: 0;
  font-size: 22px;
}

.close-btn-cw {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.6);
  font-size: 28px;
  cursor: pointer;
}

.form-group-cw {
  margin-bottom: 20px;
}

.form-group-cw label {
  display: block;
  font-size: 13px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.7);
  margin-bottom: 8px;
}

.form-group-cw input,
.form-group-cw select {
  width: 100%;
  padding: 12px;
  background: rgba(15, 23, 42, 0.8);
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 10px;
  color: white;
  font-size: 14px;
}

.form-group-cw input:focus,
.form-group-cw select:focus {
  outline: none;
  border-color: rgba(168, 85, 247, 0.5);
}

.exercise-row-cw {
  display: flex;
  gap: 8px;
  align-items: center;
  margin-bottom: 10px;
}

.exercise-row-cw select {
  flex: 2;
  padding: 10px;
  background: rgba(15, 23, 42, 0.8);
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 8px;
  color: white;
  font-size: 14px;
}

.limit-input-cw {
  flex: 0 0 80px !important;
  width: 80px !important;
}

.remove-btn-cw {
  background: rgba(239, 68, 68, 0.2);
  border: 1px solid rgba(239, 68, 68, 0.4);
  color: #fca5a5;
  border-radius: 8px;
  padding: 8px 12px;
  cursor: pointer;
  font-size: 14px;
}

.add-exercise-btn {
  background: rgba(168, 85, 247, 0.15);
  border: 1px dashed rgba(168, 85, 247, 0.4);
  color: #c4b5fd;
  border-radius: 10px;
  padding: 10px;
  width: 100%;
  cursor: pointer;
  font-size: 14px;
  font-weight: 600;
  margin-top: 4px;
}

.modal-actions-cw {
  display: flex;
  gap: 12px;
  justify-content: flex-end;
  margin-top: 24px;
}

.btn-cancel-cw {
  padding: 12px 24px;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 10px;
  color: white;
  cursor: pointer;
  font-size: 14px;
}

.btn-create-cw {
  padding: 12px 28px;
  background: linear-gradient(135deg, #ec4899, #a855f7);
  border: none;
  border-radius: 10px;
  color: white;
  font-weight: 600;
  cursor: pointer;
  font-size: 14px;
}

.btn-create-cw:hover {
  box-shadow: 0 4px 16px rgba(168, 85, 247, 0.4);
}

/* ===== Workout Session Modal ===== */
.workout-session-modal {
  max-width: 560px;
}

.session-exercises {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-bottom: 24px;
  max-height: 50vh;
  overflow-y: auto;
  padding-right: 4px;
}

.session-exercise-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  background: rgba(15, 23, 42, 0.7);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  transition: all 0.3s ease;
}

.session-exercise-item.session-done {
  border-color: rgba(34, 197, 94, 0.4);
  background: rgba(34, 197, 94, 0.08);
}

.session-exercise-num {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: rgba(168, 85, 247, 0.2);
  border: 1px solid rgba(168, 85, 247, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 13px;
  font-weight: 700;
  color: #c4b5fd;
  flex-shrink: 0;
}

.session-done .session-exercise-num {
  background: rgba(34, 197, 94, 0.25);
  border-color: rgba(34, 197, 94, 0.5);
  color: #86efac;
}

.session-exercise-info {
  flex: 1;
  min-width: 0;
}

.session-exercise-name {
  font-weight: 600;
  font-size: 14px;
  color: white;
}

.session-exercise-detail {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.5);
  margin-top: 2px;
}

.session-exercise-action {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-shrink: 0;
}

.session-reps-input {
  width: 70px;
  padding: 8px 10px;
  background: rgba(15, 23, 42, 0.9);
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 8px;
  color: white;
  font-size: 14px;
  text-align: center;
}

.session-reps-input:focus {
  outline: none;
  border-color: rgba(168, 85, 247, 0.5);
}

.session-log-btn {
  padding: 8px 16px;
  background: linear-gradient(135deg, #ec4899, #a855f7);
  border: none;
  border-radius: 8px;
  color: white;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  white-space: nowrap;
}

.session-log-btn:disabled {
  opacity: 0.4;
  cursor: not-allowed;
}

.session-log-btn:not(:disabled):hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(168, 85, 247, 0.4);
}

.session-check {
  color: #22c55e;
  font-size: 20px;
  font-weight: 700;
}

.session-reward {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.6);
  margin-top: 4px;
  text-align: right;
}

.session-reward span {
  margin-left: 8px;
}

.session-summary {
  background: rgba(15, 23, 42, 0.6);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 12px;
  padding: 16px;
  margin-bottom: 20px;
}

.session-summary-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
  font-size: 14px;
  color: rgba(255, 255, 255, 0.8);
}

.session-progress-bar {
  width: 100%;
  height: 8px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 12px;
}

.session-progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #ec4899, #a855f7);
  border-radius: 4px;
  transition: width 0.4s ease;
}

.session-total-xp {
  color: #facc15;
  font-weight: 700;
}

.session-total-coins {
  color: #fbbf24;
  font-weight: 700;
}

.start-workout-btn {
  margin-top: 12px;
  width: 100%;
  padding: 12px;
  background: linear-gradient(135deg, #ec4899, #a855f7);
  border: none;
  border-radius: 10px;
  color: white;
  font-weight: 600;
  font-size: 15px;
  cursor: pointer;
  transition: all 0.3s ease;
}

.start-workout-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(168, 85, 247, 0.4);
}

/* ===== Limit & Skipped States ===== */
.session-limit-notice {
  background: rgba(251, 191, 36, 0.12);
  border: 1px solid rgba(251, 191, 36, 0.3);
  border-radius: 10px;
  padding: 10px 16px;
  margin-bottom: 16px;
  font-size: 13px;
  color: #fbbf24;
  text-align: center;
}

.session-exercise-item.session-skipped {
  opacity: 0.5;
  border-color: rgba(255, 255, 255, 0.05);
}

.session-limit-badge {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.5);
  font-weight: 600;
  white-space: nowrap;
}

.session-remaining-hint {
  font-size: 11px;
  color: #fbbf24;
  white-space: nowrap;
}

/* ===== Finish Screen ===== */
.session-finish-screen {
  text-align: center;
  padding: 16px 0;
}

.finish-icon {
  width: 64px;
  height: 64px;
  display: grid;
  place-items: center;
  margin-inline: auto;
  margin-bottom: 8px;
  animation: finishBounce 0.6s ease;
}

.finish-icon img {
  width: 56px;
  height: 56px;
  object-fit: contain;
}

@keyframes finishBounce {
  0% { transform: scale(0.3); opacity: 0; }
  50% { transform: scale(1.15); }
  100% { transform: scale(1); opacity: 1; }
}

.finish-title {
  font-size: 24px;
  font-weight: 700;
  color: white;
  margin: 0 0 4px;
}

.finish-subtitle {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.6);
  margin: 0 0 24px;
}

.finish-stats {
  display: flex;
  justify-content: center;
  gap: 32px;
  margin-bottom: 24px;
}

.finish-stat {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  background: rgba(15, 23, 42, 0.6);
  border: 1px solid rgba(168, 85, 247, 0.3);
  border-radius: 16px;
  padding: 20px 28px;
  min-width: 120px;
}

.finish-stat-icon img {
  width: 28px;
  height: 28px;
  object-fit: contain;
}

.finish-stat-value {
  font-size: 28px;
  font-weight: 800;
  background: linear-gradient(135deg, #ec4899, #facc15);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.finish-stat-label {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.6);
  font-weight: 500;
}

.finish-details {
  background: rgba(15, 23, 42, 0.5);
  border-radius: 12px;
  padding: 12px 16px;
  margin-bottom: 16px;
}

.finish-detail-row {
  display: flex;
  justify-content: space-between;
  font-size: 14px;
  color: rgba(255, 255, 255, 0.8);
  padding: 6px 0;
}

.finish-detail-skipped {
  color: #fbbf24;
}

.finish-exercises {
  background: rgba(15, 23, 42, 0.4);
  border-radius: 12px;
  padding: 12px 16px;
  margin-bottom: 24px;
  max-height: 200px;
  overflow-y: auto;
}

.finish-exercise-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 8px 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
}

.finish-exercise-row:last-child {
  border-bottom: none;
}

.finish-ex-name {
  font-size: 13px;
  font-weight: 600;
  color: white;
}

.finish-ex-reward {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.6);
}

.finish-ex-skipped {
  font-size: 12px;
  color: rgba(251, 191, 36, 0.7);
  font-style: italic;
}

.finish-close-btn {
  width: 100%;
  padding: 14px;
  background: linear-gradient(135deg, #ec4899, #a855f7);
  border: none;
  border-radius: 12px;
  color: white;
  font-size: 16px;
  font-weight: 700;
  cursor: pointer;
  transition: all 0.3s ease;
}

.finish-close-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(168, 85, 247, 0.5);
}
</style>
