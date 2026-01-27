<template>
  <!-- Navigation -->
  <nav class="navbar">
    <button class="nav-item active">
      <span class="nav-icon">🎯</span>
      <span>Dashboard</span>
    </button>
    <button class="nav-item">
      <span class="nav-icon">🏋️</span>
      <span>Workouts</span>
    </button>
    <button class="nav-item">
      <span class="nav-icon">🏆</span>
      <span>Quests</span>
    </button>
    <button class="nav-item">
      <span class="nav-icon">👤</span>
      <span>Avatar</span>
    </button>
    <button class="nav-item">
      <span class="nav-icon">🛒</span>
      <span>Shop</span>
    </button>
    <button class="nav-item">
      <span class="nav-icon">👥</span>
      <span>Leaderboard</span>
    </button>
    <button class="nav-item">
      <span class="nav-icon">⚡</span>
      <span>Profile</span>
    </button>
  </nav>
</template>

<script setup lang="ts">
</script>

<style scoped>
/* Navigation */
.navbar {
  display: flex;
  justify-content: center ;
  gap: 8px;
  padding: 0px 40px;
  height: 60px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  position: sticky;
  top: 0;
  z-index: 1000;
  background: linear-gradient(
      180deg,
      #0f173d 0%,
      #0a112d 100%
  );
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
.header-navbar{
  position: fixed;
  top: 0;
  z-index: 1030; /* to prevent the navbar getting covered up by other content */
}

.nav-item:focus:not(:focus-visible) {
  outline: none;
}


</style>