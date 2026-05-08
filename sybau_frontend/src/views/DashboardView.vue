<template>
  <div class="dashboard-container">
    <Header></Header>
    <Navbar></Navbar>

    <main class="main-content">
      <div class="avatar-section">

        <div class="avatar-glow-bg"></div>

        <h2 class="username-clean">{{ userName || 'Champion' }}</h2>

        <div class="avatar-row">

          <div class="equipment-slots left">
            <div class="equip-slot" v-for="slotIdx in [0, 1]" :key="slotIdx" @click="router.push('/avatar')">
              <div class="equip-slot-inner" :class="{ empty: !boostSlots[slotIdx], equipped: !!boostSlots[slotIdx] }">
                <template v-if="boostSlots[slotIdx]">
                  <div class="equip-item-icon">
                    <img v-if="getBoostImage(boostSlots[slotIdx])" :src="getBoostImage(boostSlots[slotIdx])" alt="" />
                    <span v-else>⚡</span>
                  </div>
                  <span class="equip-badge">+{{ boostSlots[slotIdx]!.xpBoostPercentage || boostSlots[slotIdx]!.coinBoostPercentage || 0 }}%</span>
                </template>
                <template v-else>
                  <div class="equip-icon" v-html="`<svg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='1.5' stroke-linecap='round' stroke-linejoin='round'><polygon points='13 2 3 14 12 14 11 22 21 10 12 10 13 2'/></svg>`"></div>
                  <span class="equip-name">Booster</span>
                  <span class="equip-empty">Leer</span>
                </template>
              </div>
            </div>
          </div>

          <div class="avatar-wrapper">
            <div class="avatar-sprite">
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
            <div class="avatar-ground"></div>
          </div>

          <div class="equipment-slots right">
            <div class="equip-slot" v-for="slotIdx in [2, 3]" :key="slotIdx" @click="router.push('/avatar')">
              <div class="equip-slot-inner" :class="{ empty: !boostSlots[slotIdx], equipped: !!boostSlots[slotIdx] }">
                <template v-if="boostSlots[slotIdx]">
                  <div class="equip-item-icon">
                    <img v-if="getBoostImage(boostSlots[slotIdx])" :src="getBoostImage(boostSlots[slotIdx])" alt="" />
                    <span v-else>⚡</span>
                  </div>
                  <span class="equip-badge">+{{ boostSlots[slotIdx]!.xpBoostPercentage || boostSlots[slotIdx]!.coinBoostPercentage || 0 }}%</span>
                </template>
                <template v-else>
                  <div class="equip-icon" v-html="`<svg xmlns='http://www.w3.org/2000/svg' width='22' height='22' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='1.5' stroke-linecap='round' stroke-linejoin='round'><polygon points='13 2 3 14 12 14 11 22 21 10 12 10 13 2'/></svg>`"></div>
                  <span class="equip-name">Booster</span>
                  <span class="equip-empty">Leer</span>
                </template>
              </div>
            </div>
          </div>

        </div>

        <!-- XP Arc -->
        <div class="xp-arc-wrapper">
          <svg class="xp-arc-svg" viewBox="0 0 200 110" xmlns="http://www.w3.org/2000/svg">
            <defs>
              <linearGradient id="arcGrad" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" style="stop-color:#2563eb"/>
                <stop offset="100%" style="stop-color:#06b6d4"/>
              </linearGradient>
              <filter id="arcGlow">
                <feGaussianBlur stdDeviation="3" result="blur"/>
                <feMerge><feMergeNode in="blur"/><feMergeNode in="SourceGraphic"/></feMerge>
              </filter>
            </defs>
            <path d="M 10 105 A 90 90 0 0 1 190 105" fill="none" stroke="rgba(59,130,246,0.12)" stroke-width="6" stroke-linecap="round"/>
            <path d="M 10 105 A 90 90 0 0 1 190 105" fill="none" stroke="url(#arcGrad)" stroke-width="6" stroke-linecap="round"
              :stroke-dasharray="`${arcProgress} 283`" filter="url(#arcGlow)" class="arc-fill"/>
          </svg>
          <div class="arc-center">
            <span class="arc-percent">{{ progressPercent }}%</span>
            <span class="arc-next">{{ xpForNextLevel - currentXp }} bis Lv{{ level + 1 }}</span>
          </div>
        </div>

        <!-- Level + XP row -->
        <div class="arc-meta">
          <span class="arc-meta-item">
            <span class="arc-meta-label">Level</span>
            <span class="arc-meta-value">{{ level }}</span>
          </span>
          <span class="arc-meta-sep"></span>
          <span class="arc-meta-item">
            <span class="arc-meta-label">Gesamt XP</span>
            <span class="arc-meta-value">{{ totalXp.toLocaleString('de-DE') }}</span>
          </span>
        </div>

        <!-- Stats Bar -->
        <div class="stats-bar">
          <div class="stats-bar-item">
            <div class="stats-bar-icon flame" v-html="`<svg xmlns='http://www.w3.org/2000/svg' width='15' height='15' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z'/></svg>`"></div>
            <span class="stats-bar-value">{{ currentStreak }} Tage</span>
            <span class="stats-bar-label">Streak</span>
          </div>
          <div class="stats-bar-sep"></div>
          <div class="stats-bar-item">
            <div class="stats-bar-icon trophy" v-html="`<svg xmlns='http://www.w3.org/2000/svg' width='15' height='15' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M6 9H4.5a2.5 2.5 0 0 1 0-5H6'/><path d='M18 9h1.5a2.5 2.5 0 0 0 0-5H18'/><path d='M4 22h16'/><path d='M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22'/><path d='M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22'/><path d='M18 2H6v7a6 6 0 0 0 12 0V2Z'/></svg>`"></div>
            <span class="stats-bar-value">{{ unlockedAchievements }}/{{ totalAchievements }}</span>
            <span class="stats-bar-label">Badges</span>
          </div>
          <div class="stats-bar-sep"></div>
          <div class="stats-bar-item">
            <div class="stats-bar-icon quest" v-html="`<svg xmlns='http://www.w3.org/2000/svg' width='15' height='15' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><circle cx='12' cy='12' r='10'/><circle cx='12' cy='12' r='6'/><circle cx='12' cy='12' r='2'/></svg>`"></div>
            <span class="stats-bar-value">{{ completedQuests }}/{{ totalQuests }}</span>
            <span class="stats-bar-label">Quests</span>
          </div>
          <div class="stats-bar-sep"></div>
          <div class="stats-bar-item">
            <div class="stats-bar-icon rank" v-html="`<svg xmlns='http://www.w3.org/2000/svg' width='15' height='15' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><circle cx='12' cy='8' r='6'/><path d='M15.477 12.89 17 22l-5-3-5 3 1.523-9.11'/></svg>`"></div>
            <span class="stats-bar-value"><span class="stats-bar-value">{{ leaderboardRank }}</span></span>
            <span class="stats-bar-label">Rang</span>
          </div>
        </div>

      </div>

      <!-- StatCards -->
      <div class="stats-grid">
        <StatCard
          :icon="`<path d='M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z'/>`"
          label="Streak" :value="currentStreak + ' Tage'" cardClass="streak-card"
        />
        <StatCard
          :icon="`<path d='M6 9H4.5a2.5 2.5 0 0 1 0-5H6'/><path d='M18 9h1.5a2.5 2.5 0 0 0 0-5H18'/><path d='M4 22h16'/><path d='M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22'/><path d='M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22'/><path d='M18 2H6v7a6 6 0 0 0 12 0V2Z'/>`"
          label="Achievements" :value="unlockedAchievements + '/' + totalAchievements" cardClass="achievements-card"
        />
        <StatCard
          :icon="`<circle cx='12' cy='12' r='10'/><circle cx='12' cy='12' r='6'/><circle cx='12' cy='12' r='2'/>`"
          label="Quests" :value="completedQuests + '/' + totalQuests" :trend="activeQuests + ' aktiv'" cardClass="quests-card"
        />
        <StatCard
          :icon="`<polyline points='22 7 13.5 15.5 8.5 10.5 2 17'/><polyline points='16 7 22 7 22 13'/>`"
          label="Gesamt XP" :value="totalXp.toLocaleString('de-DE')" :trend="'+' + todayXp + ' XP heute'" cardClass="xp-card"
        />
      </div>
    </main>

    <!-- Booster-Auswahl Modal -->
    <Teleport to="body">
      <div v-if="showBoostModal" class="boost-modal-overlay" @click.self="showBoostModal = false">
        <div class="boost-modal">
          <div class="boost-modal-header">
            <h3>Booster auswählen — Slot {{ selectedSlotIndex + 1 }}</h3>
            <button class="boost-modal-close" @click="showBoostModal = false">&times;</button>
          </div>
          <div class="boost-modal-body">
            <div v-if="ownedBoosters.length === 0" class="boost-modal-empty">
              Du besitzt noch keine Booster. Kaufe welche im Shop!
            </div>
            <div v-else class="boost-list">
              <div
                v-for="booster in ownedBoosters"
                :key="booster.id"
                :class="['boost-item', { 'boost-item-disabled': availableQuantity(booster) <= 0 }]"
                @click="availableQuantity(booster) > 0 && equipBooster(booster)"
              >
                <div class="boost-item-icon">⚡</div>
                <div class="boost-item-info">
                  <span class="boost-item-name">{{ booster.name }}</span>
                  <span class="boost-item-desc">+{{ booster.xpBoostPercentage }}% XP Boost</span>
                </div>
                <span class="boost-item-qty">{{ availableQuantity(booster) }}x</span>
              </div>
              <div class="boost-item boost-item-remove" @click="unequipSlot()" v-if="boostSlots[selectedSlotIndex]">
                <div class="boost-item-icon">🗑️</div>
                <div class="boost-item-info">
                  <span class="boost-item-name">Slot leeren</span>
                  <span class="boost-item-desc">Booster entfernen</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Teleport>

    <FooterComponent />
  </div>
