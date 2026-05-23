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
          <img :src="xpIcon" alt="" />
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
          <img :src="coinIcon" alt="" />
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
                  :class="[
                    equipSlotRarityClass(slot),
                    {
                      empty: !slot.item,
                      equipped: !!slot.item,
                      'slot-highlight': selectingSlotFor !== null
                    }
                  ]"
                  @click="handleSlotClick(i)"
                >
                  <div class="equip-item-icon" v-if="slot.item">
                    <img v-if="slot.item.imageUrl" :src="slot.item.imageUrl" alt="" />
                    <span v-else>{{ slot.item.icon }}</span>
                  </div>
                  <span class="equip-empty" v-if="!slot.item && selectingSlotFor === null">{{ text('Leer', 'Empty') }}</span>
                  <span class="equip-select-hint" v-if="!slot.item && selectingSlotFor !== null">{{ text('Hier', 'Here') }}</span>
                  <div class="equip-badges" v-if="slot.item">
                    <span v-if="slot.item.xpBoost > 0" class="equip-badge xp">+{{ slot.item.xpBoost }}%</span>
                    <span v-if="slot.item.coinBoost > 0" class="equip-badge coin">+{{ slot.item.coinBoost }}%</span>
                  </div>
                </div>
              </div>
            </div>

            <div class="avatar-wrapper">
              <div class="avatar-sprite">
                <SpriteAnimator
                  :bodyStage="bodyStage"
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
                  :class="[
                    equipSlotRarityClass(slot),
                    {
                      empty: !slot.item,
                      equipped: !!slot.item,
                      'slot-highlight': selectingSlotFor !== null
                    }
                  ]"
                  @click="handleSlotClick(i + 2)"
                >
                  <div class="equip-item-icon" v-if="slot.item">
                    <img v-if="slot.item.imageUrl" :src="slot.item.imageUrl" alt="" />
                    <span v-else>{{ slot.item.icon }}</span>
                  </div>
                  <span class="equip-empty" v-if="!slot.item && selectingSlotFor === null">{{ text('Leer', 'Empty') }}</span>
                  <span class="equip-select-hint" v-if="!slot.item && selectingSlotFor !== null">{{ text('Hier', 'Here') }}</span>
                  <div class="equip-badges" v-if="slot.item">
                    <span v-if="slot.item.xpBoost > 0" class="equip-badge xp">+{{ slot.item.xpBoost }}%</span>
                    <span v-if="slot.item.coinBoost > 0" class="equip-badge coin">+{{ slot.item.coinBoost }}%</span>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Slot selection banner -->
          <Transition name="fade">
            <div v-if="selectingSlotFor !== null" class="slot-select-banner">
              <Zap :size="16" />
              <span>{{ text('Wähle einen Slot für', 'Choose a slot for') }} <strong>{{ translate(selectingSlotFor.name) }}</strong></span>
              <button class="cancel-select" @click="selectingSlotFor = null">{{ text('Abbrechen', 'Cancel') }}</button>
            </div>
          </Transition>
        </div>
      </div>

      <!-- RIGHT: Booster Inventory -->
      <div class="inventory-panel">
        <div class="section-header">
          <div class="section-title">
            <h2>{{ text('Inventar', 'Inventory') }}</h2>
          </div>
          <span class="inventory-count">{{ inventory.reduce((sum, b) => sum + b.quantity, 0) }} Booster ({{ inventory.length }} {{ text('verschiedene', 'different') }})</span>
        </div>

        <div v-if="availableBoosters.length === 0" class="empty-inventory">
          <ShoppingBag :size="48" class="empty-icon" />
          <p>{{ text('Keine Booster vorhanden', 'No boosters available') }}</p>
          <span>{{ text('Kaufe Booster im Shop!', 'Buy boosters in the shop!') }}</span>
          <button class="shop-btn" @click="$router.push('/shop')">{{ text('Zum Shop', 'Go to Shop') }}</button>
        </div>

        <div v-else class="booster-list inventory-grid">
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
              <span class="booster-qty-badge">{{ remainingCount(booster) }}/{{ booster.quantity }}</span>
              <div class="booster-card-top">
                <div class="booster-icon-wrapper" :class="'rarity-icon-' + booster.rarity">
                  <img v-if="booster.imageUrl" :src="booster.imageUrl" alt="" class="booster-image" />
                  <span v-else class="booster-icon">{{ booster.icon }}</span>
                </div>
                <div class="booster-meta">
                  <h3>{{ translate(booster.name) }}</h3>
                  <div class="booster-rarity-tag" :class="'tag-' + booster.rarity">{{ rarityLabel(booster.rarity) }}</div>
                </div>
              </div>

              <div class="booster-stat-row">
                <div v-if="booster.xpBoost" class="booster-stat xp">
                  <img :src="xpIcon" alt="" />
                  <span>+{{ booster.xpBoost }}% XP</span>
                </div>
                <div v-if="booster.coinBoost" class="booster-stat coin">
                  <img :src="coinIcon" alt="" />
                  <span>+{{ booster.coinBoost }}% Coins</span>
                </div>
              </div>

              <div class="booster-card-footer">
                <button
                  class="sell-inventory-btn"
                  type="button"
                  @click="requestSellBooster(booster)"
                >
                  {{ text('Verkauf', 'Sell') }}
                </button>
                <button
                  class="equip-btn"
                  :class="{ disabled: !canEquipMore(booster) }"
                  :disabled="!canEquipMore(booster)"
                  @click="startEquip(booster)"
                >
                  <Zap v-if="canEquipMore(booster)" :size="14" />
                  <Shield v-else :size="14" />
                  {{ canEquipMore(booster) ? text('Ausrüsten', 'Equip') : text('Ausgerüstet', 'Equipped') }}
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

    </div>

    <Transition name="confirm-pop">
      <div v-if="pendingSell" class="confirm-overlay" @click.self="pendingSell = null">
        <div class="confirm-dialog">
          <h3>{{ text('Bist du sicher?', 'Are you sure?') }}</h3>
          <p>{{ translate(pendingSell.name) }} {{ text('verkaufen', 'sell') }}</p>
          <div v-if="pendingSell.quantity > 1" class="confirm-stepper" role="group" :aria-label="text('Menge', 'Quantity')">
            <button
              class="confirm-stepper-btn"
              type="button"
              :disabled="pendingSellQuantity <= 1"
              @click="adjustPendingSellQuantity(-1)"
            >
              <Minus :size="16" />
            </button>
            <strong>{{ pendingSellQuantity }}x</strong>
            <button
              class="confirm-stepper-btn"
              type="button"
              :disabled="pendingSellQuantity >= pendingSell.quantity"
              @click="adjustPendingSellQuantity(1)"
            >
              <Plus :size="16" />
            </button>
          </div>
          <div class="confirm-price">
            <span>{{ text('Du bekommst', 'You get') }}</span>
            <strong>
              <img :src="coinIcon" alt="" />
              {{ pendingSellPrice }}
            </strong>
          </div>
          <div class="confirm-actions">
            <button class="confirm-cancel" type="button" @click="pendingSell = null">{{ text('Abbrechen', 'Cancel') }}</button>
            <button class="confirm-sell" type="button" :disabled="sellingBoosterId === pendingSell.id" @click="confirmSellBooster">
              {{ sellingBoosterId === pendingSell.id ? '...' : text('Verkaufen', 'Sell') }}
            </button>
          </div>
        </div>
      </div>
    </Transition>

    <Teleport to="body">
      <MessagePopup
        v-if="popupMessage"
        :message="popupMessage"
        :type="popupType"
        @close="popupMessage = ''"
      />
    </Teleport>
  </main>

  <!-- Footer -->
  <FooterComponent />
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { Zap, ShoppingBag, Shield, Minus, Plus } from 'lucide-vue-next';
import Header from '@/components/Header.vue';
import Navbar from '@/components/Navbar.vue';
import SpriteAnimator from '@/components/spriteAnimator.vue';
import FooterComponent from '@/components/FooterComponent.vue';
import MessagePopup from '@/components/MessagePopup.vue';
import { itemService, resolveMediaUrl, userService } from '@/services/api';
import { useAuth } from '@/composables/useAuth';
import { useLanguage } from '@/composables/useLanguage';
import xpIcon from '@/assets/XP_Pixel.png';
import coinIcon from '@/assets/SYBAU_Coin.png';

