<template>
  <div class="admin-workout-panel">
    <div class="section-header">
      <h2>Workout Management</h2>
      <p class="section-subtitle">Erstelle Übungen und Workouts direkt aus dem Backend.</p>
    </div>

    <div class="panel-grid">
      <section class="form-container">
        <h3>Neue Übung erstellen</h3>
        <form @submit.prevent="submitExercise">
          <div class="form-group">
            <label for="exercise-name">Name</label>
            <input
              id="exercise-name"
              v-model.trim="exerciseForm.name"
              type="text"
              required
              placeholder="z.B. Burpees"
            />
          </div>

          <div class="form-group">
            <label for="exercise-category">Kategorie</label>
            <select id="exercise-category" v-model="exerciseForm.category" required>
              <option v-for="category in categories" :key="category" :value="category">
                {{ category }}
              </option>
            </select>
          </div>

          <div class="form-group">
            <label for="exercise-description">Beschreibung</label>
            <textarea
              id="exercise-description"
              v-model.trim="exerciseForm.description"
              placeholder="Optional: kurze Beschreibung"
            ></textarea>
          </div>

          <div class="form-actions">
            <button type="submit" class="btn-primary" :disabled="savingExercise">
              {{ savingExercise ? 'Speichere...' : 'Übung erstellen' }}
            </button>
          </div>
        </form>
      </section>

      <section class="form-container">
        <h3>Neues Workout erstellen</h3>
        <form @submit.prevent="submitWorkout">
          <div class="form-group">
            <label for="workout-title">Name</label>
            <input
              id="workout-title"
              v-model.trim="workoutForm.title"
              type="text"
              required
              placeholder="z.B. Full Body Blast"
            />
          </div>

          <div class="form-group">
            <label for="workout-description">Beschreibung</label>
            <textarea
              id="workout-description"
              v-model.trim="workoutForm.description"
              placeholder="Optional: kurze Workout-Beschreibung"
            ></textarea>
          </div>

          <div class="form-row">
            <div class="form-group">
              <label for="workout-category">Kategorie</label>
              <select id="workout-category" v-model="workoutForm.category" required>
                <option v-for="category in categories" :key="category" :value="category">
                  {{ category }}
                </option>
              </select>
            </div>

            <div class="form-group">
              <label for="workout-difficulty">Schwierigkeit</label>
              <select id="workout-difficulty" v-model="workoutForm.difficulty" required>
                <option value="Easy">Easy</option>
                <option value="Medium">Medium</option>
                <option value="Hard">Hard</option>
              </select>
            </div>

            <div class="form-group">
              <label for="workout-duration">Dauer (Min)</label>
              <input
                id="workout-duration"
                v-model.number="workoutForm.duration"
                type="number"
                min="1"
                max="240"
                required
              />
            </div>

            <div class="form-group">
              <label for="workout-calories">Kalorien</label>
              <input
                id="workout-calories"
                v-model.number="workoutForm.calories"
                type="number"
                min="0"
                max="5000"
                required
              />
            </div>

            <div class="form-group">
              <label for="workout-xp">XP</label>
              <input
                id="workout-xp"
                v-model.number="workoutForm.xp"
                type="number"
                min="0"
                max="10000"
                required
              />
            </div>
          </div>

          <div class="exercise-picker">
            <div class="exercise-picker-header">
              <strong>Vorhandene Übungen</strong>
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

          <div class="form-actions">
            <button type="submit" class="btn-primary" :disabled="savingWorkout">
              {{ savingWorkout ? 'Speichere...' : 'Workout erstellen' }}
            </button>
          </div>
        </form>
      </section>
    </div>

    <div v-if="statusMessage" :class="['status-inline', statusType]">
      {{ statusMessage }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue';
import { adminService, workoutService } from '@/services/api';

type Difficulty = 'Easy' | 'Medium' | 'Hard';

interface ExerciseOption {
  value: string;
  id: number | null;
  name: string;
}

const categories = ['Arms', 'UpperBody', 'LowerBody', 'Core', 'FullBody', 'Cardio'];

const statusMessage = ref('');
const statusType = ref<'success' | 'error'>('success');
const loadingExercises = ref(false);
const savingExercise = ref(false);
const savingWorkout = ref(false);
const exerciseOptions = ref<ExerciseOption[]>([]);
const selectedExerciseValues = ref<string[]>([]);

const exerciseForm = ref({
  name: '',
  description: '',
  category: 'Cardio'
});

const workoutForm = ref({
  title: '',
  description: '',
  category: 'Cardio',
  duration: 30,
  calories: 250,
  difficulty: 'Medium' as Difficulty,
  xp: 300
});

const showMessage = (message: string, type: 'success' | 'error') => {
  statusMessage.value = message;
  statusType.value = type;
  window.setTimeout(() => {
    statusMessage.value = '';
  }, 3500);
};

const normalizeCategory = (value: unknown): string => {
  const lowered = String(value ?? '').toLowerCase();
  if (lowered === 'arms') return 'Arms';
  if (lowered === 'upperbody' || lowered === 'upper body' || lowered === 'upper_body') return 'UpperBody';
  if (lowered === 'lowerbody' || lowered === 'lower body' || lowered === 'lower_body') return 'LowerBody';
  if (lowered === 'fullbody' || lowered === 'full body' || lowered === 'full_body') return 'FullBody';
  if (lowered === 'cardio') return 'Cardio';
  if (lowered === 'core') return 'Core';
  return 'Cardio';
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

const toExerciseOption = (rawEntry: unknown, index: number): ExerciseOption => {
  const raw = (rawEntry ?? {}) as Record<string, unknown>;
  const idRaw = raw.id ?? raw.Id;
  const id = Number.isFinite(Number(idRaw)) ? Number(idRaw) : null;
  const name = String(raw.name ?? raw.Name ?? raw.title ?? raw.Title ?? `Uebung ${index + 1}`);

  return {
    value: id !== null ? `id:${id}` : `name:${name}:${index}`,
    id,
    name
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

const loadExercises = async () => {
  loadingExercises.value = true;
  try {
    const response = await workoutService.getExercises(workoutForm.value.category);
    const list = extractList(response.data).map((entry, index) => toExerciseOption(entry, index));
    exerciseOptions.value = list;

    const validValues = new Set(list.map((entry) => entry.value));
    selectedExerciseValues.value = selectedExerciseValues.value.filter((entry) => validValues.has(entry));
  } catch (error) {
    console.error('Fehler beim Laden der Übungen:', error);
    exerciseOptions.value = [];
    selectedExerciseValues.value = [];
    showMessage('Übungen konnten nicht geladen werden.', 'error');
  } finally {
    loadingExercises.value = false;
  }
};

const resetExerciseForm = () => {
  exerciseForm.value = {
    name: '',
    description: '',
    category: exerciseForm.value.category
  };
};

const resetWorkoutForm = () => {
  workoutForm.value = {
    title: '',
    description: '',
    category: workoutForm.value.category,
    duration: 30,
    calories: 250,
    difficulty: 'Medium',
    xp: 300
  };
  selectedExerciseValues.value = [];
};

const submitExercise = async () => {
  if (!exerciseForm.value.name) {
    showMessage('Bitte gib einen Übungsnamen ein.', 'error');
    return;
  }

  savingExercise.value = true;

  try {
    await adminService.createExercise({
      name: exerciseForm.value.name,
      description: exerciseForm.value.description || undefined,
      category: categoryToEnumValue(exerciseForm.value.category)
    });

    resetExerciseForm();
    await loadExercises();
    showMessage('Übung erfolgreich erstellt.', 'success');
  } catch (error: unknown) {
    console.error('Fehler beim Erstellen der Übung:', error);
    showMessage(extractApiErrorMessage(error, 'Übung konnte nicht erstellt werden.'), 'error');
  } finally {
    savingExercise.value = false;
  }
};

const submitWorkout = async () => {
  if (!workoutForm.value.title) {
    showMessage('Bitte gib einen Workout-Namen ein.', 'error');
    return;
  }

  if (selectedExerciseValues.value.length === 0) {
    showMessage('Bitte wähle mindestens eine Übung aus.', 'error');
    return;
  }

  if (selectedExerciseIds.value.length !== selectedExerciseValues.value.length) {
    showMessage('Mindestens eine ausgewählte Übung hat keine gültige ID.', 'error');
    return;
  }

  savingWorkout.value = true;

  try {
    await workoutService.createWorkout({
      name: workoutForm.value.title,
      description: workoutForm.value.description || undefined,
      category: categoryToEnumValue(workoutForm.value.category),
      exercises: selectedExerciseIds.value.map((exerciseId) => ({
        exerciseId,
        dailyLimit: 1
      }))
    });

    resetWorkoutForm();
    showMessage('Workout erfolgreich erstellt.', 'success');
  } catch (error: unknown) {
    console.error('Fehler beim Erstellen des Workouts:', error);
    showMessage(extractApiErrorMessage(error, 'Workout konnte nicht erstellt werden.'), 'error');
  } finally {
    savingWorkout.value = false;
  }
};

watch(
  () => workoutForm.value.category,
  async () => {
    await loadExercises();
  }
);

onMounted(async () => {
  await loadExercises();
});
</script>

<style scoped>
.section-header {
  margin-bottom: 24px;
}

.section-header h2 {
  margin: 0 0 4px;
  color: #333;
}

.section-subtitle {
  margin: 0;
  color: #666;
}

.panel-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 20px;
}

.form-container {
  background: #f8f9fa;
  border: 2px solid #e0e0e0;
  border-radius: 10px;
  padding: 20px;
}

.form-container h3 {
  margin-top: 0;
  color: #333;
}

.form-group {
  margin-bottom: 16px;
}

.form-group label {
  display: block;
  margin-bottom: 6px;
  color: #333;
  font-weight: 600;
}

.form-group input,
.form-group textarea,
.form-group select {
  width: 100%;
  padding: 10px;
  border: 1px solid #d0d0d0;
  border-radius: 8px;
  font-family: inherit;
  font-size: 1rem;
}

.form-group textarea {
  min-height: 90px;
  resize: vertical;
}

.form-row {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
  gap: 12px;
}

.form-actions {
  margin-top: 20px;
}

.btn-primary {
  padding: 10px 18px;
  border: none;
  border-radius: 8px;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  color: white;
  font-weight: 600;
  cursor: pointer;
}

.btn-primary:disabled {
  cursor: not-allowed;
  opacity: 0.7;
}

.exercise-picker {
  border: 1px solid #d9d9d9;
  background: white;
  border-radius: 8px;
  padding: 12px;
}

.exercise-picker-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 10px;
}

.exercise-grid {
  max-height: 230px;
  overflow: auto;
  display: grid;
  gap: 8px;
}

.exercise-option {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 0.95rem;
}

.mini-note {
  margin: 0;
  color: #777;
  font-size: 0.9rem;
}

.status-inline {
  margin-top: 20px;
  padding: 12px 14px;
  border-radius: 8px;
  font-weight: 600;
}

.status-inline.success {
  background: #e8f5e9;
  color: #1b5e20;
}

.status-inline.error {
  background: #ffebee;
  color: #b71c1c;
}

@media (max-width: 768px) {
  .panel-grid {
    grid-template-columns: 1fr;
  }
}
</style>