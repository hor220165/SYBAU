<template>
  <!-- Header -->
  <Header></Header>

  <!-- Navigation -->
  <Navbar></Navbar>

  <!-- Main Content -->
  <main class="workouts-content">
    <!-- Stats Header -->
    <div class="stats-header">
      <div class="stats-header-content">
        <h1 class="page-title">Deine Übungen</h1>
        <p class="page-subtitle">Wähle eine Übung und trage deine Wiederholungen ein!</p>

        <div class="stats-grid">
          <div class="stat-card">
            <span class="stat-label">Heute</span>
            <span class="stat-value">{{ todayReps }} Wiederholungen</span>
          </div>
          <div class="stat-card">
            <span class="stat-label">Diese Woche</span>
            <span class="stat-value">1,832 Wiederholungen</span>
          </div>
          <div class="stat-card">
            <span class="stat-label">XP Heute</span>
            <span class="stat-value">+{{ todayXp }} XP</span>
          </div>
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
            <span>💪 {{ wo.exercises?.length ?? 0 }} Übungen</span>
            <span class="expand-icon">{{ expandedWorkout === wo.id ? '▲' : '▼' }}</span>
          </div>
          <div v-if="expandedWorkout === wo.id" class="workout-exercises-list">
            <div v-for="ex in wo.exercises" :key="ex.exerciseId" class="workout-exercise-item">
              <span class="exercise-name-label">{{ ex.exerciseName }}</span>
              <span class="exercise-meta-label">{{ mapDifficulty(ex.difficulty) }} · Limit: {{ ex.dailyLimit }}</span>
            </div>
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
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import Header from '@/components/Header.vue';
import Navbar from '@/components/Navbar.vue';
import WorkoutCard from '@/components/WorkoutCard.vue';
import ExerciseModal from '@/components/WorkoutPopup.vue';
import FooterComponent from '@/components/FooterComponent.vue';
import { workoutService } from '@/services/api';
import { useAuth } from '@/composables/useAuth';

const { refreshProfile } = useAuth();

const activeFilter = ref('Alle');
const showModal = ref(false);
const selectedExercise = ref<any>(null);
const loading = ref(true);

const filters = ['Alle', 'Cardio', 'Strength', 'Core', 'Flexibility'];

// Kategorie → Icon Mapping
const categoryIcons: Record<string, string> = {
  Strength: '💪',
  Core: '🔥',
  Cardio: '⚡',
  Flexibility: '🧘'
};

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
const expandedWorkout = ref<number | null>(null);
const newWorkout = ref({
  name: '',
  description: '',
  category: '' as number | '',
  exercises: [{ exerciseId: 0, dailyLimit: 50 }] as { exerciseId: number; dailyLimit: number }[]
});

onMounted(async () => {
  await loadExercises();
  await loadWorkouts();
});

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
        icon: categoryIcons[cat] ?? '🏋️',
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
    alert('Bitte mindestens eine Übung hinzufügen');
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
    alert(err.response?.data || 'Fehler beim Erstellen des Workouts');
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
    alert(msg);

    // Header aktualisieren (Level, XP, Coins)
    await refreshProfile();
  } catch (err: any) {
    const errorMsg = err.response?.data || 'Fehler beim Eintragen';
    alert(errorMsg);
  }
};
</script>

<style scoped>
.workouts-content {
  padding: 40px;
  max-width: 1400px;
  margin: 0 auto;
}

/* Stats Header - Mehr Farbe */
.stats-header {
  position: relative;
  background: linear-gradient(135deg, 
    rgba(236, 72, 153, 0.25) 0%, 
    rgba(168, 85, 247, 0.2) 50%, 
    rgba(59, 130, 246, 0.15) 100%
  );
  border: 2px solid rgba(236, 72, 153, 0.5);
  border-radius: 24px;
  padding: 40px;
  margin-bottom: 40px;
  overflow: hidden;
  backdrop-filter: blur(20px);
  box-shadow: 
    0 0 40px rgba(236, 72, 153, 0.3),
    0 8px 32px rgba(0, 0, 0, 0.3);
}

/* Animated Gradient Overlay */
.stats-header::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: linear-gradient(135deg, 
    rgba(236, 72, 153, 0.3) 0%, 
    rgba(168, 85, 247, 0.25) 50%, 
    rgba(59, 130, 246, 0.2) 100%
  );
  opacity: 0.6;
  pointer-events: none;
  z-index: 0;
  animation: pulse 8s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% { opacity: 0.6; }
  50% { opacity: 0.8; }
}

.stats-header-content {
  position: relative;
  z-index: 1;
}

.page-title {
  font-size: 36px;
  font-weight: 700;
  margin: 0 0 8px 0;
  color: white;
  text-shadow: 0 2px 20px rgba(236, 72, 153, 0.6);
}

.page-subtitle {
  font-size: 16px;
  margin: 0 0 32px 0;
  color: rgba(255, 255, 255, 0.9);
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 20px;
}

/* Stat Cards - Bessere Sichtbarkeit, kein Hover */
.stat-card {
  background: rgba(15, 23, 42, 0.7);
  backdrop-filter: blur(10px);
  border: 2px solid rgba(236, 72, 153, 0.5);
  border-radius: 16px;
  padding: 20px;
  display: flex;
  align-items: center;
  gap: 16px;
  box-shadow: 
    0 4px 16px rgba(0, 0, 0, 0.3),
    0 0 20px rgba(236, 72, 153, 0.2);
}

.stat-icon {
  width: 48px;
  height: 48px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, rgba(236, 72, 153, 0.3), rgba(168, 85, 247, 0.3));
  border-radius: 12px;
  color: #ec4899;
  border: 1px solid rgba(236, 72, 153, 0.4);
}

.stat-info {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.stat-label {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.7);
  font-weight: 500;
}

.stat-value {
  font-size: 20px;
  font-weight: 700;
  color: white;
  text-shadow: 0 2px 10px rgba(236, 72, 153, 0.5);
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

  .stats-header {
    padding: 32px;
  }

  .page-title {
    font-size: 32px;
  }

  .stats-grid {
    grid-template-columns: repeat(3, 1fr);
    gap: 16px;
  }

  .stat-card {
    padding: 16px;
  }

  .stat-icon {
    width: 44px;
    height: 44px;
  }

  .stat-value {
    font-size: 18px;
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

  .stats-header {
    padding: 24px;
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

  .stat-card {
    padding: 16px;
  }

  .stat-icon {
    width: 40px;
    height: 40px;
  }

  .stat-label {
    font-size: 12px;
  }

  .stat-value {
    font-size: 16px;
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

  .stats-header {
    padding: 20px;
    border-radius: 20px;
  }

  .page-title {
    font-size: 24px;
  }

  .page-subtitle {
    font-size: 13px;
    margin-bottom: 24px;
  }

  .stat-card {
    padding: 14px;
  }

  .stat-icon {
    width: 36px;
    height: 36px;
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
</style>