const { refreshProfile } = useAuth();
const { text, translate } = useLanguage();
const userName = ref('');
const bodyStage = ref('skinny');

interface BoosterItem {
  id: number;
  name: string;
  icon: string;
  imageUrl: string;
  description: string;
  xpBoost: number;
  coinBoost: number;
  rarity: 'common' | 'rare' | 'epic' | 'legendary' | 'mythic';
  quantity: number;
  price: number;
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
const pendingSell = ref<BoosterItem | null>(null);
const pendingSellQuantity = ref(1);
const sellingBoosterId = ref<number | null>(null);
const popupMessage = ref('');
const popupType = ref<'success' | 'error'>('success');

// Rarity basierend auf Gesamt-Boost ableiten
function getRarity(xp: number, coin: number): 'common' | 'rare' | 'epic' | 'legendary' | 'mythic' {
  const total = xp + coin;
  if (total >= 100) return 'mythic';
  if (total >= 60) return 'legendary';
  if (total >= 40) return 'epic';
  if (total >= 20) return 'rare';
  return 'common';
}

const rarityLabel = (rarity: BoosterItem['rarity']) =>
  rarity === 'mythic' ? 'Mythisch' : translate(rarity);

// Icon basierend auf Boost-Typ ableiten
function getIcon(xp: number, coin: number): string {
  if (xp > 0 && coin > 0) return '🔥';
  if (coin > 0) return '🪙';
  return '⚡';
}

// Backend-Booster in Frontend-Format umwandeln
function mapBooster(b: any): BoosterItem {
  const xp = b.xpBoostPercentage ?? b.xpBoostPercent ?? b.XpBoostPercentage ?? b.XpBoostPercent ?? 0;
  const coin = b.coinBoostPercentage ?? b.coinBoostPercent ?? b.CoinBoostPercentage ?? b.CoinBoostPercent ?? 0;
  const rawRarity = String(b.rarity ?? b.Rarity ?? '').toLowerCase();
  const rarity =
    rawRarity === 'rare' || rawRarity === 'epic' || rawRarity === 'legendary' || rawRarity === 'mythic'
      ? rawRarity
      : getRarity(xp, coin);
  return {
    id: b.id,
    name: b.name,
    icon: getIcon(xp, coin),
    imageUrl: resolveMediaUrl(b.imageUrl ?? b.ImageUrl ?? ''),
    description: b.description ?? '',
    xpBoost: xp,
    coinBoost: coin,
    rarity,
    quantity: b.quantity ?? 1,
    price: Number(b.price ?? b.Price ?? 0)
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

const equipSlotRarityClass = (slot: EquipSlot) =>
  slot.item ? `rarity-${slot.item.rarity}` : 'rarity-empty';

// Kann noch in weitere Slots?
function canEquipMore(booster: BoosterItem): boolean {
  return booster.quantity > equippedCount(booster.id);
}

function remainingCount(booster: BoosterItem): number {
  return Math.max(booster.quantity - equippedCount(booster.id), 0);
}

const sellPriceFor = (booster: BoosterItem) => Math.max(1, Math.floor(Number(booster.price ?? 0) * 0.5));
const pendingSellPrice = computed(() => pendingSell.value ? sellPriceFor(pendingSell.value) * pendingSellQuantity.value : 0);
const pendingSellMaxQuantity = computed(() => pendingSell.value?.quantity ?? 1);

const adjustPendingSellQuantity = (change: number) => {
  const nextQuantity = pendingSellQuantity.value + change;
  pendingSellQuantity.value = Math.min(
    pendingSellMaxQuantity.value,
    Math.max(1, nextQuantity),
  );
};

const requestSellBooster = (booster: BoosterItem) => {
  pendingSell.value = booster;
  pendingSellQuantity.value = 1;
};

const confirmSellBooster = async () => {
  if (!pendingSell.value) return;
  const booster = pendingSell.value;
  const quantity = Math.min(Math.max(1, pendingSellQuantity.value), booster.quantity);
  sellingBoosterId.value = booster.id;

  try {
    const response = await itemService.sellItem(booster.id, quantity);
    const sellPrice = Number(response.data?.sellPrice ?? response.data?.SellPrice ?? sellPriceFor(booster) * quantity);
    pendingSell.value = null;
    pendingSellQuantity.value = 1;
    await loadProfile();
    await refreshProfile();
    popupType.value = 'success';
    popupMessage.value = `${quantity}x ${booster.name} verkauft. +${sellPrice} Coins`;
  } catch (error: any) {
    console.error('Fehler beim Verkaufen des Boosters', error);
    popupType.value = 'error';
    popupMessage.value = error.response?.data?.message
      ?? error.response?.data
      ?? 'Item konnte nicht verkauft werden.';
  } finally {
    sellingBoosterId.value = null;
  }
};

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
    bodyStage.value = avatar.bodyStage ?? 'skinny';
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

.boost-icon-wrap img {
  width: 25px;
  height: 25px;
  object-fit: contain;
  image-rendering: pixelated;
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
  overflow: hidden;
}

/* ══════════════════════════════
   LEFT PANEL — AVATAR
══════════════════════════════ */

.avatar-panel {
  min-width: 0;
  overflow: hidden;
}

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
  --rarity-color: #94a3b8;
  --rarity-bg: rgba(148, 163, 184, 0.12);
  --rarity-border: rgba(148, 163, 184, 0.28);
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
  border: 1px dashed rgba(148, 163, 184, 0.28);
  backdrop-filter: blur(10px);
}

.equip-slot-inner.empty:hover {
  border-color: rgba(148, 163, 184, 0.46);
  background: rgba(148, 163, 184, 0.08);
  transform: translateY(-2px);
  box-shadow: 0 8px 24px rgba(148, 163, 184, 0.12);
}

.equip-slot-inner.slot-highlight.empty {
  border-color: rgba(148, 163, 184, 0.58);
  background: rgba(148, 163, 184, 0.1);
  animation: slotPulse 1.5s ease-in-out infinite;
}

@keyframes slotPulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(148, 163, 184, 0.24); }
  50% { box-shadow: 0 0 20px 4px rgba(148, 163, 184, 0.3); }
}

