<template>
  <!-- Header -->
  <Header></Header>

  <!-- Navigation -->
  <Navbar></Navbar>

  <!-- Main Content -->
  <main class="main-content">

    <!-- Boost Stats — Full Width Top Bar -->
    <div class="boost-stats">
      <div class="boost-card">
        <div class="boost-icon-wrap xp-boost">
          <TrendingUp :size="20" />
        </div>
        <div class="boost-info">
          <span class="boost-label">XP Boost</span>
          <span class="boost-value" :class="{ active: totalXpBoost > 0 }">+{{ totalXpBoost }}%</span>
        </div>
        <div class="boost-bar-track">
          <div class="boost-bar-fill xp" :style="{ width: Math.min(totalXpBoost, 100) + '%' }"></div>
        </div>
      </div>
      <div class="boost-card">
        <div class="boost-icon-wrap coin-boost">
          <CircleDollarSign :size="20" />
        </div>
        <div class="boost-info">
          <span class="boost-label">Coin Boost</span>
          <span class="boost-value" :class="{ active: totalCoinBoost > 0 }">+{{ totalCoinBoost }}%</span>
        </div>
        <div class="boost-bar-track">
          <div class="boost-bar-fill coin" :style="{ width: Math.min(totalCoinBoost, 100) + '%' }"></div>
        </div>
      </div>
    </div>

    <!-- Two-Column Layout -->
    <div class="equip-layout">

      <!-- LEFT: Avatar + Equipment Slots -->
      <div class="avatar-panel">
        <div class="avatar-section">
          <div class="avatar-glow-bg"></div>

          <h2 class="username-clean">{{ userName || 'Champion' }}</h2>

          <div class="avatar-row">
            <div class="equipment-slots left">
              <div class="equip-slot" v-for="(slot, i) in equipSlots.slice(0, 2)" :key="'left-' + i">
                <div
                  class="equip-slot-inner"
                  :class="{
                    empty: !slot.item,
                    equipped: !!slot.item,
                    'slot-highlight': selectingSlotFor !== null
                  }"
                  @click="handleSlotClick(i)"
                >
                  <div class="equip-icon" v-if="!slot.item">
                    <Zap :size="22" />
                  </div>
                  <div class="equip-item-icon" v-else>{{ slot.item.icon }}</div>
                  <span class="equip-name">{{ slot.item ? slot.item.name : slot.label }}</span>
                  <span class="equip-empty" v-if="!slot.item && selectingSlotFor === null">Leer</span>
                  <span class="equip-select-hint" v-if="!slot.item && selectingSlotFor !== null">Hier</span>
                  <span class="equip-badge" v-if="slot.item">+{{ slot.item.boostValue }}%</span>
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
              <div class="equip-slot" v-for="(slot, i) in equipSlots.slice(2, 4)" :key="'right-' + i">
                <div
                  class="equip-slot-inner"
                  :class="{
                    empty: !slot.item,
                    equipped: !!slot.item,
                    'slot-highlight': selectingSlotFor !== null
                  }"
                  @click="handleSlotClick(i + 2)"
                >
                  <div class="equip-icon" v-if="!slot.item">
                    <Zap :size="22" />
                  </div>
                  <div class="equip-item-icon" v-else>{{ slot.item.icon }}</div>
                  <span class="equip-name">{{ slot.item ? slot.item.name : slot.label }}</span>
                  <span class="equip-empty" v-if="!slot.item && selectingSlotFor === null">Leer</span>
                  <span class="equip-select-hint" v-if="!slot.item && selectingSlotFor !== null">Hier</span>
                  <span class="equip-badge" v-if="slot.item">+{{ slot.item.boostValue }}%</span>
                </div>
              </div>
            </div>
          </div>

          <!-- Slot selection banner -->
          <Transition name="fade">
            <div v-if="selectingSlotFor !== null" class="slot-select-banner">
              <Zap :size="16" />
              <span>Wähle einen Slot für <strong>{{ selectingSlotFor.name }}</strong></span>
              <button class="cancel-select" @click="selectingSlotFor = null">Abbrechen</button>
            </div>
          </Transition>
        </div>
      </div>

      <!-- RIGHT: Booster Inventory -->
      <div class="inventory-panel">
        <div class="section-header">
          <div class="section-title">
            <Sparkles :size="22" class="section-icon" />
            <h2>Inventar</h2>
          </div>
          <span class="inventory-count">{{ inventory.reduce((sum, b) => sum + b.quantity, 0) }} Booster ({{ inventory.length }} verschiedene)</span>
        </div>

        <div v-if="availableBoosters.length === 0" class="empty-inventory">
          <ShoppingBag :size="48" class="empty-icon" />
          <p>Keine Booster vorhanden</p>
          <span>Kaufe Booster im Shop!</span>
          <button class="shop-btn" @click="$router.push('/shop')">Zum Shop</button>
        </div>

        <div v-else class="booster-list">
          <div
            v-for="booster in inventory"
            :key="booster.id"
            class="booster-card"
            :class="[
              'rarity-' + booster.rarity,
              { 'is-equipped': isEquipped(booster.id) }
            ]"
          >
            <div class="booster-glow"></div>
            <div class="booster-card-inner">
              <div class="booster-card-top">
                <div class="booster-icon-wrapper" :class="'rarity-icon-' + booster.rarity">
                  <span class="booster-icon">{{ booster.icon }}</span>
                  <span v-if="booster.quantity > 1" class="booster-qty-badge">{{ booster.quantity }}x</span>
                </div>
                <div class="booster-meta">
                  <h3>{{ booster.name }}</h3>
                  <div class="booster-rarity-tag" :class="'tag-' + booster.rarity">{{ booster.rarity }}</div>
                </div>
              </div>

              <p class="booster-desc">{{ booster.description }}</p>

              <div class="booster-stat-row">
                <div v-if="booster.xpBoost" class="booster-stat xp">
                  <TrendingUp :size="13" />
                  <span>+{{ booster.xpBoost }}% XP</span>
                </div>
                <div v-if="booster.coinBoost" class="booster-stat coin">
                  <CircleDollarSign :size="13" />
                  <span>+{{ booster.coinBoost }}% Coins</span>
                </div>
              </div>

              <!-- Quantity Anzeige -->
              <div v-if="booster.quantity > 1" class="booster-qty-row">
                <span class="booster-qty-label">{{ equippedCount(booster.id) }}/{{ booster.quantity }} ausgerüstet</span>
              </div>

              <div class="booster-card-footer">
                <span v-if="isEquipped(booster.id)" class="equipped-badge">
                  <Shield :size="12" /> {{ equippedCount(booster.id) }}x Ausgerüstet
                </span>
                <button
                  v-if="canEquipMore(booster)"
                  class="equip-btn"
                  @click="startEquip(booster)"
                >
                  <Zap :size="14" /> Ausrüsten
                </button>
                <button
                  v-if="isEquipped(booster.id)"
                  class="unequip-btn"
                  @click="unequipBoosterById(booster.id)"
                >
                  Ablegen
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

    </div>
  </main>

  <!-- Footer -->
  <FooterComponent />
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { Zap, TrendingUp, CircleDollarSign, Sparkles, ShoppingBag, Shield } from 'lucide-vue-next';
import Header from '@/components/Header.vue';
import Navbar from '@/components/Navbar.vue';
import SpriteAnimator from '@/components/spriteAnimator.vue';
import FooterComponent from '@/components/FooterComponent.vue';
import { userService } from '@/services/api';
import { useAuth } from '@/composables/useAuth';

