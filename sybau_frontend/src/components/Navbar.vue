<template>
  <!-- Navigation -->
  <nav class="navbar">
    <button class="nav-item"
            :class="{ active: isActiveRoute('/home') }"
            @click="navigateTo('/home')">
      <span class="nav-icon">🎯</span>
      <span>Dashboard</span>
    </button>
    <button class="nav-item"
            :class="{ active: isActiveRoute('/workouts') }"
            @click="navigateTo('/workouts')">
      <span class="nav-icon">🏋️</span>
      <span>Workouts</span>
    </button>
    <button class="nav-item"
            :class="{ active: isActiveRoute('/quests') }"
            @click="navigateTo('/quests')">
      <span class="nav-icon">🏆</span>
      <span>Quests</span>
    </button>
    <button class="nav-item"
            :class="{ active: isActiveRoute('/avatar') }"
            @click="navigateTo('/avatar')">
      <span class="nav-icon">👤</span>
      <span>Avatar</span>
    </button>
    <button class="nav-item"
            :class="{ active: isActiveRoute('/shop') }"
            @click="navigateTo('/shop')">
      <span class="nav-icon">🛒</span>
      <span>Shop</span>
    </button>
    <button class="nav-item"
            :class="{ active: isActiveRoute('/leaderboard') }"
            @click="navigateTo('/leaderboard')">
      <span class="nav-icon">👥</span>
      <span>Leaderboard</span>
    </button>
    <button class="nav-item"
            :class="{ active: isActiveRoute('/profile') }"
            @click="navigateTo('/profile')">
      <span class="nav-icon">⚡</span>
      <span>Profile</span>
    </button>
  </nav>
</template>

<script setup lang="ts">
import {useNavigation} from "@/composables/useNavigation.ts";

const {navigateTo, isActiveRoute} = useNavigation()
</script>
<style scoped>
/* Navigation */
.navbar {
  display: flex;
  justify-content: center;
  gap: 8px;
  padding: 0px 40px;
  height: 60px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  position: sticky;
  top: 0;
  z-index: 1000;
  background: transparent;
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
}

.nav-item {
  height: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0px 24px;
  background: transparent;
  border: none;
  border-radius: 0px;
  color: rgba(255, 255, 255, 0.7);
  cursor: pointer;
  font-size: 16px;
  font-weight: 500;
  transition: all 0.3s ease;
  position: relative;
}

.nav-item:hover {
  background: rgba(255, 255, 255, 0.05);
  color: white;
}

.nav-item.active {
  color: white;
}

.nav-item.active::after {
  content: '';
  position: absolute;
  bottom: 0px;
  left: 0;
  right: 0;
  height: 2px;
  background: linear-gradient(90deg, #ec4899, #f43f5e);
}

.nav-item:after {
  transition: opacity 0.3s ease, transform 0.3 ease;
}

.nav-icon {
  font-size: 20px;
}

.nav-item:focus:not(:focus-visible) {
  outline: none;
}
</style>