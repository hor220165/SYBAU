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
          <span class="stat-value">12 Workouts</span>
        </div>
        <div class="stat-card">
          <span class="stat-label">Trainingszeit</span>
          <span class="stat-value">6.5 Stunden</span>
        </div>
        <div class="stat-card">
          <span class="stat-label">Kalorien</span>
          <span class="stat-value">3,240 kcal</span>
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
    </div> <!-- ← DAS HAT GEFEHLT! -->

    <!-- Create Custom Workout Card -->
    <div class="custom-workout-card">
      <div class="custom-content">
        <h3>Erstelle dein eigenes Workout</h3>
        <p>Kombiniere Übungen und verdiene Bonus-XP</p>
      </div>
      <button class="create-btn">
        Workout erstellen
        <span class="icon">→</span>
      </button>
    </div>
  </main>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import Header from '@/components/Header.vue';
import Navbar from '@/components/Navbar.vue';
import WorkoutCard from '@/components/WorkoutCard.vue';

const activeFilter = ref('Alle');

const filters = ['Alle', 'Cardio', 'Kraft', 'Yoga', 'Core'];

// Dummy Data - später vom Backend holen
const workouts = ref([
  {
    id: 1,
    category: 'Cardio',
    title: 'Morning Warrior HIIT',
    duration: 25,
    calories: 280,
    exercises: ['Burpees', 'Mountain Climbers', 'Jump Squats', 'High Knees'],
    difficulty: 'Hard' as const,
    xp: 350,
    completed: false
  },
  {
    id: 2,
    category: 'Strength',
    title: 'Strength Champion',
    duration: 45,
    calories: 320,
    exercises: ['Deadlifts', 'Bench Press', 'Squats', 'Pull-ups'],
    difficulty: 'Hard' as const,
    xp: 450,
    completed: true
  },
  {
    id: 3,
    category: 'Yoga',
    title: 'Flexibility Flow',
    duration: 30,
    calories: 150,
    exercises: ['Sun Salutation', 'Warrior Poses', 'Downward Dog', 'Tree Pose'],
    difficulty: 'Easy' as const,
    xp: 200,
    completed: false
  },
  {
    id: 4,
    category: 'Core',
    title: 'Core Crusher',
    duration: 20,
    calories: 180,
    exercises: ['Planks', 'Russian Twists', 'Leg Raises', 'Mountain Climbers'],
    difficulty: 'Medium' as const,
    xp: 250,
    completed: false
  },
  {
    id: 5,
    category: 'Cardio',
    title: 'Endurance Run',
    duration: 40,
    calories: 450,
    exercises: ['Steady Pace Run', 'Intervals', 'Cool Down'],
    difficulty: 'Medium' as const,
    xp: 400,
    completed: true
  },
  {
    id: 6,
    category: 'Strength',
    title: 'Power Athlete',
    duration: 35,
    calories: 300,
    exercises: ['Clean & Jerk', 'Overhead Press', 'Box Jumps', 'Kettlebell Swings'],
    difficulty: 'Hard' as const,
    xp: 380,
    completed: false
  }
]);

const filteredWorkouts = computed(() => {
  if (activeFilter.value === 'Alle') {
    return workouts.value;
  }
  
  // Map "Kraft" to "Strength"
  const filterMap: Record<string, string> = {
    'Kraft': 'Strength',
    'Cardio': 'Cardio',
    'Yoga': 'Yoga',
    'Core': 'Core'
  };
  
  const mappedFilter = filterMap[activeFilter.value] || activeFilter.value;
  
  return workouts.value.filter(w => w.category === mappedFilter);
});

const startWorkout = (id: number) => {
  console.log('Starting workout:', id);
  // TODO: Navigate to workout detail or start workout
};

const viewWorkout = (id: number) => {
  console.log('Viewing workout:', id);
  // TODO: Show workout details
};
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