const { refreshProfile } = useAuth();
const userName = ref('');

interface BoosterItem {
  id: number;
  name: string;
  icon: string;
  description: string;
  xpBoost: number;
  coinBoost: number;
  boostValue: number;
  rarity: 'common' | 'rare' | 'epic' | 'legendary';
  quantity: number;
}

interface EquipSlot {
  label: string;
  item: BoosterItem | null;
}

const equipSlots = ref<EquipSlot[]>([
  { label: 'Booster', item: null },
  { label: 'Booster', item: null },
  { label: 'Booster', item: null },
  { label: 'Booster', item: null },
]);

const selectingSlotFor = ref<BoosterItem | null>(null);
const inventory = ref<BoosterItem[]>([]);

// Rarity basierend auf Gesamt-Boost ableiten
function getRarity(xp: number, coin: number): 'common' | 'rare' | 'epic' | 'legendary' {
  const total = xp + coin;
  if (total >= 60) return 'legendary';
  if (total >= 40) return 'epic';
  if (total >= 20) return 'rare';
  return 'common';
}

// Icon basierend auf Boost-Typ ableiten
function getIcon(xp: number, coin: number): string {
  if (xp > 0 && coin > 0) return '🔥';
  if (coin > 0) return '🪙';
  return '⚡';
}

