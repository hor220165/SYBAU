<script setup lang="ts">
import { computed, onMounted } from 'vue';
import { useNavigation } from "@/composables/useNavigation.ts";
import { useAuth } from "@/composables/useAuth";
import { userService } from '@/services/api';

const { logout } = useNavigation();
const { user, syncUserFromStorage } = useAuth();

onMounted(async () => {
  syncUserFromStorage();

  if (!user.value?.avatar) {
    try {
      await userService.getProfile();
      syncUserFromStorage();
    } catch (err) {
      console.error('Failed to fetch profile:', err);
    }
  }
});

// Computed properties mit allen möglichen Varianten
const userLevel = computed(() => user.value?.avatar?.level ?? user.value?.Avatar?.level ?? 0);
const userXP = computed(() => user.value?.avatar?.experience ?? user.value?.Avatar?.experience ?? 0);
const userCoins = computed(() => user.value?.coins ?? user.value?.Coins ?? 0);
</script>

<template>
  <!-- Header -->
  <header class="header">
    <div class="logo-section">
      <img src="../assets/Sybau_Logo_White.png" alt="Sybau_Logo" class="logo-img" />
     
    </div>

    <!-- Stats header  -->
    <div class="stats-header">
      <div class="stat-badge level">
        <span>Lvl</span>
        <span>{{ userLevel }}</span>
      </div>
      <div class="stat-badge xp">
        <span class="icon">XP</span>
        <span>{{ userXP }}</span>
      </div>
      <div class="stat-badge coins">
        <span>Coins</span>
        <span>{{ userCoins }}</span>
      </div>
      <button class="menu-btn" @click="logout">
        <span><img src="../assets/logout_Icon.png" alt="logout" width="25px" class="logout-icon"></span>
      </button>
    </div>
  </header>
</template>

<style scoped>
/* Header */
.header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 20px 40px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  background: transparent;
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
}

.logout-icon {
  width: 20px;
  height: 20px;
  filter: invert(68%) sepia(47%) saturate(3445%) hue-rotate(318deg) brightness(101%) contrast(92%);
}

.logo-section {
  display: flex;
  align-items: center;
  gap: 16px;
}

.logo-img {
  height: 35px;
  width: auto;
  object-fit: contain;
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
</style>