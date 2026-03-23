<script setup lang="ts">
import { computed, onMounted } from 'vue';
import { useNavigation } from "@/composables/useNavigation.ts";
import { useAuth } from "@/composables/useAuth";
import { userService } from '@/services/api';
import { useCoins } from '@/composables/useCoins';

const { logout } = useNavigation();
const { user } = useAuth();
const { formatCoins } = useCoins();

onMounted(async () => {
  if (!user.value?.avatar) {
    try {
      await userService.getProfile();
      user.value = JSON.parse(localStorage.getItem('user') || '{}');
    } catch (err) {
      console.error('Failed to fetch profile:', err);
    }
  }
});

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

    <!-- Stats header -->
    <div class="stats-header">
      <div class="stat-item level">
        <img src="../assets/Star_Pixel.png" alt="Level" class="stat-icon level-icon">
        <div class="stat-info">
          <span class="stat-label">Level</span>
          <span class="stat-value">{{ userLevel }}</span>
        </div>
      </div>

      <div class="stat-divider"></div>

      <div class="stat-item xp">
        <img src="../assets/XP_Pixel.png" alt="XP" class="stat-icon xp-icon">
        <div class="stat-info">
          <span class="stat-label">XP</span>
          <span class="stat-value">{{ userXP }}</span>
        </div>
      </div>

      <div class="stat-divider"></div>

      <div class="stat-item coins">
        <img src="../assets/SYBAU_Coin.png" alt="Coins" class="stat-icon coin-icon">
        <span class="stat-value">{{ formatCoins(userCoins) }}</span>
      </div>

      <button class="logout-btn" @click="logout">
        <img src="../assets/logout_Icon.png" alt="logout" class="logout-icon">
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
  padding: 16px 40px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
  background: transparent;
  backdrop-filter: blur(20px);
  -webkit-backdrop-filter: blur(20px);
}

.logo-section {
  display: flex;
  align-items: center;
}

.logo-img {
  height: 36px;
  width: auto;
  object-fit: contain;
}

/* Stats Header */
.stats-header {
  display: flex;
  align-items: center;
  gap: 20px;
}

.stat-item {
  display: flex;
  align-items: center;
  gap: 10px;
}

/* Gemeinsame Icon Styles */
.stat-icon {
  width: 24px;
  height: 24px;
  object-fit: contain;
  image-rendering: pixelated;
  image-rendering: -moz-crisp-edges;
  image-rendering: crisp-edges;
}

/* Icon-spezifische Glow-Effekte */
.level-icon {
  filter: drop-shadow(0 0 8px rgba(251, 191, 36, 0.6));
}

.xp-icon {
  filter: drop-shadow(0 0 8px rgba(96, 165, 250, 0.6));
}

.coin-icon {
  filter: drop-shadow(0 0 8px rgba(251, 191, 36, 0.6));
}

.stat-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.stat-label {
  font-size: 11px;
  font-weight: 500;
  color: rgba(255, 255, 255, 0.5);
  text-transform: uppercase;
  letter-spacing: 0.5px;
  line-height: 1;
}

.stat-value {
  font-size: 18px;
  font-weight: 700;
  line-height: 1;
}

/* Stat Colors */
.stat-item.level .stat-value {
  color: #fbbf24;
  text-shadow: 0 0 10px rgba(251, 191, 36, 0.5);
}

.stat-item.xp .stat-value {
  color: #60a5fa;
  text-shadow: 0 0 10px rgba(96, 165, 250, 0.5);
}

.stat-item.coins .stat-value {
  color: #fbbf24;
  text-shadow: 0 0 10px rgba(251, 191, 36, 0.5);
}

/* Divider */
.stat-divider {
  width: 1px;
  height: 28px;
  background: rgba(255, 255, 255, 0.1);
}

/* Logout Button */
.logout-btn {
  width: 44px;
  height: 44px;
  border-radius: 12px;
  background: transparent;
  border: none;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: all 0.3s ease;
  margin-left: 8px;
}

.logout-btn:hover {
  transform: translateY(-2px);
}

.logout-icon {
  width: 18px;
  height: 18px;
  filter: invert(68%) sepia(47%) saturate(3445%) hue-rotate(318deg) brightness(101%) contrast(92%)
          drop-shadow(0 0 8px rgba(248, 113, 113, 0.8));
}

.logout-btn:hover .logout-icon {
  filter: invert(68%) sepia(47%) saturate(3445%) hue-rotate(318deg) brightness(101%) contrast(92%)
          drop-shadow(0 0 12px rgba(248, 113, 113, 1));
}

/* Responsive */

/* Tablet (1024px und kleiner) */
@media (max-width: 1024px) {
  .header {
    padding: 14px 24px;
  }

  .logo-img {
    height: 32px;
  }

  .stats-header {
    gap: 16px;
  }

  .stat-icon {
    width: 22px;
    height: 22px;
  }

  .stat-label {
    font-size: 10px;
  }

  .stat-value {
    font-size: 16px;
  }

  .stat-divider {
    height: 26px;
  }

  .logout-btn {
    width: 40px;
    height: 40px;
  }

  .logout-icon {
    width: 16px;
    height: 16px;
  }
}

/* Mobile (768px und kleiner) */
@media (max-width: 768px) {
  .header {
    padding: 12px 16px;
  }

  .logo-img {
    height: 28px;
  }

  .stats-header {
    gap: 8px;
  }

  .stat-item {
    gap: 6px;
  }

  .stat-info {
    display: flex; /* war display: none — entfernt */
  }

  .stat-label {
    font-size: 9px;
  }

  .stat-icon {
    width: 18px;
    height: 18px;
  }

  .stat-value {
    font-size: 13px;
  }

  .stat-divider {
    height: 22px;
  }

  .logout-btn {
    width: 34px;
    height: 34px;
    margin-left: 4px;
  }

  .logout-icon {
    width: 14px;
    height: 14px;
  }
}


/* Small Mobile (480px und kleiner) */
@media (max-width: 480px) {
  .header {
    padding: 10px 12px;
  }

  .logo-img {
    height: 22px;
  }

  .stats-header {
    gap: 6px;
  }

  .stat-item {
    gap: 4px;
  }

  .stat-label {
    font-size: 8px;
  }

  .stat-icon {
    width: 16px;
    height: 16px;
  }

  .stat-value {
    font-size: 12px;
  }

  .stat-divider {
    height: 18px;
  }

  .logout-btn {
    width: 30px;
    height: 30px;
  }

  .logout-icon {
    width: 12px;
    height: 12px;
  }
}
</style>