// Backend-Booster in Frontend-Format umwandeln
function mapBooster(b: any): BoosterItem {
  const xp = b.xpBoostPercentage ?? 0;
  const coin = b.coinBoostPercentage ?? 0;
  return {
    id: b.id,
    name: b.name,
    icon: getIcon(xp, coin),
    description: b.description ?? '',
    xpBoost: xp,
    coinBoost: coin,
    boostValue: xp + coin,
    rarity: b.rarity ?? getRarity(xp, coin),
    quantity: b.quantity ?? 1
  };
}

const availableBoosters = computed(() => inventory.value);

const totalXpBoost = computed(() =>
  equipSlots.value.reduce((sum, slot) => sum + (slot.item?.xpBoost ?? 0), 0)
);

const totalCoinBoost = computed(() =>
  equipSlots.value.reduce((sum, slot) => sum + (slot.item?.coinBoost ?? 0), 0)
);

// Wie oft ist dieser Booster aktuell in Slots?
function equippedCount(id: number): number {
  return equipSlots.value.filter(s => s.item?.id === id).length;
}

const isEquipped = (id: number) => equippedCount(id) > 0;

// Kann noch in weitere Slots?
function canEquipMore(booster: BoosterItem): boolean {
  return booster.quantity > equippedCount(booster.id);
}

const startEquip = (booster: BoosterItem) => {
  selectingSlotFor.value = booster;
};

const handleSlotClick = async (slotIndex: number) => {
  if (slotIndex < 0 || slotIndex >= equipSlots.value.length) return;

  if (selectingSlotFor.value) {
    // Booster in Slot setzen
    equipSlots.value[slotIndex]!.item = selectingSlotFor.value;
    selectingSlotFor.value = null;
    await saveSlots();
  } else if (equipSlots.value[slotIndex]!.item) {
    // Slot leeren
    equipSlots.value[slotIndex]!.item = null;
    await saveSlots();
  }
};

const unequipBoosterById = async (id: number) => {
  const slot = equipSlots.value.find(s => s.item?.id === id);
  if (slot) {
    slot.item = null;
    await saveSlots();
  }
};

async function saveSlots() {
  const slots = equipSlots.value.map(s => s.item?.id ?? null);
  try {
    await userService.updateBoostSlots(slots);
    await refreshProfile();
  } catch (e) {
    console.error('Fehler beim Speichern der Booster-Slots', e);
  }
}

async function loadProfile() {
  try {
    const res = await userService.getProfile();
    const data = res.data ?? {};
    userName.value = data.userName ?? '';

    // Booster-Inventar laden
    await loadOwnedBoosters();

    // Equippte Slots aus Profil wiederherstellen
    const avatar = data.avatar ?? {};
    const slotNames = [avatar.boost1, avatar.boost2, avatar.boost3, avatar.boost4];
    equipSlots.value = slotNames.map((name: string | null) => ({
      label: 'Booster',
      item: name ? inventory.value.find(b => b.name === name) ?? null : null
    }));
  } catch (e) {
    console.error('Fehler beim Laden des Profils', e);
  }
}

async function loadOwnedBoosters() {
  try {
    const res = await userService.getUserBoosters();
    inventory.value = (res.data ?? []).map(mapBooster);
  } catch (e) {
    console.error('Fehler beim Laden der Booster', e);
  }
}

onMounted(() => loadProfile());
</script>

<style scoped>
.main-content {
  padding: 40px;
  max-width: 1400px;
  margin: 0 auto;
}

/* ══════════════════════════════
   BOOST STATS — FULL WIDTH TOP
══════════════════════════════ */
.boost-stats {
  display: flex;
  gap: 20px;
  margin-bottom: 32px;
}

