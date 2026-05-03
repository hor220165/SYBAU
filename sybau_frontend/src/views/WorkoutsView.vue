<template>
  <!-- Header -->
  <Header></Header>

  <!-- Navigation -->
  <Navbar></Navbar>

  <!-- Main Content -->
  <main class="workouts-content">
    <section class="page-heading">
      <span class="page-kicker">Workouts</span>
      <h1 class="page-title">Deine Übungen</h1>
      <p class="page-subtitle">Wähle eine Übung und trage deine Wiederholungen ein.</p>
    </section>

    <section class="mobile-stats-panel">
      <div class="stats-grid">
        <article class="stat-card">
          <span class="stat-icon stat-icon-blue">
            <CalendarDays :size="24" />
          </span>
          <span class="stat-copy">
            <span class="stat-label">Heute</span>
            <span class="stat-value">{{ formatNumber(todayReps) }} Reps</span>
          </span>
        </article>
        <article class="stat-card">
          <span class="stat-icon stat-icon-purple">
            <BarChart3 :size="24" />
          </span>
          <span class="stat-copy">
            <span class="stat-label">Gesamt</span>
            <span class="stat-value">{{ formatNumber(totalExercises) }} Reps</span>
          </span>
        </article>
        <article class="stat-card">
          <span class="stat-icon stat-icon-yellow">
            <Zap :size="24" />
          </span>
          <span class="stat-copy">
            <span class="stat-label">XP Heute</span>
            <span class="stat-value">+{{ formatNumber(todayXp) }} XP</span>
          </span>
        </article>
      </div>
    </section>

    <section class="health-grid">
      <article class="health-card">
        <Flame class="health-flame" :size="30" />
        <div>
          <span class="health-label">Schritte heute</span>
          <strong>{{ todayActivity.steps.toLocaleString('de-DE') }}</strong>
        </div>
      </article>
      <article class="health-card">
        <Flame class="health-flame" :size="30" />
        <div>
          <span class="health-label">Kilometer heute</span>
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
        {{ filter }}
      </button>
    </div>

    <!-- Workouts Grid -->
    <div class="workouts-grid">
      <WorkoutCard
          v-for="exercise in filteredExercises"
          :key="exercise.id"
          :category="exercise.category"
          :title="exercise.name"
          :duration="0"
          :calories="0"
          :exercises="[exercise.description]"
          :difficulty="exercise.difficulty"
          :xp="exercise.xpPerRep"
          :completed="exercise.todayCount >= exercise.dailyLimit"
          @log="logExercise(exercise)"
      />
    </div>

    <!-- Create Custom Workout Card -->
    <div class="custom-workout-card">
      <div class="custom-content">
        <h3>Erstelle dein eigenes Workout</h3>
        <p>Kombiniere Übungen und verdiene Bonus-XP</p>
      </div>
      <button class="create-btn" @click="showCreateWorkout = true">
        Workout erstellen
      </button>
    </div>

    <!-- Saved Workouts Section -->
    <div v-if="workouts.length > 0" class="workouts-section">
      <h2 class="section-title">Deine Workouts</h2>
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
              {{ wo.exercises?.length ?? 0 }} Übungen
            </span>
            <span class="expand-icon">{{ expandedWorkout === wo.id ? '▲' : '▼' }}</span>
          </div>
          <div v-if="expandedWorkout === wo.id" class="workout-exercises-list">
            <div v-for="ex in wo.exercises" :key="ex.exerciseId" class="workout-exercise-item">
              <span class="exercise-name-label">{{ ex.exerciseName }}</span>
              <span class="exercise-meta-label">{{ mapDifficulty(ex.difficulty) }} · Limit: {{ ex.dailyLimit }}</span>
            </div>
            <button class="start-workout-btn" @click.stop="startWorkoutSession(wo)">
              Workout starten
            </button>
          </div>
        </div>
      </div>
    </div>
  </main>

  <!-- Exercise Modal -->
  <ExerciseModal 
    :is-open="showModal"
    :exercise-name="selectedExercise?.name || ''"
    :icon="selectedExercise?.icon || ''"
    :xp-per-rep="selectedExercise?.xpPerRep || 0"
    :daily-limit="selectedExercise?.dailyLimit || 0"
    :today-count="selectedExercise?.todayCount || 0"
    @close="showModal = false"
    @submit="handleExerciseSubmit"
  />
   <!-- Footer -->
    <FooterComponent />

  <!-- Create Workout Modal -->
  <div v-if="showCreateWorkout" class="workout-modal-overlay" @click.self="showCreateWorkout = false">
    <div class="create-workout-modal">
      <div class="modal-header-cw">
        <h2>Neues Workout erstellen</h2>
        <button class="close-btn-cw" @click="showCreateWorkout = false">&times;</button>
      </div>
      <form @submit.prevent="handleCreateWorkout">
        <div class="form-group-cw">
          <label>Name</label>
          <input v-model="newWorkout.name" type="text" required placeholder="z.B. Oberkörper Power">
        </div>
        <div class="form-group-cw">
          <label>Beschreibung</label>
          <input v-model="newWorkout.description" type="text" placeholder="Optional">
        </div>
        <div class="form-group-cw">
          <label>Kategorie</label>
          <select v-model.number="newWorkout.category" required>
            <option value="" disabled>-- Wähle Kategorie --</option>
            <option :value="0">Strength</option>
            <option :value="1">Core</option>
            <option :value="2">Cardio</option>
            <option :value="3">Flexibility</option>
          </select>
        </div>
        <div class="form-group-cw">
          <label>Übungen</label>
          <div v-for="(entry, idx) in newWorkout.exercises" :key="idx" class="exercise-row-cw">
            <select v-model.number="entry.exerciseId" required>
              <option value="0" disabled>-- Übung wählen --</option>
              <option v-for="ex in exercises" :key="ex.id" :value="ex.id">{{ ex.name }}</option>
            </select>
            <input v-model.number="entry.dailyLimit" type="number" min="1" placeholder="Limit" class="limit-input-cw">
            <button type="button" class="remove-btn-cw" @click="newWorkout.exercises.splice(idx, 1)" v-if="newWorkout.exercises.length > 1">✕</button>
          </div>
          <button type="button" class="add-exercise-btn" @click="newWorkout.exercises.push({ exerciseId: 0, dailyLimit: 50 })">+ Übung hinzufügen</button>
        </div>
        <div class="modal-actions-cw">
          <button type="button" class="btn-cancel-cw" @click="showCreateWorkout = false">Abbrechen</button>
          <button type="submit" class="btn-create-cw">Erstellen</button>
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
          <h2 class="finish-title">Workout abgeschlossen!</h2>
          <p class="finish-subtitle">{{ workoutSession.name }}</p>

          <div class="finish-stats">
            <div class="finish-stat">
              <span class="finish-stat-icon">
                <img src="../assets/XP_Pixel.png" alt="" />
              </span>
              <span class="finish-stat-value">+{{ sessionTotalXp }}</span>
              <span class="finish-stat-label">XP verdient</span>
            </div>
            <div class="finish-stat">
              <span class="finish-stat-icon">
                <img src="../assets/SYBAU_Coin.png" alt="" />
              </span>
              <span class="finish-stat-value">+{{ sessionTotalCoins }}</span>
              <span class="finish-stat-label">Coins verdient</span>
            </div>
          </div>

          <div class="finish-details">
            <div class="finish-detail-row">
              <span>Übungen abgeschlossen</span>
              <span>{{ sessionActiveCount }}</span>
            </div>
            <div v-if="sessionSkippedCount > 0" class="finish-detail-row finish-detail-skipped">
              <span>Übersprungen (Limit erreicht)</span>
              <span>{{ sessionSkippedCount }}</span>
            </div>
          </div>

          <!-- Einzelne Ergebnisse -->
          <div class="finish-exercises">
            <div v-for="ex in workoutSession.exercises" :key="ex.exerciseId" class="finish-exercise-row">
              <span class="finish-ex-name">{{ ex.exerciseName }}</span>
              <template v-if="ex.skipped">
                <span class="finish-ex-skipped">Limit erreicht</span>
              </template>
              <template v-else>
                <span class="finish-ex-reward">{{ ex.repsLogged }} Reps · +{{ ex.xpEarned }} XP · +{{ ex.coinsEarned }} Coins</span>
              </template>
            </div>
          </div>

          <button class="finish-close-btn" @click="closeWorkoutSession">Fertig</button>
        </div>
      </template>

      <!-- ===== AKTIVE SESSION ===== -->
      <template v-else>
        <div class="modal-header-cw">
          <h2>{{ workoutSession.name }}</h2>
          <button class="close-btn-cw" @click="closeWorkoutSession">&times;</button>
        </div>

        <!-- Limit-Hinweis oben -->
        <div v-if="sessionSkippedCount > 0" class="session-limit-notice">
          ⚠️ {{ sessionSkippedCount }} Übung{{ sessionSkippedCount > 1 ? 'en' : '' }} übersprungen – Tageslimit bereits erreicht
        </div>

        <div class="session-exercises">
          <div v-for="(ex, idx) in workoutSession.exercises" :key="ex.exerciseId" 
               class="session-exercise-item" :class="{ 'session-done': ex.logged, 'session-skipped': ex.skipped }">
            <div class="session-exercise-info">
              <span class="session-exercise-num">{{ Number(idx) + 1 }}</span>
              <div>
                <span class="session-exercise-name">{{ ex.exerciseName }}</span>
                <span class="session-exercise-detail">{{ mapDifficulty(ex.difficulty) }} · Limit: {{ ex.dailyLimit }}</span>
              </div>
            </div>
            <div class="session-exercise-action">
              <!-- Limit erreicht -->
              <template v-if="ex.skipped">
                <span class="session-limit-badge">Limit erreicht</span>
              </template>
              <!-- Bereits geloggt -->
              <template v-else-if="ex.logged">
                <span class="session-check">{{ ex.repsLogged }} Reps</span>
                <span class="session-reward">+{{ ex.xpEarned }} XP · +{{ ex.coinsEarned }} Coins</span>
              </template>
              <!-- Noch offen -->
              <template v-else>
                <span v-if="ex.remaining < ex.dailyLimit" class="session-remaining-hint">
                  Noch {{ ex.remaining }} möglich
                </span>
                <input v-model.number="ex.repsInput" type="number" min="1" :max="ex.remaining" 
                       placeholder="Reps" class="session-reps-input">
                <button class="session-log-btn" @click="logWorkoutExercise(ex)" :disabled="!ex.repsInput || ex.repsInput < 1">
                  Eintragen
                </button>
              </template>
            </div>
          </div>
        </div>

        <!-- Session Summary -->
        <div class="session-summary">
          <div class="session-summary-row">
            <span>Fortschritt</span>
            <span>{{ sessionCompletedCount }} / {{ workoutSession.exercises.length }} Übungen</span>
          </div>
          <div class="session-progress-bar">
            <div class="session-progress-fill" :style="{ width: sessionProgressPercent + '%' }"></div>
          </div>
          <div class="session-summary-row">
            <span>Gesamt XP</span>
            <span class="session-total-xp">+{{ sessionTotalXp }}</span>
          </div>
          <div class="session-summary-row">
            <span>Gesamt Coins</span>
            <span class="session-total-coins">+{{ sessionTotalCoins }}</span>
          </div>
        </div>

        <div class="modal-actions-cw">
          <button class="btn-cancel-cw" @click="closeWorkoutSession">Schließen</button>
          <button v-if="sessionCompletedCount === workoutSession.exercises.length" class="btn-create-cw" @click="finishWorkoutSession">
            Workout abgeschlossen
          </button>
        </div>
      </template>
    </div>
  </div>

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
import ExerciseModal from '@/components/WorkoutPopup.vue';
import FooterComponent from '@/components/FooterComponent.vue';
import MessagePopup from '@/components/MessagePopup.vue';
import { workoutService, achievementService, questService } from '@/services/api';
import { useAuth } from '@/composables/useAuth';
import { BarChart3, CalendarDays, Flame, Zap } from 'lucide-vue-next';

