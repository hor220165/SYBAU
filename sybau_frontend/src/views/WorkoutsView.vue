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
            <div class="stat-icon">
              <Flame :size="28" />
            </div>
            <div class="stat-info">
              <span class="stat-label">Heute</span>
              <span class="stat-value">245 Reps</span>
            </div>
          </div>
          <div class="stat-card">
            <div class="stat-icon">
              <TrendingUp :size="28" />
            </div>
            <div class="stat-info">
              <span class="stat-label">Diese Woche</span>
              <span class="stat-value">1,832 Reps</span>
            </div>
          </div>
          <div class="stat-card">
            <div class="stat-icon">
              <Zap :size="28" />
            </div>
            <div class="stat-info">
              <span class="stat-label">XP Heute</span>
              <span class="stat-value">+490 XP</span>
            </div>
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
import { ref, computed } from 'vue';
import { Flame, TrendingUp, Zap } from 'lucide-vue-next';
import Header from '@/components/Header.vue';
import Navbar from '@/components/Navbar.vue';
import WorkoutCard from '@/components/WorkoutCard.vue';
import ExerciseModal from '@/components/WorkoutPopup.vue';
import FooterComponent from '@/components/FooterComponent.vue';

const activeFilter = ref('Alle');
const showModal = ref(false);
const selectedExercise = ref<any>(null);

const filters = ['Alle', 'Cardio', 'Strength', 'Core', 'Flexibility'];

// Dummy Data - Einzelne Übungen
const exercises = ref([
  {
    id: 1,
    name: 'Push-Ups',
    description: 'Klassische Liegestütze',
    category: 'Strength',
    icon: '💪',
    xpPerRep: 2,
    dailyLimit: 200,
    todayCount: 45,
    difficulty: 'Medium' as const
  },
  {
    id: 2,
    name: 'Sit-Ups',
    description: 'Bauchmuskeltraining',
    category: 'Core',
    icon: '🔥',
    xpPerRep: 1,
    dailyLimit: 300,
    todayCount: 80,
    difficulty: 'Easy' as const
  },
  {
    id: 3,
    name: 'Squats',
    description: 'Kniebeugen',
    category: 'Strength',
    icon: '🦵',
    xpPerRep: 2,
    dailyLimit: 200,
    todayCount: 60,
    difficulty: 'Medium' as const
  },
  {
    id: 4,
    name: 'Burpees',
    description: 'Ganzkörper-Übung',
    category: 'Cardio',
    icon: '⚡',
    xpPerRep: 5,
    dailyLimit: 100,
    todayCount: 20,
    difficulty: 'Hard' as const
  },
  {
    id: 5,
    name: 'Plank',
    description: 'Unterarmstütz (in Sekunden)',
    category: 'Core',
    icon: '🧘',
    xpPerRep: 0.5,
    dailyLimit: 600,
    todayCount: 120,
    difficulty: 'Medium' as const
  },
  {
    id: 6,
    name: 'Pull-Ups',
    description: 'Klimmzüge',
    category: 'Strength',
    icon: '🏋️',
    xpPerRep: 5,
    dailyLimit: 50,
    todayCount: 15,
    difficulty: 'Hard' as const
  },
  {
    id: 7,
    name: 'Jumping Jacks',
    description: 'Hampelmänner',
    category: 'Cardio',
    icon: '🤸',
    xpPerRep: 1,
    dailyLimit: 500,
    todayCount: 100,
    difficulty: 'Easy' as const
  },
  {
    id: 8,
    name: 'Lunges',
    description: 'Ausfallschritte',
    category: 'Strength',
    icon: '🚶',
    xpPerRep: 2,
    dailyLimit: 150,
    todayCount: 40,
    difficulty: 'Medium' as const
  },
  {
    id: 9,
    name: 'Mountain Climbers',
    description: 'Bergsteiger',
    category: 'Cardio',
    icon: '⛰️',
    xpPerRep: 1,
    dailyLimit: 400,
    todayCount: 150,
    difficulty: 'Medium' as const
  },
  {
    id: 10,
    name: 'Leg Raises',
    description: 'Beinheben',
    category: 'Core',
    icon: '🦿',
    xpPerRep: 2,
    dailyLimit: 200,
    todayCount: 30,
    difficulty: 'Medium' as const
  }
]);

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
  
  // Update todayCount
  const exercise = exercises.value.find(e => e.name === data.exercise);
  if (exercise) {
    exercise.todayCount += data.reps;
  }
  
  // TODO: Send to backend
  alert(`${data.exercise}: ${data.reps} Wiederholungen eingetragen! +${data.xp} XP gewonnen!`);
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
</style>