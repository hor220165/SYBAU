<template>
  <!-- Header -->
  <Header></Header>

  <!-- Navigation -->
  <Navbar></Navbar>

  <!-- Main Content -->
  <main class="workouts-content">
    <!-- Stats Header -->
    <div class="stats-header">
      <h1 class="page-title">Deine Übungen</h1>
      <p class="page-subtitle">Wähle eine Übung und trage deine Wiederholungen ein!</p>

      <div class="stats-grid">
        <div class="stat-card">
          <span class="stat-label">Heute</span>
          <span class="stat-value">245 Wiederholungen</span>
        </div>
        <div class="stat-card">
          <span class="stat-label">Diese Woche</span>
          <span class="stat-value">1,832 Wiederholungen</span>
        </div>
        <div class="stat-card">
          <span class="stat-label">XP Heute</span>
          <span class="stat-value">+490 XP</span>
        </div>
      </div>
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

    <!-- Loading / Error State -->
    <div v-if="loading" class="loading-state">Übungen werden geladen…</div>
    <div v-else-if="error" class="error-state">{{ error }}</div>

    <!-- Workouts Grid -->
    <div v-else class="workouts-grid">
      <!-- BEISPIELDATEN (zum Vergleich) -->
      <div class="dummy-wrapper">
        <span class="dummy-label">📌 Beispieldaten</span>
        <WorkoutCard
            :category="dummyExercise.category"
            :title="dummyExercise.name"
            :duration="0"
            :calories="0"
            :exercises="[dummyExercise.description]"
            :difficulty="dummyExercise.difficulty"
            :xp="dummyExercise.xpPerRep"
            :completed="dummyExercise.todayCount >= dummyExercise.dailyLimit"
            @log="logExercise(dummyExercise)"
        />
      </div>

      <!-- BACKEND-DATEN -->
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
    <div v-if="successMessage" class="success-message">{{ successMessage }}</div>

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

    <!-- Create Workout Modal -->
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
                <option v-for="cat in createCategories" :key="cat" :value="cat">{{ cat }}</option>
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
              <input v-model.number="createForm.duration" class="form-input" type="number" min="1" max="240" required />
            </label>
            <label class="form-label">
              Kalorien
              <input v-model.number="createForm.calories" class="form-input" type="number" min="0" max="5000" required />
            </label>
            <label class="form-label">
              XP
              <input v-model.number="createForm.xp" class="form-input" type="number" min="0" max="10000" required />
            </label>
          </div>

          <div class="exercise-section">
            <div class="exercise-header">
              <span>Übungen aus Backend</span>
              <span v-if="loadingExercises" class="mini-note">Lade Übungen...</span>
            </div>
            <div v-if="exerciseOptions.length" class="exercise-grid">
              <label v-for="ex in exerciseOptions" :key="ex.value" class="exercise-option">
                <input v-model="selectedExerciseValues" type="checkbox" :value="ex.value" />
                <span>{{ ex.name }}</span>
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
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue';
import Header from '@/components/Header.vue';
import Navbar from '@/components/Navbar.vue';
import WorkoutCard from '@/components/WorkoutCard.vue';
import ExerciseModal from '@/components/WorkoutPopup.vue';
import FooterComponent from '@/components/FooterComponent.vue';
import { workoutService } from '@/services/api';

type Difficulty = 'Easy' | 'Medium' | 'Hard';

interface ExerciseOption {
  value: string;
  id: number | null;
  name: string;
  category: string;
}

const activeFilter = ref('Alle');
const showModal = ref(false);
const selectedExercise = ref<any>(null);
const loading = ref(false);
const error = ref<string | null>(null);

// Create Workout Modal
const showCreateModal = ref(false);
const loadingExercises = ref(false);
const submittingWorkout = ref(false);
const formError = ref('');
const successMessage = ref('');
const exerciseOptions = ref<ExerciseOption[]>([]);
const selectedExerciseValues = ref<string[]>([]);

