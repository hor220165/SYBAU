<template>
  <button
    class="mobile-menu-btn"
    type="button"
    :class="{ 'below-header': headerVisible }"
    aria-label="Navigation öffnen"
    data-tooltip="Navigation"
    @click="mobileMenuOpen = !mobileMenuOpen"
  >
    <span class="hamburger-icon">☰</span>
  </button>

  <nav class="navbar" :class="{ 'mobile-open': mobileMenuOpen }">
    <button class="nav-item" :class="{ active: isActiveRoute('/dashboard') }" @click="navigateAndClose('/dashboard')">
      <LayoutDashboard class="nav-icon" :size="20" />
      <span>Dashboard</span>
    </button>
    <button class="nav-item" :class="{ active: isActiveRoute('/workouts') }" @click="navigateAndClose('/workouts')">
      <Dumbbell class="nav-icon" :size="20" />
      <span>{{ text('Workouts', 'Workouts') }}</span>
    </button>
    <button class="nav-item nav-item-quests" :class="{ active: isActiveRoute('/quests') }" @click="navigateAndClose('/quests')">
      <Flag class="nav-icon" :size="20" />
      <span>{{ text('Quests', 'Quests') }}</span>
      <span v-if="hasClaimableQuest" class="nav-alert-dot" :aria-label="text('Abgeschlossene Quest verfügbar', 'Completed quest available')"></span>
    </button>
    <button class="nav-item" :class="{ active: isActiveRoute('/avatar') }" @click="navigateAndClose('/avatar')">
      <Accessibility class="nav-icon" :size="20" />
      <span>{{ text('Avatar', 'Avatar') }}</span>
    </button>
    <button class="nav-item" :class="{ active: isActiveRoute('/shop') }" @click="navigateAndClose('/shop')">
      <Store class="nav-icon" :size="20" />
      <span>{{ text('Shop', 'Shop') }}</span>
    </button>
    <button class="nav-item" :class="{ active: isActiveRoute('/friends') }" @click="navigateAndClose('/friends')">
      <Users class="nav-icon" :size="20" />
      <span>{{ text('Freunde', 'Friends') }}</span>
    </button>
    <button class="nav-item" :class="{ active: isActiveRoute('/leaderboard') }"
      @click="navigateAndClose('/leaderboard')">
      <Trophy class="nav-icon" :size="20" />
      <span>{{ text('Leaderboard', 'Leaderboard') }}</span>
    </button>
    <button class="nav-item" :class="{ active: isActiveRoute('/profile') }" @click="navigateAndClose('/profile')">
      <User class="nav-icon" :size="20" />
      <span>{{ text('Profil', 'Profile') }}</span>
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
import { ref, onMounted, onUnmounted } from 'vue';
import { questService } from '@/services/api';
import { useLanguage } from '@/composables/useLanguage';
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
const { text } = useLanguage();
const isAdmin = ref(false);
const mobileMenuOpen = ref(false);
const headerVisible = ref(true);
const hasClaimableQuest = ref(false);

type QuestBadgeEventDetail = {
  claimable?: boolean;
};

const navigateAndClose = (path: string) => {
  navigateTo(path);
  mobileMenuOpen.value = false;
};

const isClaimableQuest = (quest: any) => {
  const completed = quest?.isCompleted ?? quest?.IsCompleted;
  const claimed = quest?.isRewardClaimed ?? quest?.IsRewardClaimed;
  return completed === true && claimed !== true;
};

const refreshQuestBadge = async () => {
  if (!localStorage.getItem('token')) {
    hasClaimableQuest.value = false;
    return;
  }

  try {
    const { data } = await questService.getMyQuests();
    hasClaimableQuest.value = Array.isArray(data) && data.some(isClaimableQuest);
  } catch {
    hasClaimableQuest.value = false;
  }
};

const handleQuestBadgeUpdate = (event: Event) => {
  const detail = (event as CustomEvent<QuestBadgeEventDetail>).detail;
  if (typeof detail?.claimable === 'boolean') {
    hasClaimableQuest.value = detail.claimable;
    return;
  }
  void refreshQuestBadge();
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

  void refreshQuestBadge();
  window.addEventListener('sybau:quests-updated', handleQuestBadgeUpdate);
  window.addEventListener('focus', refreshQuestBadge);
});

onUnmounted(() => {
  window.removeEventListener('sybau:quests-updated', handleQuestBadgeUpdate);
  window.removeEventListener('focus', refreshQuestBadge);
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
  box-sizing: border-box;
  display: flex;
  justify-content: center;
  gap: 8px;
  padding: 0 40px;
  height: 60px;
  max-width: 100%;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  position: sticky;
  top: 83px;
  z-index: 2400;
  background: transparent;
  backdrop-filter: blur(18px);
  -webkit-backdrop-filter: blur(18px);
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

.nav-alert-dot {
  position: absolute;
  top: 13px;
  right: 13px;
  width: 9px;
  height: 9px;
  border-radius: 999px;
  background: #ef4444;
  box-shadow:
    0 0 0 2px rgba(5, 10, 18, 0.88),
    0 0 12px rgba(239, 68, 68, 0.9);
  pointer-events: none;
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
    top: 61px;
    right: auto;
    width: 100%;
    height: 60px;
    flex-direction: row;
    justify-content: flex-start;
    gap: 8px;
    padding: 0 16px;
    overflow-x: auto;
    overflow-y: hidden;
    background: transparent;
    backdrop-filter: blur(18px);
    -webkit-backdrop-filter: blur(18px);
    border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    border-left: none;
    transition: none;
    z-index: 2400;
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

@media (max-width: 768px) {
  .navbar {
    top: 53px;
  }
}

@media (max-width: 480px) {
  .navbar {
    top: 43px;
  }
}
</style>
