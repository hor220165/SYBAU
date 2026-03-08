<template>
  <!-- Header -->
  <Header></Header>

  <!-- Navigation -->
  <Navbar></Navbar>

  <!-- Main Content -->
  <main class="workouts-content">
    <!-- Stats Header -->
    <div class="stats-header">
      <h1 class="page-title">Deine Workouts</h1>
      <p class="page-subtitle">Wähle ein Workout und starte dein Training!</p>

      <div class="stats-grid">
        <div class="stat-card">
          <span class="stat-label">Diese Woche</span>
          <span class="stat-value">{{ workouts.length }} Workouts</span>
        </div>
        <div class="stat-card">
          <span class="stat-label">Trainingszeit</span>
          <span class="stat-value">{{ totalHours }} Stunden</span>
        </div>
        <div class="stat-card">
          <span class="stat-label">Kalorien</span>
          <span class="stat-value">{{ totalCalories }} kcal</span>
        </div>
      </div>
    </div>

    <div v-if="successMessage" class="success-message">
      {{ successMessage }}
    </div>

    <div v-if="errorMessage" class="error-message">
      {{ errorMessage }}
    </div>

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

    <div v-if="loadingWorkouts" class="loading-state">Lade Workouts...</div>

    <!-- Workouts Grid -->
    <div v-if="!loadingWorkouts && filteredWorkouts.length" class="workouts-grid">
      <WorkoutCard
          v-for="workout in filteredWorkouts"
          :key="workout.id"
          :category="workout.category"
          :title="workout.title"
          :duration="workout.duration"
          :calories="workout.calories"
          :exercises="workout.exercises"
          :difficulty="workout.difficulty"
          :xp="workout.xp"
          :completed="workout.completed"
          @start="startWorkout(workout.id)"
          @view="viewWorkout(workout.id)"
      />
    </div>

    <div v-if="!loadingWorkouts && !filteredWorkouts.length" class="empty-state">
      Keine Workouts in dieser Kategorie gefunden.
    </div>

    <!-- Create Custom Workout Card -->
    <div class="custom-workout-card">
      <div class="custom-content">
        <h3>Erstelle dein eigenes Workout</h3>
        <p>Kombiniere Übungen und verdiene Bonus-XP</p>
      </div>
      <button class="create-btn" @click="openCreateModal">
        Workout erstellen
        <span class="icon">→</span>
      </button>
    </div>

    <div v-if="showCreateModal" class="modal-overlay" @click.self="closeCreateModal">
      <div class="modal-card">
        <h3 class="modal-title">Eigenes Workout erstellen</h3>

        <form class="create-form" @submit.prevent="submitWorkout">
          <label class="form-label">
            Name
            <input v-model.trim="createForm.title" class="form-input" type="text" required />
          </label>

          <div class="form-grid">
            <label class="form-label">
              Kategorie
              <select v-model="createForm.category" class="form-select" required>
                <option v-for="category in createCategories" :key="category" :value="category">
                  {{ category }}
                </option>
              </select>
            </label>

            <label class="form-label">
              Schwierigkeit
              <select v-model="createForm.difficulty" class="form-select" required>
                <option value="Easy">Easy</option>
                <option value="Medium">Medium</option>
                <option value="Hard">Hard</option>
              </select>
            </label>

            <label class="form-label">
              Dauer (Min)
              <input
                v-model.number="createForm.duration"
                class="form-input"
                type="number"
                min="1"
                max="240"
                required
              />
            </label>

            <label class="form-label">
              Kalorien
              <input
                v-model.number="createForm.calories"
                class="form-input"
                type="number"
                min="0"
                max="5000"
                required
              />
            </label>

            <label class="form-label">
              XP
              <input
                v-model.number="createForm.xp"
                class="form-input"
                type="number"
                min="0"
                max="10000"
                required
              />
            </label>
          </div>

          <div class="exercise-section">
            <div class="exercise-header">
              <span>Übungen aus Backend</span>
              <span v-if="loadingExercises" class="mini-note">Lade Übungen...</span>
            </div>

            <div v-if="exerciseOptions.length" class="exercise-grid">
              <label
                v-for="exercise in exerciseOptions"
                :key="exercise.value"
                class="exercise-option"
              >
                <input
                  v-model="selectedExerciseValues"
                  type="checkbox"
                  :value="exercise.value"
                />
                <span>{{ exercise.name }}</span>
              </label>
            </div>
            <p v-else class="mini-note">Keine Übungen für diese Kategorie gefunden.</p>
          </div>

          <p v-if="formError" class="form-error">{{ formError }}</p>

          <div class="modal-actions">
            <button type="button" class="secondary-btn" @click="closeCreateModal">Abbrechen</button>
            <button type="submit" class="primary-btn" :disabled="submittingWorkout">
              {{ submittingWorkout ? 'Speichere...' : 'Workout speichern' }}
            </button>
          </div>
        </form>
      </div>
    </div>
  </main>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import Header from '@/components/Header.vue';