.boost-card {
  flex: 1;
  display: flex;
  align-items: center;
  gap: 16px;
  background: rgba(15, 23, 42, 0.6);
  border: 1px solid rgba(255, 255, 255, 0.06);
  border-radius: 16px;
  padding: 20px 28px;
  backdrop-filter: blur(10px);
  transition: all 0.3s ease;
  position: relative;
  overflow: hidden;
}

.boost-card:hover {
  border-color: rgba(236, 72, 153, 0.3);
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.2);
}

.boost-bar-track {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 3px;
  background: rgba(255, 255, 255, 0.04);
}

.boost-bar-fill {
  height: 100%;
  border-radius: 0 3px 0 0;
  transition: width 0.6s cubic-bezier(0.4, 0, 0.2, 1);
}

.boost-bar-fill.xp {
  background: linear-gradient(90deg, #3b82f6, #06b6d4);
  box-shadow: 0 0 10px rgba(59, 130, 246, 0.5);
}

.boost-bar-fill.coin {
  background: linear-gradient(90deg, #f59e0b, #fbbf24);
  box-shadow: 0 0 10px rgba(251, 191, 36, 0.5);
}

.boost-icon-wrap {
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 10px;
  flex-shrink: 0;
}

.boost-icon-wrap.xp-boost {
  background: rgba(59, 130, 246, 0.15);
  color: #3b82f6;
  border: 1px solid rgba(59, 130, 246, 0.25);
}

.boost-icon-wrap.coin-boost {
  background: rgba(251, 191, 36, 0.15);
  color: #fbbf24;
  border: 1px solid rgba(251, 191, 36, 0.25);
}

.boost-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.boost-label {
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 1px;
  text-transform: uppercase;
  color: rgba(255, 255, 255, 0.35);
}

.boost-value {
  font-size: 22px;
  font-weight: 800;
  color: rgba(255, 255, 255, 0.25);
  transition: all 0.3s ease;
}

.boost-value.active {
  color: #34d399;
  text-shadow: 0 0 14px rgba(52, 211, 153, 0.5);
}

/* ══════════════════════════════
   TWO-COLUMN LAYOUT
══════════════════════════════ */
.equip-layout {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 40px;
  align-items: start;
}

/* ══════════════════════════════
   LEFT PANEL — AVATAR
══════════════════════════════ */

.avatar-section {
  display: flex;
  flex-direction: column;
  align-items: center;
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

/* ── EQUIPMENT SLOTS ── */
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

.equip-slot-inner.slot-highlight.empty {
  border-color: rgba(168, 85, 247, 0.6);
  background: rgba(168, 85, 247, 0.1);
  animation: slotPulse 1.5s ease-in-out infinite;
}

@keyframes slotPulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(168, 85, 247, 0.3); }
  50% { box-shadow: 0 0 20px 4px rgba(168, 85, 247, 0.4); }
}

.equip-slot-inner.equipped {
  background: rgba(168, 85, 247, 0.12);
  border: 1px solid rgba(168, 85, 247, 0.5);
  backdrop-filter: blur(10px);
  box-shadow: 0 0 20px rgba(168, 85, 247, 0.15);
}

.equip-slot-inner.equipped:hover {
  background: rgba(168, 85, 247, 0.18);
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(168, 85, 247, 0.25);
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

.equip-item-icon {
  font-size: 24px;
  filter: drop-shadow(0 0 8px rgba(168, 85, 247, 0.5));
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

.equip-select-hint {
  font-size: 9px;
  font-weight: 700;
  color: #a855f7;
  letter-spacing: 0.5px;
  animation: hintPulse 1s ease-in-out infinite;
}

@keyframes hintPulse {
  0%, 100% { opacity: 0.6; }
  50% { opacity: 1; }
}

.equip-badge {
  font-size: 9px;
  font-weight: 700;
  color: #a855f7;
  letter-spacing: 0.5px;
}

/* Slot selection banner */
.slot-select-banner {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 20px;
  padding: 12px 20px;
  background: rgba(168, 85, 247, 0.12);
  border: 1px solid rgba(168, 85, 247, 0.35);
  border-radius: 14px;
  color: #c084fc;
  font-size: 13px;
  font-weight: 500;
  z-index: 2;
  position: relative;
}

.slot-select-banner strong { color: white; }

.cancel-select {
  margin-left: auto;
  padding: 6px 14px;
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.15);
  background: rgba(255, 255, 255, 0.06);
  color: rgba(255, 255, 255, 0.6);
  font-size: 12px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.cancel-select:hover {
  background: rgba(239, 68, 68, 0.15);
  border-color: rgba(239, 68, 68, 0.4);
  color: #f87171;
}

.fade-enter-active, .fade-leave-active { transition: all 0.25s ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; transform: translateY(-8px); }

/* ── AVATAR ── */
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
   RIGHT PANEL — INVENTORY
══════════════════════════════ */
.inventory-panel {
  min-width: 0;
  max-height: calc(100vh - 180px);
  overflow-y: auto;
  padding-right: 4px;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.section-title {
  display: flex;
  align-items: center;
  gap: 12px;
}

.section-icon { color: #ec4899; }

.section-title h2 {
  font-size: 22px;
  font-weight: 700;
  color: white;
  margin: 0;
}

.inventory-count {
  padding: 6px 14px;
  background: rgba(168, 85, 247, 0.15);
  border: 1px solid rgba(168, 85, 247, 0.3);
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  color: #a855f7;
}

/* Empty State */
.empty-inventory {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  padding: 60px 20px;
  background: rgba(15, 23, 42, 0.4);
  border: 1px dashed rgba(255, 255, 255, 0.08);
  border-radius: 20px;
  text-align: center;
}

.empty-icon { color: rgba(255, 255, 255, 0.15); }

.empty-inventory p {
  font-size: 18px;
  font-weight: 600;
  color: rgba(255, 255, 255, 0.5);
  margin: 0;
}

.empty-inventory span {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.3);
}

.shop-btn {
  margin-top: 8px;
  padding: 12px 28px;
  border-radius: 12px;
  border: none;
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  color: white;
  font-weight: 600;
  font-size: 15px;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 4px 12px rgba(236, 72, 153, 0.3);
}

.shop-btn:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(236, 72, 153, 0.4);
}

/* ══════════════════════════════
   BOOSTER CARDS — VERTICAL LIST
══════════════════════════════ */
.booster-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.booster-card {
  position: relative;
  border-radius: 18px;
  overflow: hidden;
  transition: all 0.35s cubic-bezier(0.4, 0, 0.2, 1);
}

.booster-card:hover {
  transform: translateY(-2px);
}

.booster-glow {
  position: absolute;
  inset: -2px;
  border-radius: 20px;
  z-index: 0;
  opacity: 0;
  transition: opacity 0.35s ease;
}

.booster-card:hover .booster-glow { opacity: 1; }

.rarity-common .booster-glow {
  background: linear-gradient(135deg, rgba(148, 163, 184, 0.4), rgba(100, 116, 139, 0.2));
  box-shadow: 0 0 30px rgba(148, 163, 184, 0.2);
}
.rarity-rare .booster-glow {
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.5), rgba(37, 99, 235, 0.3));
  box-shadow: 0 0 30px rgba(59, 130, 246, 0.3);
}
.rarity-epic .booster-glow {
  background: linear-gradient(135deg, rgba(168, 85, 247, 0.5), rgba(139, 92, 246, 0.3));
  box-shadow: 0 0 30px rgba(168, 85, 247, 0.3);
}
.rarity-legendary .booster-glow {
  background: linear-gradient(135deg, rgba(245, 158, 11, 0.5), rgba(249, 115, 22, 0.3));
  box-shadow: 0 0 30px rgba(245, 158, 11, 0.3);
}

.booster-card-inner {
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 20px;
  border-radius: 18px;
  backdrop-filter: blur(16px);
}

.rarity-common .booster-card-inner {
  background: linear-gradient(160deg, rgba(30, 41, 59, 0.85), rgba(15, 23, 42, 0.9));
  border: 1px solid rgba(148, 163, 184, 0.15);
}
.rarity-rare .booster-card-inner {
  background: linear-gradient(160deg, rgba(30, 58, 95, 0.7), rgba(15, 23, 42, 0.9));
  border: 1px solid rgba(59, 130, 246, 0.3);
}
.rarity-epic .booster-card-inner {
  background: linear-gradient(160deg, rgba(55, 30, 80, 0.7), rgba(15, 23, 42, 0.9));
  border: 1px solid rgba(168, 85, 247, 0.35);
}
.rarity-legendary .booster-card-inner {
  background: linear-gradient(160deg, rgba(80, 50, 15, 0.6), rgba(15, 23, 42, 0.9));
  border: 1px solid rgba(245, 158, 11, 0.4);
}

.booster-card.is-equipped .booster-card-inner {
  box-shadow: inset 0 0 40px rgba(168, 85, 247, 0.06);
}

/* Card Top */
.booster-card-top {
  display: flex;
  align-items: center;
  gap: 14px;
}

.booster-icon-wrapper {
  position: relative;
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.booster-icon { font-size: 24px; }

.rarity-icon-common {
  background: rgba(148, 163, 184, 0.12);
  border: 1px solid rgba(148, 163, 184, 0.2);
}
.rarity-icon-rare {
  background: rgba(59, 130, 246, 0.15);
  border: 1px solid rgba(59, 130, 246, 0.3);
  box-shadow: 0 0 16px rgba(59, 130, 246, 0.15);
}
.rarity-icon-epic {
  background: rgba(168, 85, 247, 0.15);
  border: 1px solid rgba(168, 85, 247, 0.3);
  box-shadow: 0 0 16px rgba(168, 85, 247, 0.15);
}
.rarity-icon-legendary {
  background: rgba(245, 158, 11, 0.15);
  border: 1px solid rgba(245, 158, 11, 0.35);
  box-shadow: 0 0 16px rgba(245, 158, 11, 0.2);
}

.booster-meta {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}

.booster-meta h3 {
  font-size: 16px;
  font-weight: 700;
  color: white;
  margin: 0;
}

.booster-rarity-tag {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 5px;
  font-size: 9px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 1px;
  width: fit-content;
}

.tag-common {
  background: rgba(148, 163, 184, 0.15);
  color: #94a3b8;
  border: 1px solid rgba(148, 163, 184, 0.25);
}
.tag-rare {
  background: rgba(59, 130, 246, 0.15);
  color: #60a5fa;
  border: 1px solid rgba(59, 130, 246, 0.3);
}
.tag-epic {
  background: rgba(168, 85, 247, 0.15);
  color: #c084fc;
  border: 1px solid rgba(168, 85, 247, 0.3);
}
.tag-legendary {
  background: rgba(245, 158, 11, 0.15);
  color: #fbbf24;
  border: 1px solid rgba(245, 158, 11, 0.35);
}

.booster-desc {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.4);
  margin: 0;
  line-height: 1.4;
}

.booster-stat-row {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
}

.booster-stat {
  display: flex;
  align-items: center;
  gap: 5px;
  padding: 4px 10px;
  border-radius: 8px;
  font-size: 12px;
  font-weight: 700;
}

.booster-stat.xp {
  background: rgba(59, 130, 246, 0.1);
  color: #60a5fa;
  border: 1px solid rgba(59, 130, 246, 0.2);
}

.booster-stat.coin {
  background: rgba(251, 191, 36, 0.1);
  color: #fbbf24;
  border: 1px solid rgba(251, 191, 36, 0.2);
}

/* Card Footer */
.booster-card-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding-top: 8px;
  border-top: 1px solid rgba(255, 255, 255, 0.04);
}

