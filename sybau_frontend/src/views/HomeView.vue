<template>
  <div class="dashboard-container">
    <!-- Header -->
    <Header></Header>

    <!-- Navigation -->
    <Navbar></Navbar>

    <!-- Main Content -->
    <main class="main-content">
      <!-- Avatar Section -->
      <div class="avatar-section">
        <div class="avatar-display">
          <SpriteAnimator
              :frameWidth="128"
              :frameHeight="128"
              :columns="2"
              :rows="2"
              :frameCount="4"
              :speed="1000"
              :scale="3"
          />
        </div>

        <!-- XP Progress -->
        <div class="xp-progress">
          <div class="progress-header">
            <span>Level 12 Progress</span>
            <span>650 / 1000 XP</span>
          </div>
          <div class="progress-bar">
            <div class="progress-fill" style="width: 65%"></div>
          </div>
          <p class="progress-text">350 XP bis Level 13</p>
        </div>
      </div>

      <!-- StatCards -->
      <div class="stats-grid">
        <StatCard
            icon="🔥"
            label="Streak"
            value="5 Tage"
            trend="+2"
            cardClass="streak-card"
        />
        <StatCard
            icon="🏆"
            label="Achievements"
            value="24/50"
            trend="+3 diese Woche"
            cardClass="achievements-card"
        />
        <StatCard
            icon="🎯"
            label="Quests"
            value="3/5"
            trend="2 aktiv"
            cardClass="quests-card"
        />
        <StatCard
            icon="📈"
            label="Gesamt XP"
            value="12,450"
            trend="+450 heute"
            cardClass="xp-card"
        />
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import SpriteAnimator from "../components/spriteAnimator.vue";
import StatCard from "../components/StatCard.vue";
import Navbar from "@/components/Navbar.vue";
import Header from "@/components/Header.vue";

</script>

<style scoped>
/* Base Styles */
.dashboard-container {
  min-height: 100vh;
  color: white;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

/* Main Content */
.main-content {
  padding: 40px;
  max-width: 1400px;
  margin: 0 auto;
}

/* Avatar Section */
.avatar-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 40px;
  gap: 24px;
}

.avatar-display {
  position: relative;
  border: 2px solid rgba(236, 72, 153, 0.3);
  border-radius: 20px;
  padding: 24px;
  box-shadow: 0 0 40px rgba(236, 72, 153, 0.2);
  display: inline-block;
}

/* XP Progress */
.xp-progress {
  width: 100%;
  max-width: 500px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.progress-header {
  display: flex;
  justify-content: space-between;
  font-size: 14px;
  color: #93c5fd;
}

.progress-bar {
  height: 12px;
  background: rgba(30, 41, 59, 0.5);
  border-radius: 999px;
  overflow: hidden;
  border: 1px solid rgba(59, 130, 246, 0.2);
  position: relative;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #3b82f6, #06b6d4);
  border-radius: 999px;
  transition: width 0.3s ease;
  box-shadow: 0 0 20px rgba(59, 130, 246, 0.5);
}

.progress-text {
  font-size: 12px;
  color: #60a5fa;
  margin: 0;
  text-align: center;
}

/* Stats Grid */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 24px;
}

/* Responsive */
@media (max-width: 768px) {
  .navbar {
    overflow-x: auto;
  }

  .xp-progress {
    max-width: 100%;
  }
}
</style>