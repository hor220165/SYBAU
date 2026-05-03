<template>
  <button class="mobile-menu-btn" :class="{ 'below-header': headerVisible }" @click="mobileMenuOpen = !mobileMenuOpen">
    <span class="hamburger-icon">☰</span>
  </button>

  <nav class="navbar" :class="{ 'mobile-open': mobileMenuOpen }">
    <button class="nav-item" :class="{ active: isActiveRoute('/dashboard') }" @click="navigateAndClose('/dashboard')">
      <LayoutDashboard class="nav-icon" :size="20" />
      <span>Dashboard</span>
    </button>
    <button class="nav-item" :class="{ active: isActiveRoute('/workouts') }" @click="navigateAndClose('/workouts')">
      <Dumbbell class="nav-icon" :size="20" />
      <span>Workouts</span>
    </button>
    <button class="nav-item" :class="{ active: isActiveRoute('/quests') }" @click="navigateAndClose('/quests')">
      <Flag class="nav-icon" :size="20" />
      <span>Quests</span>
    </button>
    <button class="nav-item" :class="{ active: isActiveRoute('/avatar') }" @click="navigateAndClose('/avatar')">
      <Accessibility class="nav-icon" :size="20" />
      <span>Avatar</span>
    </button>
    <button class="nav-item" :class="{ active: isActiveRoute('/shop') }" @click="navigateAndClose('/shop')">
      <Store class="nav-icon" :size="20" />
      <span>Shop</span>
    </button>
    <button class="nav-item" :class="{ active: isActiveRoute('/friends') }" @click="navigateAndClose('/friends')">
      <Users class="nav-icon" :size="20" />
      <span>Friends</span>
    </button>
    <button class="nav-item" :class="{ active: isActiveRoute('/leaderboard') }"
      @click="navigateAndClose('/leaderboard')">
      <Trophy class="nav-icon" :size="20" />
      <span>Leaderboard</span>
    </button>
    <button class="nav-item" :class="{ active: isActiveRoute('/profile') }" @click="navigateAndClose('/profile')">
      <User class="nav-icon" :size="20" />
      <span>Profile</span>
    </button>
    <button v-if="isAdmin" class="nav-item admin-btn" :class="{ active: isActiveRoute('/admin') }"
      @click="navigateAndClose('/admin')">
      <ShieldCheck class="nav-icon" :size="20" />
      <span>Admin</span>
    </button>
  </nav>
</template>

<script setup lang="ts">
import { useNavigation } from "@/composables/useNavigation.ts";
import { ref, onMounted } from 'vue';
import {
  Accessibility,
  Dumbbell,
  Flag,
  LayoutDashboard,
  ShieldCheck,
  Store,
  Trophy,
  User,
  Users,
} from 'lucide-vue-next';

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
      ([entry]) => {
        if (entry) {
          headerVisible.value = entry.isIntersecting;
        }
      },
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
  flex: 0 0 auto;
  stroke-width: 2.4;
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
    display: none;
  }

  .navbar {
    position: sticky;
    top: 0;
    right: auto;
    width: 100%;
    height: 60px;
    flex-direction: row;
    justify-content: flex-start;
    gap: 8px;
    padding: 0 16px;
    overflow-x: auto;
    overflow-y: hidden;
    background: rgba(5, 7, 20, 0.72);
    backdrop-filter: blur(20px);
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    border-left: none;
    transition: none;
    z-index: 1000;
    scrollbar-width: none;
    -webkit-overflow-scrolling: touch;
  }

  .nav-item {
    width: auto;
    height: 100%;
    flex: 0 0 auto;
    padding: 0 18px;
    justify-content: center;
    border-radius: 0;
    white-space: nowrap;
  }

  .nav-item.active::after {
    width: auto;
    height: 2px;
    left: 0;
    right: 0;
    top: auto;
    bottom: 0;
  }

  .admin-btn {
    border-left: 1px solid rgba(255, 255, 255, 0.2);
    border-top: none;
    margin-top: 0;
  }
}

@media (max-width: 1024px) {
  .navbar::-webkit-scrollbar {
    display: none;
  }
}
</style>