</template>

<script setup lang="ts">
import SpriteAnimator from "../components/spriteAnimator.vue";
import StatCard from "../components/StatCard.vue";
import Navbar from "@/components/Navbar.vue";
import Header from "@/components/Header.vue";
import { onMounted, ref, computed } from 'vue';
import type { item } from '@/models/Item';
import { userService, achievementService, questService, resolveMediaUrl } from '@/services/api';
import FooterComponent from "@/components/FooterComponent.vue";
import { useLeaderboard } from '@/composables/useLeaderboard';
import { useRouter } from 'vue-router';

const userName = ref('');
const email = ref('');
const coins = ref(0);
const level = ref(1);
const currentXp = ref(0);
const xpForNextLevel = ref(1000);
const router = useRouter();

const getBoostImage = (booster: item | null) => resolveMediaUrl(booster?.imageUrl ?? (booster as any)?.ImageUrl ?? '');

// Stats vom Backend
const currentStreak = ref(0);
const unlockedAchievements = ref(0);
const totalAchievements = ref(16);
const completedQuests = ref(0);
const activeQuests = ref(0);
const totalQuests = ref(0);
const caloriesBurned = ref(0);
const todayXp = ref(0);
const totalXp = ref(0);

// Booster State
const boostSlots = ref<Array<item | null>>([null, null, null, null]);
const ownedBoosters = ref<item[]>([]);
const showBoostModal = ref(false);
const selectedSlotIndex = ref(0);