.equip-slot-inner.equipped {
  background:
    radial-gradient(circle at 50% 30%, color-mix(in srgb, var(--rarity-color) 22%, transparent), transparent 62%),
    var(--rarity-bg);
  border: 1px solid var(--rarity-border);
  backdrop-filter: blur(10px);
  box-shadow: 0 0 20px color-mix(in srgb, var(--rarity-color) 18%, transparent);
  gap: 8px;
}

.equip-slot-inner.equipped:hover {
  background:
    radial-gradient(circle at 50% 30%, color-mix(in srgb, var(--rarity-color) 30%, transparent), transparent 64%),
    color-mix(in srgb, var(--rarity-color) 16%, rgba(15, 23, 42, 0.5));
  transform: translateY(-2px);
  box-shadow: 0 8px 24px color-mix(in srgb, var(--rarity-color) 24%, transparent);
}

.equip-slot-inner::before,
.equip-slot-inner::after {
  content: '';
  position: absolute;
  width: 10px;
  height: 10px;
  border-color: var(--rarity-border);
  border-style: solid;
}

.equip-slot-inner::before {
  top: 6px;
  left: 6px;
  border-width: 1px 0 0 1px;
}

.equip-slot-inner::after {
  top: 6px;
  right: 6px;
  border-width: 1px 1px 0 0;
}