.equipped-badge {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 5px 12px;
  background: rgba(168, 85, 247, 0.15);
  border: 1px solid rgba(168, 85, 247, 0.35);
  border-radius: 8px;
  font-size: 11px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  color: #a855f7;
}

.equip-btn,
.unequip-btn {
  padding: 9px 18px;
  border-radius: 10px;
  border: none;
  font-weight: 600;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 6px;
  margin-left: auto;
}

.equip-btn {
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  color: white;
  box-shadow: 0 4px 12px rgba(236, 72, 153, 0.3);
}

.equip-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 18px rgba(236, 72, 153, 0.4);
}

.unequip-btn {
  background: rgba(255, 255, 255, 0.05);
  color: rgba(255, 255, 255, 0.5);
  border: 1px solid rgba(255, 255, 255, 0.08);
}

.unequip-btn:hover {
  background: rgba(239, 68, 68, 0.12);
  border-color: rgba(239, 68, 68, 0.35);
  color: #f87171;
}

.booster-qty-badge {
  position: absolute;
  top: -4px;
  right: -4px;
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  color: white;
  font-size: 10px;
  font-weight: 800;
  padding: 2px 6px;
  border-radius: 999px;
  line-height: 1.2;
  box-shadow: 0 2px 6px rgba(236, 72, 153, 0.4);
}