import Navbar from '@/components/Navbar.vue';
import WorkoutCard from '@/components/WorkoutCard.vue';
import { workoutService } from '@/services/api';

type Difficulty = 'Easy' | 'Medium' | 'Hard';

interface Workout {
  id: number;
  category: string;
  title: string;
  duration: number;
  calories: number;
  exercises: string[];
  difficulty: Difficulty;
  xp: number;
  completed: boolean;
}

interface ExerciseOption {
  value: string;
  id: number | null;
  name: string;
  category: string;
}

const activeFilter = ref('Alle');
const loadingWorkouts = ref(false);
const loadingExercises = ref(false);
const submittingWorkout = ref(false);
const errorMessage = ref('');
const successMessage = ref('');
const showCreateModal = ref(false);
const formError = ref('');
const selectedExerciseValues = ref<string[]>([]);
const exerciseOptions = ref<ExerciseOption[]>([]);

const filters = ['Alle', 'Arms', 'UpperBody', 'LowerBody', 'Core', 'FullBody', 'Cardio'];
const createCategories = ['Arms', 'UpperBody', 'LowerBody', 'Core', 'FullBody', 'Cardio'];

const createForm = ref({
  title: '',
  category: 'Cardio',
  duration: 30,
  calories: 250,
  difficulty: 'Medium' as Difficulty,
  xp: 300
});

const workouts = ref<Workout[]>([]);

const filterToCategory: Record<string, string> = {
  Arms: 'Arms',
  UpperBody: 'UpperBody',
  LowerBody: 'LowerBody',
  Core: 'Core',
  FullBody: 'FullBody',
  Cardio: 'Cardio'
};

const normalizeCategory = (value: unknown): string => {
  const raw = String(value ?? '').trim();
  const lowered = raw.toLowerCase();
  if (lowered === 'arms') return 'Arms';
  if (lowered === 'upperbody' || lowered === 'upper_body' || lowered === 'upper body') return 'UpperBody';
  if (lowered === 'lowerbody' || lowered === 'lower_body' || lowered === 'lower body') return 'LowerBody';
  if (lowered === 'cardio') return 'Cardio';
  if (lowered === 'core') return 'Core';
  if (lowered === 'fullbody' || lowered === 'full_body' || lowered === 'full body') return 'FullBody';
  return raw || 'Core';
};

const categoryToEnumValue = (category: string): number => {
  const normalized = normalizeCategory(category);
  const mapping: Record<string, number> = {
    Arms: 0,
    UpperBody: 1,
    LowerBody: 2,
    Core: 3,
    FullBody: 4,
    Cardio: 5
  };
  return mapping[normalized] ?? 0;
};

const extractApiErrorMessage = (error: unknown, fallback: string): string => {
  const maybeError = error as {
    response?: {
      data?: {
        message?: string;
        title?: string;
        errors?: Record<string, string[] | undefined>;
      } | string;
    };
  };

  const rawData = maybeError.response?.data;
  if (typeof rawData === 'string' && rawData.trim()) {
    return rawData;
  }

  if (rawData && typeof rawData === 'object') {
    const message = rawData.message ?? rawData.title;
    if (message) return message;

    const firstErrorList = Object.values(rawData.errors ?? {}).find(
      (entry): entry is string[] => Array.isArray(entry) && entry.length > 0
    );
    if (firstErrorList?.[0]) return firstErrorList[0];
  }

  return fallback;
};