const { refreshProfile } = useAuth();

const activeFilter = ref('Alle');
const showModal = ref(false);
const selectedExercise = ref<any>(null);
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
}

const exercises = ref<ExerciseLocal[]>([]);
const workouts = ref<any[]>([]);
const showCreateWorkout = ref(false);
const totalExercises = ref(0);
const todayActivity = ref({ steps: 0, kilometers: 0 });
const expandedWorkout = ref<number | null>(null);
const workoutSession = ref<any>(null);
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
  if (Math.abs(value) < 10000) return value.toLocaleString('de-DE');
  const units = [
    { amount: 1_000_000_000, suffix: 'B' },
    { amount: 1_000_000, suffix: 'M' },
    { amount: 1_000, suffix: 'K' }
  ];
  const unit = units.find((u) => Math.abs(value) >= u.amount);
  if (!unit) return value.toLocaleString('de-DE');
  const compact = value / unit.amount;
  const digits = compact >= 100 || Number.isInteger(compact) ? 0 : 1;
  return `${compact.toFixed(digits).replace('.', ',')}${unit.suffix}`;
}

// Stats berechnen
const todayReps = computed(() => exercises.value.reduce((sum, e) => sum + e.todayCount, 0));
const todayXp = computed(() => exercises.value.reduce((sum, e) => sum + (e.todayCount * e.xpPerRep), 0));

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
        difficulty: diff
      };
    });
  } catch (e) {
    console.error('Fehler beim Laden der Übungen', e);
  }
  loading.value = false;
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
    popupMessage.value = err.response?.data || 'Fehler beim Erstellen des Workouts';
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
      return {
        ...ex,
        repsInput: remaining,
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
  if (!ex.repsInput || ex.repsInput < 1) return;
  try {
    const res = await workoutService.logExercise(ex.exerciseId, ex.repsInput);
    const result = res.data;
    ex.logged = true;
    ex.repsLogged = ex.repsInput;
    ex.xpEarned = (result.xpEarned ?? 0) + (result.bonusXp ?? 0);
    ex.coinsEarned = (result.coinsEarned ?? 0) + (result.bonusCoins ?? 0);

    // Lokalen Exercise-Counter auch updaten
    const localEx = exercises.value.find(e => e.id === ex.exerciseId);
    if (localEx) localEx.todayCount += ex.repsInput;

    await refreshProfile();
  } catch (err: any) {
    popupType.value = 'error';
    popupMessage.value = err.response?.data || 'Fehler beim Eintragen';
  }
}