const progressPercent = computed(() => {
  const denom = xpForNextLevel.value || 1;
  return Math.min(100, Math.floor((currentXp.value / denom) * 100));
});

const arcProgress = computed(() => (progressPercent.value / 100) * 283);

const { sortedLeaderboard, loadLeaderboard } = useLeaderboard();

const leaderboardRank = computed(() => {
  const name = userName.value.toLowerCase();
  const entry = sortedLeaderboard.value.find(
    (p: any) => (p.UserName ?? p.userName ?? '').toLowerCase() === name
  );
  return entry ? `#${entry.Rank ?? sortedLeaderboard.value.indexOf(entry) + 1}` : '—';
});

async function loadProfile() {
  try {
    const res = await userService.getProfile();
    const data = res.data ?? {};
    userName.value = data.userName ?? '';
    email.value = data.email ?? '';
    coins.value = data.coins ?? 0;
    const avatar = data.avatar ?? {};
    level.value = avatar.level ?? 0;
    currentXp.value = avatar.experience ?? 0;
    xpForNextLevel.value = avatar.xpForNextLevel ?? 1000;

    // Booster-Slots aus Profil laden und mit owned Boosters matchen
    await loadOwnedBoosters();
    const slotNames = [avatar.boost1, avatar.boost2, avatar.boost3, avatar.boost4];
    boostSlots.value = slotNames.map((name: string | null) => {
      if (!name) return null;
      return ownedBoosters.value.find(b => b.name === name) ?? null;
    });
  } catch (e) {
    console.error('Fehler beim Laden des Profils', e);
  }
  await loadLeaderboard();
}