const normalizeDifficulty = (value: unknown): Difficulty => {
  if (typeof value === 'number') {
    if (value <= 0) return 'Easy';
    if (value === 1) return 'Medium';
    return 'Hard';
  }

  const lowered = String(value ?? '').toLowerCase();
  if (lowered.includes('easy')) return 'Easy';
  if (lowered.includes('medium')) return 'Medium';
  if (lowered.includes('hard')) return 'Hard';
  return 'Medium';
};

const toNumber = (value: unknown, fallback = 0): number => {
  const numeric = Number(value);
  return Number.isFinite(numeric) ? numeric : fallback;
};

const toStringArray = (value: unknown): string[] => {
  if (!Array.isArray(value)) return [];

  return value
    .map((entry) => {
      if (typeof entry === 'string') return entry;
      if (typeof entry === 'object' && entry !== null) {
        const maybeName = (entry as Record<string, unknown>).name
          ?? (entry as Record<string, unknown>).Name
          ?? (entry as Record<string, unknown>).exerciseName
          ?? (entry as Record<string, unknown>).ExerciseName
          ?? (entry as Record<string, unknown>).title
          ?? (entry as Record<string, unknown>).Title;
        return maybeName ? String(maybeName) : '';
      }
      return '';
    })
    .filter((entry) => Boolean(entry));
};

const normalizeWorkout = (rawWorkout: unknown, index: number): Workout => {
  const raw = (rawWorkout ?? {}) as Record<string, unknown>;
  const id = toNumber(raw.id ?? raw.Id, index + 1);
  const category = normalizeCategory(raw.category ?? raw.Category);
  const title = String(raw.title ?? raw.Title ?? raw.name ?? raw.Name ?? `Workout ${id}`);
  const duration = toNumber(raw.duration ?? raw.Duration ?? raw.durationMinutes ?? raw.DurationMinutes, 30);
  const calories = toNumber(raw.calories ?? raw.Calories, 200);
  const exercises = toStringArray(raw.exercises ?? raw.Exercises);
  const difficulty = normalizeDifficulty(raw.difficulty ?? raw.Difficulty);
  const xp = toNumber(raw.xp ?? raw.Xp ?? raw.xpReward ?? raw.XpReward, 100);
  const completed = Boolean(raw.completed ?? raw.Completed ?? false);

  return {
    id,
    category,
    title,
    duration,
    calories,
    exercises,
    difficulty,
    xp,
    completed
  };
};

const normalizeExercise = (rawExercise: unknown, index: number): ExerciseOption => {
  const raw = (rawExercise ?? {}) as Record<string, unknown>;
  const idRaw = raw.id ?? raw.Id;
  const id = Number.isFinite(Number(idRaw)) ? Number(idRaw) : null;
  const name = String(raw.name ?? raw.Name ?? raw.title ?? raw.Title ?? rawExercise ?? `Uebung ${index + 1}`);
  const category = normalizeCategory(raw.category ?? raw.Category ?? createForm.value.category);

  return {
    value: id !== null ? `id:${id}` : `name:${name}:${index}`,
    id,
    name,
    category
  };
};

const extractList = (raw: unknown): unknown[] => {
  if (Array.isArray(raw)) return raw;
  if (raw && typeof raw === 'object') {
    const data = (raw as Record<string, unknown>).data;
    if (Array.isArray(data)) return data;
  }
  return [];
};

const selectedExercises = computed(() => {
  const selected = new Set(selectedExerciseValues.value);
  return exerciseOptions.value.filter((option) => selected.has(option.value));
});

const selectedExerciseIds = computed(() =>
  selectedExercises.value
    .map((exercise) => exercise.id)
    .filter((id): id is number => id !== null)
);

const totalHours = computed(() => {
  const totalMinutes = workouts.value.reduce((sum, workout) => sum + workout.duration, 0);
  return (totalMinutes / 60).toFixed(1);
});

const totalCalories = computed(() =>
  workouts.value.reduce((sum, workout) => sum + workout.calories, 0).toLocaleString('de-DE')
);

const loadWorkouts = async () => {
  loadingWorkouts.value = true;
  errorMessage.value = '';
  try {
    const response = await workoutService.getWorkouts();
    const list = extractList(response.data).map((entry, index) => normalizeWorkout(entry, index));
    workouts.value = list;
  } catch (error) {
    console.error('Fehler beim Laden der Workouts:', error);
    errorMessage.value = 'Workouts konnten nicht geladen werden.';
  } finally {
    loadingWorkouts.value = false;
  }
};

