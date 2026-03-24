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
          <span class="stat-value">167 Wiederholungen</span>
          <!---<span class="stat-value">{{ todayReps }} Wiederholungen</span>-->
        </div>
        <div class="stat-card">
          <span class="stat-label">Diese Woche</span>
          <span class="stat-value">1,832 Wiederholungen</span>
         <!--- <span class="stat-label">Übungen</span>
          <span class="stat-value">{{ exercises.length }} verfügbar</span>--> 
        </div>
        <div class="stat-card">
          <span class="stat-label">XP Heute</span>
          <span class="stat-value">+{{ todayXp }} XP</span>
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
      <button class="create-btn">
        Workout erstellen
      </button>
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
import { ref, computed, onMounted } from 'vue';
import Header from '@/components/Header.vue';
import Navbar from '@/components/Navbar.vue';
import WorkoutCard from '@/components/WorkoutCard.vue';
import ExerciseModal from '@/components/WorkoutPopup.vue';
import FooterComponent from '@/components/FooterComponent.vue';
import { workoutService } from '@/services/api';

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

onMounted(() => loadExercises());

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
        xpPerRep: e.xpPerRep ?? 1,
        dailyLimit: e.dailyLimit ?? 200,
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

const logExercise = (exercise: any) => {
  selectedExercise.value = exercise;
  showModal.value = true;
};

const handleExerciseSubmit = async (data: any) => {
  const exercise = exercises.value.find(e => e.name === data.exercise);
  if (!exercise) return;

  try {
    const res = await workoutService.logExercise(exercise.id, data.reps);
    exercise.todayCount = res.data.todayCount;
    const xpEarned = res.data.xpEarned ?? 0;
    const bonusXp = res.data.bonusXp ?? 0;
    const boostPct = res.data.boostPercent ?? 0;
    let msg = `${data.exercise}: ${data.reps} Wiederholungen eingetragen! +${xpEarned} XP`;
    if (bonusXp > 0) {
      msg += ` (davon +${bonusXp} Bonus durch ${boostPct}% Booster)`;
    }
    alert(msg);
  } catch (e: any) {
    const msg = e.response?.data || 'Fehler beim Eintragen';
    alert(msg);
  }
};
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
</style>