async function loadOwnedBoosters() {
  try {
    const res = await userService.getUserBoosters();
    ownedBoosters.value = res.data ?? [];
  } catch (e) {
    console.error('Fehler beim Laden der Booster', e);
  }
}

// Berechne wie oft ein Booster schon in Slots verwendet wird (ohne den aktuellen Slot)
function availableQuantity(booster: item): number {
  const totalOwned = booster.quantity ?? 1;
  const usedInOtherSlots = boostSlots.value.filter(
    (b: item | null, idx: number) => b?.id === booster.id && idx !== selectedSlotIndex.value
  ).length;
  return totalOwned - usedInOtherSlots;
}

async function equipBooster(booster: item) {
  const slots = boostSlots.value.map((b: item | null) => b?.id ?? null);
  slots[selectedSlotIndex.value] = booster.id;

  try {
    await userService.updateBoostSlots(slots);
    boostSlots.value[selectedSlotIndex.value] = booster;
    showBoostModal.value = false;
  } catch (e) {
    console.error('Fehler beim Equippen des Boosters', e);
  }
}

async function unequipSlot() {
  const slots = boostSlots.value.map(b => b?.id ?? null);
  slots[selectedSlotIndex.value] = null;

  try {
    await userService.updateBoostSlots(slots);
    boostSlots.value[selectedSlotIndex.value] = null;
    showBoostModal.value = false;
  } catch (e) {
    console.error('Fehler beim Entfernen des Boosters', e);
  }
}

onMounted(async () => {
  await loadProfile();
  try {
    const [achRes, questRes, statsRes, xpRes] = await Promise.all([
      achievementService.getAll(),
      questService.getMyQuests(),
      achievementService.getProfileStats(),
      achievementService.getTodayXp()
    ]);
    const achs = achRes.data ?? [];
    totalAchievements.value = achs.length;
    unlockedAchievements.value = achs.filter((a: any) => a.unlocked).length;
    const quests = questRes.data ?? [];
    totalQuests.value = quests.length;
    completedQuests.value = quests.filter((q: any) => q.isCompleted).length;
    activeQuests.value = quests.filter((q: any) => !q.isCompleted).length;
    const stats = statsRes.data ?? {};
    caloriesBurned.value = stats.caloriesBurned ?? 0;
    currentStreak.value = stats.currentStreak ?? 0;
    todayXp.value = xpRes.data?.todayXp ?? 0;
    totalXp.value = xpRes.data?.totalXp ?? 0;
  } catch { /* stats nicht verfügbar */ }
});
</script>

<style scoped>
.dashboard-container {
  min-height: 100vh;
  color: white;
}

.main-content {
  padding: 40px;
  max-width: 1400px;
  margin: 0 auto;
}

.avatar-section {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin-bottom: 56px;
  position: relative;
}

