<template>
  <button class="mobile-menu-btn"
          :class="{ 'below-header': headerVisible }"
          @click="mobileMenuOpen = !mobileMenuOpen">
    <span class="hamburger-icon">☰</span>
  </button>

  <nav class="navbar" :class="{ 'mobile-open': mobileMenuOpen }">
    <button class="nav-item"
            :class="{ active: isActiveRoute('/dashboard') }"
            @click="navigateAndClose('/dashboard')">
      <span class="nav-icon">🎯</span>
      <span>Dashboard</span>
    </button>
    <button class="nav-item"
            :class="{ active: isActiveRoute('/workouts') }"
            @click="navigateAndClose('/workouts')">
      <span class="nav-icon">🏋️</span>
      <span>Workouts</span>
    </button>
    <button class="nav-item"
            :class="{ active: isActiveRoute('/quests') }"
            @click="navigateAndClose('/quests')">
      <span class="nav-icon">🏆</span>
      <span>Quests</span>
    </button>
    <button class="nav-item"
            :class="{ active: isActiveRoute('/avatar') }"
            @click="navigateAndClose('/avatar')">
      <span class="nav-icon">👤</span>
      <span>Avatar</span>
    </button>
    <button class="nav-item"
            :class="{ active: isActiveRoute('/shop') }"
            @click="navigateAndClose('/shop')">
      <span class="nav-icon">🛒</span>
      <span>Shop</span>
    </button>
    <button class="nav-item"
            :class="{ active: isActiveRoute('/friends') }"
            @click="navigateAndClose('/friends')">
      <span class="nav-icon">🤝</span>
      <span>Friends</span>
    </button>
    <button class="nav-item"
            :class="{ active: isActiveRoute('/leaderboard') }"
            @click="navigateAndClose('/leaderboard')">
      <span class="nav-icon">👥</span>
      <span>Leaderboard</span>
    </button>
    <button class="nav-item"
            :class="{ active: isActiveRoute('/profile') }"
            @click="navigateAndClose('/profile')">
      <span class="nav-icon">⚡</span>
      <span>Profile</span>
    </button>
    <button v-if="isAdmin" class="nav-item admin-btn"
            :class="{ active: isActiveRoute('/admin') }"
            @click="navigateAndClose('/admin')">
      <span class="nav-icon">🔐</span>
      <span>Admin</span>
    </button>
  </nav>
</template>

<script setup lang="ts">
import { useNavigation } from "@/composables/useNavigation.ts";
import { ref, onMounted } from 'vue';

const { navigateTo, isActiveRoute } = useNavigation();
const isAdmin = ref(false);
const mobileMenuOpen = ref(false);
const headerVisible = ref(true);

const navigateAndClose = (path: string) => {
  navigateTo(path);
  mobileMenuOpen.value = false;
};

onMounted(() => {
  const user = localStorage.getItem('user');
  if (user) {
    try {
      const userData = JSON.parse(user);
      isAdmin.value = userData.isAdmin || false;
    } catch (e) {
      isAdmin.value = false;
    }
  }

  const header = document.querySelector('header');
  if (header) {
    const observer = new IntersectionObserver(
      ([entry]) => { headerVisible.value = entry.isIntersecting; },
      { threshold: 0 }
    );
    observer.observe(header);
  }
});
</script>

<style scoped>
.mobile-menu-btn {
  display: none;
  position: fixed;
  top: 16px;
  right: 16px;
  z-index: 2000;
  width: 48px;
  height: 48px;
  border-radius: 12px;
  border: none;
  background: rgba(30, 41, 59, 0.9);
  backdrop-filter: blur(10px);
  color: white;
  font-size: 24px;
  cursor: pointer;
  transition: top 0.3s ease, background 0.3s ease;
}

.mobile-menu-btn.below-header {
  top: 72px;
}

.mobile-menu-btn:hover {
  background: rgba(236, 72, 153, 0.3);
}

.navbar {
  display: flex;
  justify-content: center;
  gap: 8px;
  padding: 0 40px;
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
  padding: 0 24px;
  background: transparent;
  border: none;
  border-radius: 0;
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
  bottom: 0;
  left: 0;
  right: 0;
  height: 2px;
  background: linear-gradient(90deg, #ec4899, #f43f5e);
}

.nav-icon {
  font-size: 20px;
}

.admin-btn {
  border-left: 1px solid rgba(255, 255, 255, 0.2);
  background: rgba(255, 215, 0, 0.05);
}

.admin-btn:hover {
  background: rgba(255, 215, 0, 0.15);
}

.admin-btn.active {
  color: #ffd700;
}

.admin-btn.active::after {
  background: linear-gradient(90deg, #ffd700, #ffed4e);
}

@media (max-width: 1024px) {
  .mobile-menu-btn {
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .navbar {
    position: fixed;
    top: 0;
    right: -100%;
    width: 280px;
    height: 100vh;
    flex-direction: column;
    justify-content: flex-start;
    gap: 0;
    padding: 80px 0 0 0;
    background: rgba(15, 23, 42, 0.98);
    backdrop-filter: blur(20px);
    border-bottom: none;
    border-left: 1px solid rgba(255, 255, 255, 0.1);
    transition: right 0.3s ease;
    z-index: 1500;
  }

  .navbar.mobile-open {
    right: 0;
  }

  .nav-item {
    width: 100%;
    height: 56px;
    padding: 0 24px;
    justify-content: flex-start;
    border-radius: 0;
  }

  .nav-item.active::after {
    width: 4px;
    height: 100%;
    left: 0;
    right: auto;
    top: 0;
    bottom: 0;
  }

  .admin-btn {
    border-left: none;
    border-top: 1px solid rgba(255, 255, 255, 0.2);
    margin-top: auto;
  }
}
</style>