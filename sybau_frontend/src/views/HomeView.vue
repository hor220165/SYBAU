<template>
  <div class="dashboard-container">
    <!-- Header -->
    <header class="header">
      <div class="logo-section">
        <div class="logo-icon">💪</div>
        <div class="logo-text">
          <h1>SBYAU</h1>
          <p>Shape Your Body And Unleash</p>
        </div>
      </div>

      <!-- Stats header  -->
      <div class="stats-header">
        <div class="stat-badge level">
          <span>Lvl</span>
        </div>
        <div class="stat-badge xp">
          <span class="icon">XP</span>
        </div>
        <div class="stat-badge coins">
          <span>Coins</span>
        </div>
        <button class="menu-btn" @click="handleLogout">
          <span>logout</span>
        </button>
      </div>
    </header>

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
import {useRouter} from "vue-router";

const router = useRouter();

const handleLogout = async () =>{
  router.push('/auth');
}

</script>

<style scoped>
/* Base Styles */
.dashboard-container {
  min-height: 100vh;
  color: white;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

/* Header */
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 40px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  background: linear-gradient(
      180deg,
      #0f173d 0%,
      #0a112d 100%
  );
}

.logo-section {
  display: flex;
  align-items: center;
  gap: 16px;
}

.logo-icon {
  width: 64px;
  height: 64px;
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 32px;
}

.logo-text h1 {
  font-size: 24px;
  font-weight: 700;
  margin: 0;
  color: white;
}

.logo-text p {
  font-size: 14px;
  margin: 0;
  color: rgba(255, 255, 255, 0.7);
}

.stats-header {
  display: flex;
  align-items: center;
  gap: 12px;
}

.stat-badge {
  padding: 12px 20px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 600;
  border: 1px solid rgba(255, 255, 255, 0.2);
  backdrop-filter: blur(10px);
}

.stat-badge.level {
  background: linear-gradient(135deg, rgba(234, 179, 8, 0.2), rgba(202, 138, 4, 0.2));
  border-color: rgba(234, 179, 8, 0.3);
  color: #fbbf24;
}

.stat-badge.xp {
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.2), rgba(37, 99, 235, 0.2));
  border-color: rgba(59, 130, 246, 0.3);
  color: #60a5fa;
}

.stat-badge.coins {
  background: linear-gradient(135deg, rgba(245, 158, 11, 0.2), rgba(217, 119, 6, 0.2));
  border-color: rgba(245, 158, 11, 0.3);
  color: #fbbf24;
}

.menu-btn {
  color: rgba(248, 113, 113, 1);;
  width: 68px;
  height: 48px;
  border-radius: 12px;
  background: rgba(248, 113, 113, 0.2);
  border: 1px solid rgba(248, 113, 113, 0.3);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s ease;
}

.menu-btn:hover {
  background: rgba(248, 113, 113, 0.3);
  transform: translateY(-2px);
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