const createCategories = ['Arms', 'UpperBody', 'LowerBody', 'Core', 'FullBody', 'Cardio'];

const createForm = ref({
  title: '',
  category: 'Cardio',
  duration: 30,
  calories: 250,
  difficulty: 'Medium' as Difficulty,
  xp: 300
});

const filters = ['Alle', 'Cardio', 'Strength', 'Core', 'Flexibility'];

// Ein Dummy-Eintrag zum Vergleich mit Backend-Daten
const dummyExercise = {
  id: 0,
  name: 'Push-Ups',
  description: 'Klassische Liegestütze',
  category: 'Strength',
  icon: '💪',
  xpPerRep: 2,
  dailyLimit: 200,
  todayCount: 45,
  difficulty: 'Medium' as const
};

// Backend-Daten
const exercises = ref<any[]>([]);

onMounted(async () => {
  loading.value = true;
  error.value = null;
  try {
    const { data } = await workoutService.getExercises();
    exercises.value = (Array.isArray(data) ? data : data.exercises ?? []).map((e: any) => ({
      id: e.id,
      name: e.name,
      description: e.description ?? '',
      category: e.category ?? 'Strength',
      icon: e.icon ?? '🏋️',
      xpPerRep: e.xpPerRep ?? e.xpperrep ?? 0,
      dailyLimit: e.dailyLimit ?? e.dailylimit ?? 100,
      todayCount: e.todayCount ?? e.todaycount ?? 0,
      difficulty: e.difficulty ?? 'Medium'
    }));
  } catch (err: any) {
    error.value = 'Übungen konnten nicht geladen werden.';
    console.error(err);
  } finally {
    loading.value = false;
  }
});


const filteredExercises = computed(() => {
  if (activeFilter.value === 'Alle') {
    return exercises.value;
  }
  return exercises.value.filter(e => e.category === activeFilter.value);
});

const logExercise = (exercise: any) => {
  selectedExercise.value = exercise;
  showModal.value = true;
};

const handleExerciseSubmit = (data: any) => {
  console.log('Exercise logged:', data);
  
  // Update todayCount lokal
  const exercise = exercises.value.find(e => e.name === data.exercise);
  if (exercise) {
    exercise.todayCount += data.reps;
  }
  if (selectedExercise.value?.id === dummyExercise.id) {
    dummyExercise.todayCount += data.reps;
  }

  // TODO: Send to backend (kein dedizierter Log-Endpoint noch)
  alert(`${data.exercise}: ${data.reps} Wiederholungen eingetragen! +${data.xp} XP gewonnen!`);
};

// ── Create Workout ─────────────────────────────────────────

const normalizeExerciseOpt = (raw: any, index: number): ExerciseOption => {
  const idRaw = raw?.id ?? raw?.Id;
  const id = Number.isFinite(Number(idRaw)) ? Number(idRaw) : null;
  const name = String(raw?.name ?? raw?.Name ?? raw?.title ?? raw?.Title ?? `Übung ${index + 1}`);
  const category = String(raw?.category ?? raw?.Category ?? createForm.value.category);
  return {
    value: id !== null ? `id:${id}` : `name:${name}:${index}`,
    id,
    name,
    category
  };
};

const selectedExerciseIds = computed(() =>
  exerciseOptions.value
    .filter(opt => selectedExerciseValues.value.includes(opt.value))
    .map(opt => opt.id)
    .filter((id): id is number => id !== null)
);

const loadExercisesForCreate = async (category?: string) => {
  loadingExercises.value = true;
  formError.value = '';
  try {
    const { data } = await workoutService.getExercises(category);
    const list = (Array.isArray(data) ? data : data?.exercises ?? []) as any[];
    exerciseOptions.value = list.map((e, i) => normalizeExerciseOpt(e, i));
    const validValues = new Set(exerciseOptions.value.map(o => o.value));
    selectedExerciseValues.value = selectedExerciseValues.value.filter(v => validValues.has(v));
  } catch {
    exerciseOptions.value = [];
    formError.value = 'Übungen konnten nicht geladen werden.';
  } finally {
    loadingExercises.value = false;
  }
};