.avatar-glow-bg {
  position: absolute;
  top: 20px;
  left: 50%;
  transform: translateX(-50%);
  width: 340px;
  height: 420px;
  border-radius: 50%;
  background: radial-gradient(
    ellipse 65% 100% at 50% 45%,
    rgba(59, 130, 246, 0.16) 0%,
    rgba(6, 182, 212, 0.08) 45%,
    transparent 70%
  );
  filter: blur(28px);
  pointer-events: none;
  z-index: 0;
}

.username-clean {
  position: relative;
  z-index: 2;
  font-size: 18px;
  font-weight: 600;
  letter-spacing: 4px;
  text-transform: uppercase;
  color: rgba(255, 255, 255, 0.75);
  margin: 0 0 20px 0;
}

.avatar-row {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 20px;
  position: relative;
  z-index: 2;
}

/* ══════════════════════════════
   EQUIPMENT SLOTS
══════════════════════════════ */
.equipment-slots {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.equip-slot {
  width: 100px;
  height: 100px;
}

.equip-slot-inner {
  width: 100%;
  height: 100%;
  border-radius: 14px;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 5px;
  cursor: pointer;
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
}

.equip-slot-inner.empty {
  background: rgba(15, 23, 42, 0.5);
  border: 1px dashed rgba(168, 85, 247, 0.25);
  backdrop-filter: blur(10px);
}

.equip-slot-inner.empty:hover {
  border-color: rgba(168, 85, 247, 0.5);
  background: rgba(168, 85, 247, 0.07);
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(168, 85, 247, 0.15);
}

.equip-slot-inner::before,
.equip-slot-inner::after {
  content: '';
  position: absolute;
  width: 10px;
  height: 10px;
  border-color: rgba(168, 85, 247, 0.4);
  border-style: solid;
}

.equip-slot-inner::before {
  top: 6px;
  left: 6px;
  border-width: 1px 0 0 1px;
}

.equip-slot-inner::after {
  bottom: 6px;
  right: 6px;
  border-width: 0 1px 1px 0;
}

.equip-icon {
  color: rgba(168, 85, 247, 0.45);
  display: flex;
  transition: all 0.3s ease;
}

.equip-slot-inner:hover .equip-icon {
  color: rgba(168, 85, 247, 0.8);
  filter: drop-shadow(0 0 6px rgba(168, 85, 247, 0.6));
}

.equip-name {
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 1px;
  text-transform: uppercase;
  color: rgba(255, 255, 255, 0.5);
}

.equip-empty {
  font-size: 9px;
  color: rgba(255, 255, 255, 0.2);
  letter-spacing: 0.5px;
}

/* ══════════════════════════════
   AVATAR
══════════════════════════════ */
.avatar-wrapper {
  display: flex;
  flex-direction: column;
  align-items: center;
  flex-shrink: 0;
}

.avatar-sprite {
  image-rendering: pixelated;
  filter:
    drop-shadow(0 0 14px rgba(59, 130, 246, 0.6))
    drop-shadow(0 0 36px rgba(6, 182, 212, 0.3))
    drop-shadow(0 16px 28px rgba(0, 0, 0, 0.7));
}

.avatar-ground {
  width: 180px;
  height: 28px;
  margin-top: -50px;
  margin-bottom: 20px;
  border-radius: 50%;
  background: radial-gradient(ellipse, rgba(59, 130, 246, 0.7) 0%, rgba(59, 130, 246, 0.25) 50%, transparent 70%);
  filter: blur(10px);
}

/* ══════════════════════════════
   XP ARC
══════════════════════════════ */
.xp-arc-wrapper {
  position: relative;
  z-index: 2;
  width: 220px;
  height: 120px;
  margin-top: -4px;
}

.xp-arc-svg {
  width: 100%;
  height: 100%;
  overflow: visible;
}

.arc-fill {
  transition: stroke-dasharray 0.8s cubic-bezier(0.4, 0, 0.2, 1);
}

.arc-center {
  position: absolute;
  bottom: 2px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  white-space: nowrap;
}

.arc-percent {
  font-size: 15px;
  font-weight: 800;
  color: white;
  text-shadow: 0 0 10px rgba(6, 182, 212, 0.7);
}

.arc-next {
  font-size: 10px;
  color: rgba(255, 255, 255, 0.35);
  font-weight: 500;
}

/* ══════════════════════════════
   ARC META (Level + XP)
══════════════════════════════ */
.arc-meta {
  display: flex;
  align-items: center;
  margin-top: 10px;
  position: relative;
  z-index: 2;
}

.arc-meta-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0 20px;
}