const logExercise = (exercise: any) => {
  selectedExercise.value = exercise;
  showModal.value = true;
};

const handleExerciseSubmit = async (data: any) => {
  const exercise = exercises.value.find(e => e.name === data.exercise);
  if (!exercise) return;

  try {
    const res = await workoutService.logExercise(exercise.id, data.reps);
    const result = res.data;

    // Update lokalen todayCount
    exercise.todayCount += data.reps;

    // Zeige echte XP/Coin-Ergebnisse vom Backend
    let msg = `${data.exercise}: ${data.reps} Reps eingetragen!\n`;
    msg += `+${result.xpEarned ?? data.xp} XP`;
    if (result.bonusXp > 0) msg += ` (+${result.bonusXp} Bonus, ${result.boostPercent}% Boost)`;
    if (result.coinsEarned > 0) {
      msg += `\n+${result.coinsEarned} Coins`;
      if (result.bonusCoins > 0) msg += ` (+${result.bonusCoins} Bonus, ${result.coinBoostPercent}% Boost)`;
    }
    popupType.value = 'success';
    popupMessage.value = msg;

    // Header aktualisieren (Level, XP, Coins)
    await refreshProfile();
  } catch (err: any) {
    const errorMsg = err.response?.data || 'Fehler beim Eintragen';
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

.page-kicker {
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
    grid-template-columns: 1fr;
    gap: 12px;
  }

  .health-grid {
    grid-template-columns: 1fr;
  }

  .stat-label {
    font-size: 15px;
  }

  .stat-value {
    font-size: 22px;
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
    min-height: 116px;
    padding: 14px;
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