const resetCreateForm = () => {
  createForm.value = { title: '', category: 'Cardio', duration: 30, calories: 250, difficulty: 'Medium', xp: 300 };
  selectedExerciseValues.value = [];
  formError.value = '';
};

const openCreateModal = async () => {
  showCreateModal.value = true;
  successMessage.value = '';
  await loadExercisesForCreate(createForm.value.category);
};

const closeCreateModal = () => {
  showCreateModal.value = false;
  resetCreateForm();
};

const categoryToEnumValue = (category: string): number => {
  const mapping: Record<string, number> = {
    Arms: 0, UpperBody: 1, LowerBody: 2, Core: 3, FullBody: 4, Cardio: 5
  };
  return mapping[category] ?? 0;
};

const submitWorkout = async () => {
  formError.value = '';
  if (!createForm.value.title) {
    formError.value = 'Bitte gib einen Namen ein.';
    return;
  }
  if (selectedExerciseValues.value.length === 0) {
    formError.value = 'Bitte wähle mindestens eine Übung aus.';
    return;
  }
  if (selectedExerciseIds.value.length !== selectedExerciseValues.value.length) {
    formError.value = 'Mindestens eine Übung hat keine gültige ID.';
    return;
  }
  submittingWorkout.value = true;
  try {
    await workoutService.createWorkout({
      name: createForm.value.title,
      category: categoryToEnumValue(createForm.value.category),
      exercises: selectedExerciseIds.value.map(exerciseId => ({ exerciseId, dailyLimit: 1 }))
    });
    closeCreateModal();
    successMessage.value = 'Workout wurde erfolgreich erstellt!';
  } catch (err: any) {
    const msg = err?.response?.data?.message ?? err?.response?.data?.title ?? 'Workout konnte nicht erstellt werden.';
    formError.value = msg;
  } finally {
    submittingWorkout.value = false;
  }
};

watch(
  () => createForm.value.category,
  async (newCat) => {
    if (!showCreateModal.value) return;
    await loadExercisesForCreate(newCat);
  }
);
</script>

<style scoped>
.workouts-content {
  padding: 40px;
  max-width: 1400px;
  margin: 0 auto;
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
  border: 2px solid rgba(236, 72, 153, 0.4);
  border-radius: 20px;
  padding: 40px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  backdrop-filter: blur(10px);
  transition: all 0.3s ease;
}

.custom-workout-card:hover {
  border-color: rgba(236, 72, 153, 0.6);
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

.create-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 16px rgba(168, 85, 247, 0.3);
}

/* Loading / Error */
.loading-state,
.error-state {
  text-align: center;
  padding: 40px;
  font-size: 18px;
  color: rgba(255, 255, 255, 0.7);
  margin-bottom: 40px;
}
.error-state {
  color: #f87171;
}

/* Success Message */
.success-message {
  border-radius: 14px;
  padding: 14px 16px;
  margin-bottom: 20px;
  font-weight: 600;
  background: rgba(22, 163, 74, 0.2);
  border: 1px solid rgba(22, 163, 74, 0.35);
  color: #bbf7d0;
}

/* Create Workout Modal */
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
  max-height: 90vh;
  overflow-y: auto;
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
  cursor: pointer;
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

/* Dummy-Wrapper */
.dummy-wrapper {
  position: relative;
}
.dummy-label {
  display: inline-block;
  margin-bottom: 8px;
  padding: 4px 12px;
  background: rgba(234, 179, 8, 0.25);
  border: 1px solid rgba(234, 179, 8, 0.5);
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  color: #fbbf24;
  letter-spacing: 0.5px;
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
}

@media (max-width: 768px) {
  .modal-actions {
    flex-direction: column;
  }
}
</style>