.arc-meta-sep {
  width: 1px;
  height: 20px;
  background: rgba(255, 255, 255, 0.08);
}

.arc-meta-label {
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 1.5px;
  text-transform: uppercase;
  color: rgba(255, 255, 255, 0.3);
}

.arc-meta-value {
  font-size: 16px;
  font-weight: 800;
  color: white;
  text-shadow: 0 0 12px rgba(59, 130, 246, 0.5);
}

/* ══════════════════════════════
   STATS BAR
══════════════════════════════ */
.stats-bar {
  display: flex;
  align-items: center;
  margin-top: 20px;
  position: relative;
  z-index: 2;
}

.stats-bar-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 3px;
  padding: 0 20px;
}

.stats-bar-sep {
  width: 1px;
  height: 28px;
  background: rgba(255, 255, 255, 0.08);
  flex-shrink: 0;
}

.stats-bar-icon {
  display: flex;
  margin-bottom: 2px;
}

.flame  { color: #f97316; filter: drop-shadow(0 0 5px rgba(249, 115, 22, 0.7)); }
.trophy { color: #fbbf24; filter: drop-shadow(0 0 5px rgba(251, 191, 36, 0.7)); }
.quest  { color: #a855f7; filter: drop-shadow(0 0 5px rgba(168, 85, 247, 0.7)); }
.rank   { color: #ec4899; filter: drop-shadow(0 0 5px rgba(236, 72, 153, 0.7)); }

.stats-bar-value {
  font-size: 13px;
  font-weight: 800;
  color: white;
  line-height: 1;
}

.stats-bar-label {
  font-size: 9px;
  font-weight: 600;
  letter-spacing: 1px;
  text-transform: uppercase;
  color: rgba(255, 255, 255, 0.3);
}

/* ══════════════════════════════
   STATS GRID
══════════════════════════════ */
.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 24px;
}

/* ══════════════════════════════
   RESPONSIVE
══════════════════════════════ */
@media (max-width: 1200px) {
  .stats-grid { grid-template-columns: repeat(2, 1fr); }
}

@media (max-width: 768px) {
  .main-content { padding: 24px 16px; }
  .equip-slot { width: 80px; height: 80px; }
  .equip-slot-inner::before,
  .equip-slot-inner::after { width: 7px; height: 7px; }
  .stats-bar-item { padding: 0 12px; }
  .arc-meta-item { padding: 0 12px; }
  .stats-grid { grid-template-columns: repeat(2, 1fr); gap: 16px; }
}

@media (max-width: 600px) {
  .avatar-row {
    flex-direction: row;
    gap: 8px;
    width: 100%;
    justify-content: center;
  }

  .equipment-slots {
    gap: 8px;
    flex-shrink: 0;
  }

  .equip-slot {
    width: 68px;
    height: 68px;
  }

  .equip-slot-inner::before,
  .equip-slot-inner::after {
    width: 7px;
    height: 7px;
  }

  .equip-name { display: none; }
  .equip-empty { display: none; }

  .avatar-wrapper {
    flex-shrink: 0;
  }

  .avatar-sprite {
  transform: scale(0.8);
  transform-origin: center bottom;
  margin-left: -100px;
  margin-right: -100px;
  margin-top: -60px;
}

.avatar-ground {
  width: 120px;
  height: 16px;
  margin-top: -30px;
}

  .avatar-glow-bg {
    width: 200px;
    height: 280px;
  }

  .username-clean { font-size: 13px; letter-spacing: 3px; }
  .xp-arc-wrapper { width: 180px; height: 100px; }
  .stats-bar { flex-wrap: wrap; justify-content: center; gap: 8px; }
  .stats-bar-sep { display: none; }
  .stats-bar-item { padding: 0 10px; }
  .stats-grid { grid-template-columns: 1fr 1fr; gap: 12px; }
}

/* ══════════════════════════════
   EQUIPPED SLOT
══════════════════════════════ */
.equip-slot-inner.equipped {
  background: rgba(168, 85, 247, 0.12);
  border: 1px solid rgba(168, 85, 247, 0.4);
  backdrop-filter: blur(10px);
  gap: 8px;
}

.equip-slot-inner.equipped:hover {
  border-color: rgba(168, 85, 247, 0.7);
  background: rgba(168, 85, 247, 0.18);
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(168, 85, 247, 0.25);
}

.equip-slot-inner.equipped .equip-icon {
  color: rgba(168, 85, 247, 0.9);
  filter: drop-shadow(0 0 6px rgba(168, 85, 247, 0.6));
}

.equip-boost {
  font-size: 8px;
  font-weight: 700;
  color: rgba(168, 85, 247, 0.9);
  letter-spacing: 0.5px;
}

.equip-item-icon {
  font-size: 34px;
  filter: drop-shadow(0 0 6px rgba(168, 85, 247, 0.6));
  display: grid;
  place-items: center;
  width: 48px;
  height: 48px;
}

.equip-item-icon img {
  width: 48px;
  height: 48px;
  object-fit: contain;
  image-rendering: pixelated;
}

.equip-badge {
  font-size: 11px;
  font-weight: 700;
  color: rgba(168, 85, 247, 0.95);
  background: rgba(168, 85, 247, 0.15);
  padding: 2px 6px;
  border-radius: 8px;
  letter-spacing: 0.5px;
}

/* ══════════════════════════════
   BOOSTER MODAL
══════════════════════════════ */
.boost-modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.7);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 9999;
}

.boost-modal {
  background: #0f172a;
  border: 1px solid rgba(168, 85, 247, 0.3);
  border-radius: 16px;
  width: 380px;
  max-width: 90vw;
  max-height: 80vh;
  overflow: hidden;
  box-shadow: 0 24px 48px rgba(0, 0, 0, 0.5), 0 0 60px rgba(168, 85, 247, 0.1);
}

.boost-modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
}

