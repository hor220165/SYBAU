<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue';
import { useNavigation } from "@/composables/useNavigation.ts";
import { useAuth } from "@/composables/useAuth";
import { useCoins } from '@/composables/useCoins';
import { useNotifications } from '@/composables/useNotifications';
import NotificationBell from '@/components/NotificationBell.vue';

const { logout, navigateTo } = useNavigation();
const { user, refreshProfile } = useAuth();
const { formatCoins } = useCoins();
const { connect } = useNotifications();

type RewardFlashDetail = {
  xp?: number;
  coins?: number;
};

const rewardFlash = ref({ xp: 0, coins: 0, key: 0 });
let rewardFlashTimer: ReturnType<typeof setTimeout> | null = null;

function calculateTotalXp(level: number, experience: number) {
  let total = 0;
  for (let lvl = 1; lvl < level; lvl += 1) {
    total += 100 + lvl * lvl * 20;
  }
  return total + experience;
}

function clearRewardFlash() {
  rewardFlash.value = { ...rewardFlash.value, xp: 0, coins: 0 };
  if (rewardFlashTimer) {
    clearTimeout(rewardFlashTimer);
    rewardFlashTimer = null;
  }
}

function showRewardFlash(detail: RewardFlashDetail) {
  const xp = Math.max(0, Number(detail.xp ?? 0));
  const coins = Math.max(0, Number(detail.coins ?? 0));
  if (xp <= 0 && coins <= 0) return;

  if (rewardFlashTimer) {
    clearTimeout(rewardFlashTimer);
  }

  rewardFlash.value = {
    xp,
    coins,
    key: rewardFlash.value.key + 1
  };
  rewardFlashTimer = setTimeout(clearRewardFlash, 4000);
}

function handleRewardFlash(event: Event) {
  showRewardFlash((event as CustomEvent<RewardFlashDetail>).detail ?? {});
}

onMounted(async () => {
  window.addEventListener('sybau:reward-flash', handleRewardFlash);
  if (localStorage.getItem('token')) {
    try {
      await refreshProfile();
    } catch (err) {
      console.error('Failed to fetch profile:', err);
    }
  }
  connect();
});

onUnmounted(() => {
  window.removeEventListener('sybau:reward-flash', handleRewardFlash);
  if (rewardFlashTimer) {
    clearTimeout(rewardFlashTimer);
  }
});

const userLevel = computed(() => user.value?.avatar?.level ?? user.value?.Avatar?.level ?? 0);
const userXP = computed(() => {
  const storedTotalXp = user.value?.totalXp ?? user.value?.TotalXp;
  if (storedTotalXp !== undefined && storedTotalXp !== null) return Number(storedTotalXp);

  const avatar = user.value?.avatar ?? user.value?.Avatar ?? {};
  return calculateTotalXp(Number(avatar.level ?? avatar.Level ?? 0), Number(avatar.experience ?? avatar.Experience ?? 0));
});
const userCoins = computed(() => user.value?.coins ?? user.value?.Coins ?? 0);
</script>

<template>
  <!-- Header -->
  <header class="header">
    <div class="logo-section">
      <button class="logo-button" type="button" @click="navigateTo('/home')" aria-label="Zur Landingpage">
        <img src="../assets/Sybau_logo_short.png" alt="Sybau_Logo" class="logo-img" />
      </button>
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
          <span class="stat-value">{{ formatCoins(userXP) }}</span>
          <Transition name="reward-pop">
            <span
              v-if="rewardFlash.xp > 0"
              :key="`xp-${rewardFlash.key}`"
              class="stat-reward xp-reward"
              aria-live="polite"
            >
              +{{ formatCoins(rewardFlash.xp) }}
            </span>
          </Transition>
        </div>
      </div>

      <div class="stat-divider"></div>

      <div class="stat-item coins">
        <img src="../assets/SYBAU_Coin.png" alt="Coins" class="stat-icon coin-icon">
        <div class="stat-info">
          <span class="stat-label">Coins</span>
          <span class="stat-value">{{ formatCoins(userCoins) }}</span>
          <Transition name="reward-pop">
            <span
              v-if="rewardFlash.coins > 0"
              :key="`coins-${rewardFlash.key}`"
              class="stat-reward coin-reward"
              aria-live="polite"
            >
              +{{ formatCoins(rewardFlash.coins) }}
            </span>
          </Transition>
        </div>
      </div>

      <NotificationBell />

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
  backdrop-filter: blur(18px);
  -webkit-backdrop-filter: blur(18px);
  position: sticky;
  top: 0;
  z-index: 2500;
}

.logo-section {
  display: flex;
  align-items: center;
}

.logo-button {
  display: inline-flex;
  align-items: center;
  padding: 0;
  border: 0;
  background: transparent;
  cursor: pointer;
}

.logo-img {
  height: 50px;
  width: auto;
  object-fit: contain;
}

/* Stats Header */
.stats-header {
  display: flex;
  align-items: center;
  gap: 20px;
  overflow: visible;
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
  position: relative;
  overflow: visible;
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
  color: white;
}

.stat-item.xp .stat-value {
  color: white;
}

.stat-item.coins .stat-value {
  color: white;
}

.stat-reward {
  position: absolute;
  top: calc(100% + 2px);
  left: 0;
  z-index: 2;
  font-size: 12px;
  font-weight: 900;
  line-height: 1;
  pointer-events: none;
  text-shadow: 0 0 12px currentColor;
  white-space: nowrap;
}

.xp-reward {
  color: #60a5fa;
}

.coin-reward {
  color: #fbbf24;
}

.reward-pop-enter-active,
.reward-pop-leave-active {
  transition: opacity 0.22s ease, transform 0.22s ease;
}

.reward-pop-enter-from {
  opacity: 0;
  transform: translateY(-4px) scale(0.96);
}

.reward-pop-leave-to {
  opacity: 0;
  transform: translateY(6px) scale(0.98);
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

  .stat-reward {
    font-size: 10px;
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

  .stat-reward {
    font-size: 9px;
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