.booster-qty-row {
  margin-top: 6px;
  margin-bottom: 2px;
}

.booster-qty-label {
  font-size: 11px;
  font-weight: 600;
  color: rgba(168, 85, 247, 0.8);
  background: rgba(168, 85, 247, 0.1);
  padding: 3px 10px;
  border-radius: 6px;
  border: 1px solid rgba(168, 85, 247, 0.2);
}

/* ══════════════════════════════
   RESPONSIVE
══════════════════════════════ */
/* Custom scrollbar for inventory */
.inventory-panel::-webkit-scrollbar {
  width: 6px;
}

.inventory-panel::-webkit-scrollbar-track {
  background: transparent;
}

.inventory-panel::-webkit-scrollbar-thumb {
  background: rgba(168, 85, 247, 0.25);
  border-radius: 3px;
}

.inventory-panel::-webkit-scrollbar-thumb:hover {
  background: rgba(168, 85, 247, 0.45);
}

@media (max-width: 1024px) {
  .equip-layout {
    gap: 28px;
  }
}

@media (max-width: 900px) {
  .equip-layout {
    grid-template-columns: 1fr;
    gap: 32px;
  }

  .avatar-panel {
    position: static;
  }

  .avatar-section {
    margin-bottom: 0;
  }

  .inventory-panel {
    max-height: 50vh;
    padding-right: 0;
  }
}