.boost-modal-header h3 {
  font-size: 14px;
  font-weight: 700;
  color: white;
  margin: 0;
  letter-spacing: 0.5px;
}

.boost-modal-close {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.4);
  font-size: 22px;
  cursor: pointer;
  padding: 0 4px;
  transition: color 0.2s;
}

.boost-modal-close:hover {
  color: white;
}

.boost-modal-body {
  padding: 12px 16px 20px;
  overflow-y: auto;
  max-height: 50vh;
}

.boost-modal-empty {
  text-align: center;
  color: rgba(255, 255, 255, 0.4);
  font-size: 13px;
  padding: 24px 0;
}

.boost-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.boost-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 14px;
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.06);
  cursor: pointer;
  transition: all 0.2s ease;
}

.boost-item:hover {
  background: rgba(168, 85, 247, 0.1);
  border-color: rgba(168, 85, 247, 0.35);
  transform: translateX(4px);
}

.boost-item-remove:hover {
  background: rgba(239, 68, 68, 0.1);
  border-color: rgba(239, 68, 68, 0.35);
}

.boost-item-disabled {
  opacity: 0.35;
  cursor: not-allowed !important;
  pointer-events: none;
}

.boost-item-qty {
  margin-left: auto;
  font-size: 12px;
  font-weight: 700;
  color: rgba(168, 85, 247, 0.7);
  flex-shrink: 0;
}

.boost-item-icon {
  font-size: 20px;
  flex-shrink: 0;
}

.boost-item-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.boost-item-name {
  font-size: 13px;
  font-weight: 600;
  color: white;
}

.boost-item-desc {
  font-size: 11px;
  color: rgba(168, 85, 247, 0.7);
  font-weight: 500;
}
</style>