const loadExercises = async (category?: string) => {
  loadingExercises.value = true;
  formError.value = '';
  try {
    const response = await workoutService.getExercises(category);
    const list = extractList(response.data).map((entry, index) => normalizeExercise(entry, index));
    exerciseOptions.value = list;

    const validValues = new Set(list.map((entry) => entry.value));
    selectedExerciseValues.value = selectedExerciseValues.value.filter((value) => validValues.has(value));
  } catch (error) {
    console.error('Fehler beim Laden der Uebungen:', error);
    exerciseOptions.value = [];
    formError.value = 'Uebungen konnten nicht geladen werden.';
  } finally {
    loadingExercises.value = false;
  }
};

const filteredWorkouts = computed(() => {
  if (activeFilter.value === 'Alle') {
    return workouts.value;
  }
  const mappedFilter = filterToCategory[activeFilter.value] || activeFilter.value;
  return workouts.value.filter(w => w.category === mappedFilter);
});

const resetCreateForm = () => {
  createForm.value = {
    title: '',
    category: 'Cardio',
    duration: 30,
    calories: 250,
    difficulty: 'Medium',
    xp: 300
  };
  selectedExerciseValues.value = [];
  formError.value = '';
};

const openCreateModal = async () => {
  showCreateModal.value = true;
  successMessage.value = '';
  await loadExercises(createForm.value.category);
};

const closeCreateModal = () => {
  showCreateModal.value = false;
  resetCreateForm();
};

const submitWorkout = async () => {
  formError.value = '';

  if (!createForm.value.title) {
    formError.value = 'Bitte gib einen Namen ein.';
    return;
  }

  if (selectedExerciseValues.value.length === 0) {
    formError.value = 'Bitte waehle mindestens eine Uebung aus.';
    return;
  }

  if (selectedExerciseIds.value.length !== selectedExerciseValues.value.length) {
    formError.value = 'Mindestens eine ausgewaehlte Uebung hat keine gueltige ID.';
    return;
  }

  submittingWorkout.value = true;

  try {
    await workoutService.createWorkout({
      name: createForm.value.title,
      description: undefined,
      category: categoryToEnumValue(createForm.value.category),
      exercises: selectedExerciseIds.value.map((exerciseId) => ({
        exerciseId,
        dailyLimit: 1
      }))
    });

    closeCreateModal();
    await loadWorkouts();
    successMessage.value = 'Workout wurde erfolgreich erstellt.';
  } catch (error: unknown) {
    console.error('Fehler beim Erstellen des Workouts:', error);
    formError.value = extractApiErrorMessage(error, 'Workout konnte nicht erstellt werden.');
  } finally {
    submittingWorkout.value = false;
  }
};

const startWorkout = (id: number) => {
  console.log('Starting workout:', id);
  // TODO: Navigate to workout detail or start workout
};

const viewWorkout = (id: number) => {
  console.log('Viewing workout:', id);
  // TODO: Show workout details
};

watch(
  () => createForm.value.category,
  async (newCategory) => {
    if (!showCreateModal.value) return;
    await loadExercises(newCategory);
  }
);

onMounted(async () => {
  await loadWorkouts();
});
</script>

<style scoped>
.workouts-container {
  min-height: 100vh;
  color: white;
}

.workouts-content {
  padding: 40px;
  max-width: 1400px;
  margin: 0 auto;
}

.loading-state,
.empty-state,
.error-message,
.success-message {
  border-radius: 14px;
  padding: 14px 16px;
  margin-bottom: 16px;
  font-weight: 600;
}

.loading-state,
.empty-state {
  background: rgba(255, 255, 255, 0.08);
  color: rgba(255, 255, 255, 0.85);
}

.error-message {
  background: rgba(220, 38, 38, 0.2);
  border: 1px solid rgba(220, 38, 38, 0.35);
  color: #fecaca;
}

.success-message {
  background: rgba(22, 163, 74, 0.2);
  border: 1px solid rgba(22, 163, 74, 0.35);
  color: #bbf7d0;
}

/* Stats Header */
.stats-header {
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  border-radius: 24px;
  padding: 40px;
  margin-bottom: 40px;
}