.equip-item-icon {
  font-size: 34px;
  filter: drop-shadow(0 0 8px color-mix(in srgb, var(--rarity-color) 46%, transparent));
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

.equip-slot-inner.equipped .equip-item-icon,
.equip-slot-inner.equipped .equip-item-icon img {
  width: 54px;
  height: 54px;
}

.equip-slot-inner.equipped .equip-item-icon {
  transform: translateY(-7px);
}

.equip-empty {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.28);
  font-weight: 700;
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

.equip-badges {
  position: absolute;
  right: 0;
  bottom: 10px;
  left: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  pointer-events: none;
}

.equip-badge {
  min-width: 0;
  padding: 0;
  font-size: 13px;
  font-weight: 800;
  letter-spacing: 0.2px;
  line-height: 1;
  white-space: nowrap;
  text-shadow: 0 0 9px currentColor;
}

.equip-badge.xp {
  color: #60a5fa;
}

.equip-badge.coin {
  color: #facc15;
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

.section-title h2 {
  font-size: 22px;
  font-weight: 700;
  color: white;
  margin: 0;
}

.inventory-count {
  padding: 0;
  background: transparent;
  border: 0;
  border-radius: 0;
  font-size: 13px;
  font-weight: 700;
  color: #c084fc;
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
   BOOSTER INVENTORY — GAME GRID
══════════════════════════════ */
.booster-list,
.inventory-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 16px;
}

.booster-card {
  position: relative;
  border-radius: 14px;
  overflow: hidden;
  height: auto;
  transition: transform 0.18s ease, filter 0.18s ease;
}

.rarity-common {
  --rarity-color: #cbd5e1;
  --rarity-bg: rgba(148, 163, 184, 0.16);
  --rarity-border: rgba(148, 163, 184, 0.34);
}

.rarity-empty {
  --rarity-color: #94a3b8;
  --rarity-bg: rgba(148, 163, 184, 0.12);
  --rarity-border: rgba(148, 163, 184, 0.28);
}

.rarity-rare {
  --rarity-color: #60a5fa;
  --rarity-bg: rgba(59, 130, 246, 0.17);
  --rarity-border: rgba(59, 130, 246, 0.38);
}

.rarity-epic {
  --rarity-color: #c084fc;
  --rarity-bg: rgba(168, 85, 247, 0.18);
  --rarity-border: rgba(168, 85, 247, 0.42);
}

.rarity-legendary {
  --rarity-color: #fbbf24;
  --rarity-bg: rgba(245, 158, 11, 0.18);
  --rarity-border: rgba(245, 158, 11, 0.42);
}

.rarity-mythic {
  --rarity-color: #f472b6;
  --rarity-bg: rgba(236, 72, 153, 0.18);
  --rarity-border: rgba(244, 114, 182, 0.44);
}

.booster-card:hover {
  transform: translateY(-2px);
  filter: brightness(1.08);
}

.booster-glow {
  position: absolute;
  inset: -2px;
  border-radius: 16px;
  z-index: 0;
  opacity: 0.08;
  transition: opacity 0.35s ease;
}

.booster-card:hover .booster-glow { opacity: 0.18; }

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
.rarity-mythic .booster-glow {
  background: linear-gradient(135deg, rgba(236, 72, 153, 0.5), rgba(34, 211, 238, 0.26));
  box-shadow: 0 0 30px rgba(236, 72, 153, 0.3);
}

.booster-card-inner {
  position: relative;
  z-index: 1;
  display: flex;
  flex-direction: column;
  gap: 12px;
  height: auto;
  padding: 22px;
  border-radius: 22px;
  background: rgba(2, 6, 23, 0.42);
  border: 1px solid rgba(255, 255, 255, 0.075);
  backdrop-filter: blur(14px);
}

.rarity-common .booster-card-inner {
  background: rgba(2, 6, 23, 0.42);
  border-color: rgba(255, 255, 255, 0.075);
}
.rarity-rare .booster-card-inner {
  background: rgba(2, 6, 23, 0.42);
  border-color: rgba(255, 255, 255, 0.075);
}
.rarity-epic .booster-card-inner {
  background: rgba(2, 6, 23, 0.42);
  border-color: rgba(255, 255, 255, 0.075);
}
.rarity-legendary .booster-card-inner {
  background: rgba(2, 6, 23, 0.42);
  border-color: rgba(255, 255, 255, 0.075);
}
.rarity-mythic .booster-card-inner {
  background: rgba(2, 6, 23, 0.42);
  border-color: rgba(255, 255, 255, 0.075);
}

.booster-card.is-equipped .booster-card-inner {
  box-shadow: inset 0 0 40px rgba(168, 85, 247, 0.06);
}

/* Card Top */
.booster-card-top {
  display: flex;
  align-items: flex-start;
  gap: 14px;
}

.booster-icon-wrapper {
  position: relative;
  width: 76px;
  height: 76px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  box-shadow:
    inset 0 0 0 2px rgba(255, 255, 255, 0.04),
    inset 0 -10px 18px rgba(0, 0, 0, 0.22);
}

.booster-icon-wrapper::before,
.booster-icon-wrapper::after {
  content: '';
  position: absolute;
  width: 9px;
  height: 9px;
  pointer-events: none;
}

.booster-icon-wrapper::before {
  left: 6px;
  top: 6px;
  border-left: 1px solid rgba(255, 255, 255, 0.26);
  border-top: 1px solid rgba(255, 255, 255, 0.26);
}

.booster-icon-wrapper::after {
  right: 6px;
  bottom: 6px;
  border-right: 1px solid rgba(255, 255, 255, 0.18);
  border-bottom: 1px solid rgba(255, 255, 255, 0.18);
}

.booster-icon {
  font-size: 42px;
  line-height: 1;
  image-rendering: pixelated;
  filter: drop-shadow(0 4px 8px rgba(0, 0, 0, 0.35));
}

.booster-image {
  width: 64px;
  height: 64px;
  object-fit: contain;
  image-rendering: pixelated;
  filter: drop-shadow(0 5px 10px rgba(0, 0, 0, 0.35));
}

.rarity-icon-common {
  background: var(--rarity-bg);
  border: 1px solid var(--rarity-border);
}
.rarity-icon-rare {
  background: var(--rarity-bg);
  border: 1px solid var(--rarity-border);
  box-shadow: 0 0 16px rgba(59, 130, 246, 0.15);
}
.rarity-icon-epic {
  background: var(--rarity-bg);
  border: 1px solid var(--rarity-border);
  box-shadow: 0 0 16px rgba(168, 85, 247, 0.15);
}
.rarity-icon-legendary {
  background: var(--rarity-bg);
  border: 1px solid var(--rarity-border);
  box-shadow: 0 0 16px rgba(245, 158, 11, 0.2);
}
.rarity-icon-mythic {
  background: var(--rarity-bg);
  border: 1px solid var(--rarity-border);
  box-shadow: 0 0 16px rgba(236, 72, 153, 0.2);
}

.booster-meta {
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-width: 0;
  padding-top: 2px;
}

.booster-meta h3 {
  font-size: 17px;
  line-height: 1.18;
  font-weight: 800;
  color: white;
  margin: 0;
  overflow-wrap: anywhere;
}

.booster-rarity-tag {
  display: inline-block;
  padding: 0;
  border-radius: 0;
  font-size: 8px;
  font-weight: 800;
  text-transform: uppercase;
  letter-spacing: 1.2px;
  width: fit-content;
  background: transparent;
  color: var(--rarity-color);
  border: 0;
  text-shadow: 0 0 12px color-mix(in srgb, var(--rarity-color) 45%, transparent);
}

.tag-common { color: #cbd5e1; }
.tag-rare { color: #60a5fa; }
.tag-epic { color: #c084fc; }
.tag-legendary { color: #fbbf24; }
.tag-mythic { color: #f472b6; }

.booster-stat-row {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  min-height: 28px;
}

.booster-stat {
  display: flex;
  align-items: center;
  gap: 5px;
  padding: 4px 8px;
  border-radius: 7px;
  font-size: 11px;
  font-weight: 800;
}

.booster-stat img {
  width: 16px;
  height: 16px;
  object-fit: contain;
  image-rendering: pixelated;
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
  gap: 8px;
  margin-top: auto;
  padding-top: 9px;
  border-top: 1px solid rgba(255, 255, 255, 0.04);
}

.sell-inventory-btn {
  min-height: 34px;
  padding: 0 11px;
  border-radius: 9px;
  border: 1px solid rgba(248, 113, 113, 0.42);
  background:
    linear-gradient(135deg, rgba(248, 113, 113, 0.2), rgba(127, 29, 29, 0.82)),
    rgba(69, 10, 10, 0.74);
  color: #fecaca;
  font-weight: 900;
  font-size: 12px;
  cursor: pointer;
  box-shadow: inset 0 0 16px rgba(248, 113, 113, 0.07);
  transition: transform 0.18s ease, filter 0.18s ease;
}

.sell-inventory-btn:hover {
  transform: translateY(-1px);
  filter: brightness(1.08);
}

.equip-btn {
  min-height: 34px;
  padding: 0 11px;
  border-radius: 9px;
  border: none;
  font-weight: 800;
  font-size: 12px;
  cursor: pointer;
  transition: all 0.3s ease;
  display: flex;
  align-items: center;
  gap: 6px;
  margin-left: auto;
  background: linear-gradient(135deg, #ec4899, #f43f5e);
  color: white;
  box-shadow: 0 4px 12px rgba(236, 72, 153, 0.3);
}

.equip-btn:hover {
  transform: translateY(-1px);
  box-shadow: 0 6px 18px rgba(236, 72, 153, 0.4);
}

.equip-btn.disabled,
.equip-btn:disabled {
  background: rgba(71, 85, 105, 0.5);
  border: 1px solid rgba(148, 163, 184, 0.14);
  color: rgba(255, 255, 255, 0.46);
  box-shadow: none;
  cursor: default;
}

.equip-btn.disabled:hover,
.equip-btn:disabled:hover {
  transform: none;
  box-shadow: none;
}

.confirm-overlay {
  position: fixed;
  inset: 0;
  z-index: 10020;
  display: grid;
  place-items: center;
  padding: 20px;
  background: rgba(0, 0, 0, 0.68);
  backdrop-filter: blur(8px);
}

.confirm-dialog {
  width: min(360px, 92vw);
  padding: 22px;
  border-radius: 18px;
  background: rgba(15, 23, 42, 0.96);
  border: 1px solid rgba(248, 113, 113, 0.28);
  box-shadow: 0 26px 60px rgba(0, 0, 0, 0.42);
}

.confirm-dialog h3 {
  margin: 0;
  color: white;
  font-size: 1.25rem;
  font-weight: 900;
}

.confirm-dialog p {
  margin: 8px 0 16px;
  color: rgba(255, 255, 255, 0.68);
  font-weight: 800;
}

.confirm-stepper {
  display: grid;
  grid-template-columns: 42px 1fr 42px;
  align-items: center;
  gap: 8px;
  margin-bottom: 12px;
  padding: 6px;
  border-radius: 14px;
  background: rgba(2, 6, 23, 0.42);
  border: 1px solid rgba(255, 255, 255, 0.08);
}

.confirm-stepper strong {
  color: white;
  text-align: center;
  font-size: 1.06rem;
  font-weight: 900;
}

.confirm-stepper-btn {
  width: 42px;
  height: 38px;
  display: grid;
  place-items: center;
  border-radius: 10px;
  border: 1px solid rgba(248, 113, 113, 0.36);
  color: white;
  background: rgba(248, 113, 113, 0.18);
  cursor: pointer;
}

.confirm-stepper-btn:disabled {
  opacity: 0.38;
  cursor: not-allowed;
  background: rgba(30, 41, 59, 0.62);
  border-color: rgba(148, 163, 184, 0.18);
}

.confirm-price {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  padding: 12px 14px;
  border-radius: 12px;
  background: rgba(2, 6, 23, 0.48);
  border: 1px solid rgba(255, 255, 255, 0.08);
}

.confirm-price span {
  color: rgba(255, 255, 255, 0.58);
  font-weight: 800;
}

.confirm-price strong {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  color: #f8fafc;
  font-weight: 900;
  line-height: 1;
}

.confirm-price img {
  width: 20px;
  height: 20px;
  object-fit: contain;
  image-rendering: pixelated;
}

.confirm-actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  margin-top: 18px;
}

.confirm-actions button {
  min-height: 44px;
  border-radius: 11px;
  font-weight: 900;
  cursor: pointer;
}

.confirm-cancel {
  border: 1px solid rgba(148, 163, 184, 0.22);
  background: rgba(30, 41, 59, 0.76);
  color: rgba(255, 255, 255, 0.72);
}

.confirm-sell {
  border: 1px solid rgba(248, 113, 113, 0.42);
  background: linear-gradient(135deg, rgba(248, 113, 113, 0.24), rgba(127, 29, 29, 0.86));
  color: white;
}

.confirm-sell:disabled {
  opacity: 0.65;
  cursor: wait;
}

.confirm-pop-enter-active,
.confirm-pop-leave-active {
  transition: opacity 0.18s ease;
}

.confirm-pop-enter-active .confirm-dialog,
.confirm-pop-leave-active .confirm-dialog {
  transition: transform 0.18s ease;
}

.confirm-pop-enter-from,
.confirm-pop-leave-to {
  opacity: 0;
}

.confirm-pop-enter-from .confirm-dialog,
.confirm-pop-leave-to .confirm-dialog {
  transform: translateY(12px) scale(0.96);
}

.booster-qty-badge {
  position: absolute;
  top: 22px;
  right: 24px;
  z-index: 2;
  background: transparent;
  border: 0;
  color: #f9a8d4;
  font-size: 13px;
  font-weight: 800;
  min-width: 0;
  padding: 0;
  border-radius: 0;
  line-height: 1.2;
  box-shadow: none;
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
    grid-template-columns: minmax(0, 340px) 1fr;
    gap: 24px;
  }

  .avatar-panel {
    max-width: 340px;
  }
}

@media (max-width: 900px) {
  .equip-layout {
    grid-template-columns: 1fr;
    gap: 32px;
  }

  .avatar-panel {
    position: static;
    justify-self: center;
    width: 100%;
    max-width: none;
  }

  .avatar-section {
    margin-bottom: 0;
  }

  .inventory-panel {
    max-height: 50vh;
    padding-right: 0;
  }

  .equip-slot {
    width: 112px;
    height: 112px;
  }

  .equip-slot-inner.equipped .equip-item-icon,
  .equip-slot-inner.equipped .equip-item-icon img {
    width: 54px;
    height: 54px;
  }

  .equip-slot-inner.equipped .equip-item-icon {
    font-size: 38px;
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
    width: 104px;
    height: 104px;
  }

  .equip-slot-inner.equipped .equip-item-icon,
  .equip-slot-inner.equipped .equip-item-icon img {
    width: 52px;
    height: 52px;
  }

  .equip-slot-inner.equipped .equip-item-icon {
    font-size: 36px;
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
    width: 100%;
    gap: 8px;
  }

  .equip-slot {
    width: clamp(76px, 20vw, 92px);
    height: clamp(76px, 20vw, 92px);
  }

  .equip-slot-inner.equipped .equip-item-icon,
  .equip-slot-inner.equipped .equip-item-icon img {
    width: 42px;
    height: 42px;
  }

  .equip-slot-inner.equipped .equip-item-icon {
    font-size: 30px;
  }

  .equip-name { display: none; }
  .equip-empty { display: none; }
  .equip-select-hint { display: none; }

  .equip-badge {
    font-size: 10px;
  }

  .avatar-sprite {
    display: flex;
    justify-content: center;
    width: clamp(184px, 52vw, 220px);
    margin-top: -28px;
  }

  .avatar-sprite :deep(canvas) {
    width: clamp(184px, 52vw, 220px);
    height: clamp(184px, 52vw, 220px);
  }

  .avatar-ground {
    width: 110px;
    height: 14px;
    margin-top: -34px;
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

  .inventory-grid {
    grid-template-columns: 1fr;
  }

  .booster-meta h3 {
    font-size: 14px;
  }

  .equip-btn {
    padding: 8px 14px;
    font-size: 12px;
  }

  .inventory-panel {
    max-height: 40vh;
  }
}

@media (max-width: 400px) {
  .equip-slot {
    width: 72px;
    height: 72px;
  }

  .equip-slot-inner.equipped .equip-item-icon,
  .equip-slot-inner.equipped .equip-item-icon img {
    width: 36px;
    height: 36px;
  }

  .equip-slot-inner.equipped .equip-item-icon {
    font-size: 26px;
  }

  .equip-badges {
    bottom: 8px;
    gap: 5px;
  }

  .equip-badge {
    font-size: 9px;
  }

  .equip-slot-inner::before,
  .equip-slot-inner::after {
    width: 6px;
    height: 6px;
    border-color: var(--rarity-border);
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