@media (max-width: 768px) {
  .main-content {
    padding: 24px 16px;
  }

  .boost-stats {
    flex-direction: column;
    gap: 12px;
  }

  .boost-card {
    padding: 16px 20px;
  }

  .equip-slot {
    width: 80px;
    height: 80px;
  }

  .equip-slot-inner::before,
  .equip-slot-inner::after {
    width: 7px;
    height: 7px;
  }

  .inventory-panel {
    max-height: 45vh;
  }
}

@media (max-width: 600px) {
  .main-content {
    padding: 20px 12px;
  }

  .avatar-row {
    gap: 6px;
  }

  .equip-slot {
    width: 64px;
    height: 64px;
  }

  .equip-name { display: none; }
  .equip-empty { display: none; }
  .equip-badge { display: none; }
  .equip-select-hint { display: none; }

  .avatar-sprite {
    transform: scale(0.75);
    transform-origin: center bottom;
    margin-left: -110px;
    margin-right: -110px;
    margin-top: -70px;
  }

  .avatar-ground {
    width: 110px;
    height: 14px;
    margin-top: -28px;
  }

  .avatar-glow-bg {
    width: 180px;
    height: 260px;
  }

  .username-clean {
    font-size: 12px;
    letter-spacing: 2px;
    margin-bottom: 12px;
  }

  .section-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 8px;
  }

  .section-title h2 {
    font-size: 18px;
  }

  .slot-select-banner {
    font-size: 11px;
    padding: 8px 12px;
    flex-wrap: wrap;
    gap: 6px;
  }

  .booster-card-inner {
    padding: 14px;
  }

  .booster-meta h3 {
    font-size: 14px;
  }

  .booster-desc {
    font-size: 12px;
  }

  .equip-btn, .unequip-btn {
    padding: 8px 14px;
    font-size: 12px;
  }

  .inventory-panel {
    max-height: 40vh;
  }
}

@media (max-width: 400px) {
  .equip-slot {
    width: 56px;
    height: 56px;
  }

  .equip-slot-inner::before,
  .equip-slot-inner::after {
    width: 6px;
    height: 6px;
    border-color: rgba(168, 85, 247, 0.3);
  }

  .boost-value {
    font-size: 18px;
  }

  .boost-label {
    font-size: 10px;
  }

  .boost-icon-wrap {
    width: 34px;
    height: 34px;
  }
}
</style>