.page-title {
  font-size: 32px;
  font-weight: 700;
  margin: 0 0 8px 0;
  color: white;
}

.page-subtitle {
  font-size: 16px;
  margin: 0 0 32px 0;
  color: rgba(255, 255, 255, 0.9);
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 20px;
}

.stat-card {
  background: rgba(255, 255, 255, 0.15);
  backdrop-filter: blur(10px);
  border-radius: 16px;
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.stat-label {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.8);
}

.stat-value {
  font-size: 24px;
  font-weight: 700;
  color: white;
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
  border: 1px solid rgba(255, 255, 255, 0.2);
  background: rgba(30, 41, 59, 0.6);
  color: rgba(255, 255, 255, 0.7);
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
  backdrop-filter: blur(10px);
}

.filter-btn:hover {
  background: rgba(255, 255, 255, 0.1);
  color: white;
}

.filter-btn.active {
 background: linear-gradient(135deg, #ec4899, #f43f5e);
  color: white;
  border-color: transparent;
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
  border: 2px dashed rgba(168, 85, 247, 0.4);
  border-radius: 20px;
  padding: 40px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  backdrop-filter: blur(10px);
  transition: all 0.3s ease;
}

.custom-workout-card:hover {
  border-color: rgba(168, 85, 247, 0.6);
  background: rgba(30, 41, 59, 0.8);
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
  background: linear-gradient(90deg, #a855f7, #ec4899);
  color: white;
  font-weight: 600;
  font-size: 16px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.3s ease;
}

.create-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(168, 85, 247, 0.3);
}

.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.7);
  backdrop-filter: blur(3px);
  display: grid;
  place-items: center;
  z-index: 1000;
  padding: 20px;
}

.modal-card {
  width: min(760px, 100%);
  background: #0f172a;
  border: 1px solid rgba(236, 72, 153, 0.4);
  border-radius: 18px;
  padding: 24px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.45);
}

.modal-title {
  margin: 0 0 18px 0;
  color: white;
}

.create-form {
  display: grid;
  gap: 16px;
}

.form-grid {
  display: grid;
  gap: 12px;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
}

.form-label {
  display: grid;
  gap: 8px;
  color: rgba(255, 255, 255, 0.8);
  font-size: 14px;
}

.form-input,
.form-select {
  border-radius: 10px;
  border: 1px solid rgba(148, 163, 184, 0.45);
  background: rgba(15, 23, 42, 0.8);
  color: white;
  padding: 10px 12px;
}

.exercise-section {
  border: 1px solid rgba(148, 163, 184, 0.35);
  border-radius: 12px;
  padding: 12px;
}

.exercise-header {
  display: flex;
  justify-content: space-between;
  gap: 10px;
  margin-bottom: 10px;
  color: white;
  font-weight: 600;
}

.exercise-grid {
  display: grid;
  gap: 8px;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
}

.exercise-option {
  display: flex;
  gap: 8px;
  align-items: center;
  padding: 8px;
  border-radius: 8px;
  background: rgba(148, 163, 184, 0.12);
  color: rgba(255, 255, 255, 0.9);
}

.mini-note {
  color: rgba(255, 255, 255, 0.72);
  font-size: 13px;
}

.form-error {
  color: #fecaca;
  background: rgba(220, 38, 38, 0.2);
  border: 1px solid rgba(220, 38, 38, 0.35);
  border-radius: 10px;
  padding: 10px;
  margin: 0;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
}

.secondary-btn,
.primary-btn {
  border-radius: 10px;
  border: 1px solid transparent;
  padding: 10px 14px;
  font-weight: 600;
  cursor: pointer;
}

.secondary-btn {
  background: rgba(148, 163, 184, 0.2);
  color: white;
  border-color: rgba(148, 163, 184, 0.35);
}

.primary-btn {
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  color: white;
}

.primary-btn:disabled {
  opacity: 0.65;
  cursor: not-allowed;
}

/* Responsive */
@media (max-width: 768px) {
  .workouts-content {
    padding: 20px;
  }
  
  .workouts-grid {
    grid-template-columns: 1fr;
  }
  
  .custom-workout-card {
    flex-direction: column;
    gap: 20px;
    text-align: center;
  }

  .modal-actions {
    flex-direction: column;
  }
}
</style>