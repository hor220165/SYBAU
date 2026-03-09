<script setup lang="ts">

import { onMounted } from 'vue';
import Navbar from "@/components/Navbar.vue";
import Header from "@/components/Header.vue";
import { useLeaderboard } from '@/composables/useLeaderboard';

const { sortedLeaderboard, loading, error, loadLeaderboard } = useLeaderboard();

onMounted(loadLeaderboard);
</script>

<template>
  <div class="dashboard-container">
    <!-- Header -->
    <Header></Header>

    <!-- Navigation -->
    <Navbar></Navbar>

    <main class="main-content">
      <h1>Leaderboard</h1>

      <div v-if="loading">Lade Leaderboard…</div>
      <div v-else-if="error" class="error">
        {{ error }}
        <button class="btn-retry" @click="loadLeaderboard">Erneut versuchen</button>
      </div>

      <ul v-else class="leaderboard-list">
        <li v-for="u in sortedLeaderboard" :key="u.Id" class="leaderboard-item">
          <span class="rank">{{ u.Rank }}.</span>
          <span class="username">{{ u.UserName }}</span>
          <span class="xp">{{ u.Experience }} XP</span>
          <span class="level">Level {{ u.Level }}</span>
        </li>
      </ul>
    </main>
  </div>
</template>

<style scoped>
.dashboard-container {
  min-height: 100vh;
  color: white;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

.main-content {
  padding: 40px;
  max-width: 1200px;
  margin: 0 auto;
}

.leaderboard-list {
  list-style: none;
  padding: 0;
  margin: 16px 0 0 0;
  display: grid;
  gap: 12px;
}

.leaderboard-item {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 14px 18px;
  border-radius: 12px;
  background: rgba(15, 23, 42, 0.5);
  border: 1px solid rgba(59, 130, 246, 0.08);
  box-shadow: 0 8px 30px rgba(2, 6, 23, 0.5);
}

.rank {
  width: 48px;
  text-align: center;
  font-weight: 700;
  color: #fef3c7;
}

.username {
  font-weight: 600;
  color: #ffffff;
  flex: 1;
}

.xp {
  color: #93c5fd;
  font-size: 14px;
}

.level {
  color: #60a5fa;
  font-size: 14px;
}

.btn-retry {
  margin-left: 12px;
  padding: 6px 10px;
  background: linear-gradient(90deg,#3b82f6,#06b6d4);
  border: none;
  color: white;
  border-radius: 8px;
  cursor: pointer;
}

@media (max-width: 768px) {
  .main-content {
    padding: 20px;
  }
  .leaderboard-item {
    padding: 12px;
    gap: 8px;
  }
}
</style>