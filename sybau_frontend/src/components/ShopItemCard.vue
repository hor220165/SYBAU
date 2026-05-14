<script setup lang="ts">
import { computed } from 'vue';
import coinIcon from '@/assets/SYBAU_Coin.png';
import xpIcon from '@/assets/XP_Pixel.png';
import type { ShopDisplayItem } from '@/models/ShopDisplayItem';
import { useLanguage } from '@/composables/useLanguage';

const { translate, locale } = useLanguage();

const props = defineProps<{
  item: ShopDisplayItem;
  currentCoins: number;
  busy?: boolean;
}>();

const emit = defineEmits<{
  (e: 'buy', item: ShopDisplayItem): void;
}>();

const canAfford = computed(() => props.currentCoins >= props.item.price);
const canBuy = computed(() => canAfford.value);
const formatPrice = (value: number) => {
  const amount = Number(value || 0);
  const sign = amount < 0 ? '-' : '';
  const absolute = Math.abs(amount);
  if (absolute >= 1_000_000) return `${sign}${Number((absolute / 1_000_000).toFixed(1)).toLocaleString(locale.value)}M`;
  if (absolute >= 10_000) return `${sign}${Number((absolute / 1_000).toFixed(1)).toLocaleString(locale.value)}K`;
  return `${sign}${Math.round(absolute).toLocaleString(locale.value)}`;
};
const priceText = computed(() => formatPrice(props.item.price));
const priceSizeClass = computed(() => {
  if (priceText.value.length >= 7) return 'price-compact';
  if (priceText.value.length >= 5) return 'price-medium';
  return 'price-large';
});
const rarityLabel = computed(() =>
  props.item.rarity === 'mythic' ? 'Mythisch' : translate(props.item.rarity),
);
</script>

<template>
  <article class="shop-item-card" :class="[`rarity-${item.rarity}`, `category-${item.category}`]">
    <div class="card-background"></div>

    <div class="card-content">
      <span v-if="item.ownedQuantity > 0" class="owned-count">
        x{{ item.ownedQuantity }}
      </span>

      <div class="item-main-row">
        <div class="item-icon-shell">
          <img v-if="item.imageUrl" :src="item.imageUrl" alt="" class="item-image" />
          <span v-else class="item-icon">{{ item.icon }}</span>
        </div>

        <div class="title-block">
          <h3>{{ translate(item.name) }}</h3>
          <span class="rarity-label">{{ rarityLabel }}</span>
        </div>
      </div>

      <div v-if="item.xpBoostPercentage > 0 || item.coinBoostPercentage > 0" class="boost-row">
        <span v-if="item.xpBoostPercentage > 0" class="boost-pill xp">
          <img :src="xpIcon" alt="" />
          +{{ item.xpBoostPercentage }}% XP
        </span>
        <span v-if="item.coinBoostPercentage > 0" class="boost-pill coin">
          <img :src="coinIcon" alt="" />
          +{{ item.coinBoostPercentage }}% Coins
        </span>
      </div>

      <div class="item-footer">
        <button
          class="buy-button corner-button"
          :class="{ disabled: !canBuy || busy }"
          :disabled="!canBuy || busy"
          @click="emit('buy', item)"
        >
          <span v-if="busy">...</span>
          <span v-else class="button-price" :class="priceSizeClass">
            <img :src="coinIcon" alt="" class="coin-icon" />
            <span>{{ priceText }}</span>
          </span>
        </button>
      </div>
    </div>
  </article>
</template>

<style scoped>
.shop-item-card {
  position: relative;
  overflow: hidden;
  border-radius: 26px;
  min-height: 300px;
  background: rgba(8, 10, 31, 0.78);
  border: 1px solid rgba(139, 92, 246, 0.18);
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  box-shadow: 0 22px 42px rgba(2, 6, 23, 0.22);
  transition: transform 0.25s ease, border-color 0.25s ease, box-shadow 0.25s ease;
}

.shop-item-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 28px 48px rgba(88, 28, 135, 0.22);
}

.card-background {
  position: absolute;
  inset: 0;
  opacity: 0.22;
  pointer-events: none;
}

.rarity-common .card-background {
  background: linear-gradient(135deg, rgba(100, 116, 139, 0.44), transparent 55%);
}

.rarity-rare .card-background {
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.46), transparent 55%);
}

.rarity-epic .card-background {
  background: linear-gradient(135deg, rgba(168, 85, 247, 0.52), transparent 55%);
}

.rarity-legendary .card-background {
  background: linear-gradient(135deg, rgba(245, 158, 11, 0.48), rgba(249, 115, 22, 0.18) 55%, transparent 70%);
}

.rarity-mythic .card-background {
  background: linear-gradient(135deg, rgba(236, 72, 153, 0.54), rgba(34, 211, 238, 0.2) 48%, transparent 72%);
}

.rarity-common {
  border-color: rgba(148, 163, 184, 0.18);
  --rarity-color: #cbd5e1;
}

.rarity-rare {
  border-color: rgba(59, 130, 246, 0.2);
  --rarity-color: #60a5fa;
}

.rarity-epic {
  border-color: rgba(168, 85, 247, 0.24);
  --rarity-color: #c084fc;
}

.rarity-legendary {
  border-color: rgba(250, 204, 21, 0.3);
  --rarity-color: #fbbf24;
}

.rarity-mythic {
  border-color: rgba(244, 114, 182, 0.34);
  --rarity-color: #f472b6;
}

.card-content {
  position: relative;
  z-index: 1;
  height: 100%;
  display: flex;
  flex-direction: column;
  padding: 22px;
}

.item-main-row {
  display: grid;
  grid-template-columns: 112px minmax(0, 1fr);
  align-items: start;
  gap: 20px;
  padding-right: 54px;
}

.item-icon-shell {
  position: relative;
  width: 112px;
  height: 112px;
  flex-shrink: 0;
  display: grid;
  place-items: center;
  border-radius: 18px;
  background: rgba(2, 6, 23, 0.26);
  border: 1px solid rgba(255, 255, 255, 0.06);
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.025);
}

.item-icon-shell::before,
.item-icon-shell::after {
  content: '';
  position: absolute;
  width: 12px;
  height: 12px;
  pointer-events: none;
}

.item-icon-shell::before {
  left: 9px;
  top: 9px;
  border-left: 1px solid rgba(255, 255, 255, 0.3);
  border-top: 1px solid rgba(255, 255, 255, 0.3);
}

.item-icon-shell::after {
  right: 9px;
  bottom: 9px;
  border-right: 1px solid rgba(255, 255, 255, 0.2);
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
}

.item-icon {
  font-size: 3.6rem;
}

.item-image {
  width: 86px;
  height: 86px;
  object-fit: contain;
  image-rendering: pixelated;
  filter: drop-shadow(0 12px 18px rgba(0, 0, 0, 0.36));
}

.title-block {
  min-width: 0;
  padding-top: 4px;
}

.title-block h3 {
  margin: 0 0 10px;
  color: white;
  font-size: 1.45rem;
  line-height: 1.08;
  font-weight: 900;
  overflow-wrap: anywhere;
}

.rarity-label {
  display: block;
  color: var(--rarity-color, #f8fafc);
  font-size: 0.78rem;
  font-weight: 900;
  letter-spacing: 0.32em;
  text-transform: uppercase;
  text-shadow: 0 0 14px color-mix(in srgb, var(--rarity-color, #f8fafc) 35%, transparent);
}

.boost-row {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-top: 34px;
  padding-bottom: 28px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
}

.boost-pill {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  min-height: 38px;
  padding: 0 12px;
  border-radius: 11px;
  font-size: 0.94rem;
  font-weight: 900;
}

.boost-pill img {
  width: 19px;
  height: 19px;
  object-fit: contain;
  image-rendering: pixelated;
}

.boost-pill.xp {
  background: rgba(37, 99, 235, 0.18);
  border: 1px solid rgba(59, 130, 246, 0.38);
  color: #60a5fa;
}

.boost-pill.coin {
  background: rgba(245, 158, 11, 0.16);
  border: 1px solid rgba(245, 158, 11, 0.38);
  color: #facc15;
}

.item-footer {
  margin-top: auto;
  padding-top: 22px;
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  align-items: center;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
}

.coin-icon {
  width: 20px;
  height: 20px;
  object-fit: contain;
  image-rendering: pixelated;
  flex: 0 0 auto;
}

.corner-button {
  position: relative;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  border-radius: 10px;
  padding: 12px clamp(14px, 1.4vw, 20px);
  min-width: clamp(92px, 7.5vw, 124px);
  width: max-content;
  max-width: 100%;
  color: white;
  font-weight: 900;
  cursor: pointer;
  overflow: hidden;
  transition: transform 0.18s ease, border-color 0.18s ease, filter 0.18s ease;
}

.corner-button::before,
.corner-button::after {
  content: '';
  position: absolute;
  width: 10px;
  height: 10px;
  pointer-events: none;
}

.corner-button::before {
  top: 5px;
  left: 5px;
  border-top: 1px solid rgba(255, 255, 255, 0.42);
  border-left: 1px solid rgba(255, 255, 255, 0.42);
}

.corner-button::after {
  right: 5px;
  bottom: 5px;
  border-right: 1px solid rgba(255, 255, 255, 0.28);
  border-bottom: 1px solid rgba(255, 255, 255, 0.28);
}

.buy-button {
  background:
    linear-gradient(135deg, rgba(34, 197, 94, 0.24), rgba(20, 83, 45, 0.86)),
    rgba(6, 78, 59, 0.7);
  border-color: rgba(74, 222, 128, 0.42);
  box-shadow: 0 16px 28px rgba(22, 163, 74, 0.16), inset 0 0 20px rgba(34, 197, 94, 0.08);
}

.button-price {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-weight: 900;
  font-size: var(--price-font-size, 1.05rem);
  line-height: 1;
  white-space: nowrap;
  max-width: 100%;
}

.button-price.price-large {
  --price-font-size: 1.08rem;
}

.button-price.price-medium {
  --price-font-size: 0.98rem;
}

.button-price.price-compact {
  --price-font-size: 0.88rem;
  gap: 5px;
}

.button-price span {
  display: inline-block;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
}

.corner-button:hover:not(:disabled) {
  transform: translateY(-1px);
  filter: brightness(1.08);
}

.corner-button:disabled,
.buy-button.disabled {
  background: rgba(30, 41, 59, 0.72);
  border-color: rgba(148, 163, 184, 0.18);
  color: rgba(255, 255, 255, 0.62);
  box-shadow: none;
  cursor: not-allowed;
}

@media (max-width: 560px) {
  .rarity-label {
    display: none;
  }

  .card-top-row,
  .item-footer {
    flex-direction: column;
    align-items: stretch;
  }

  .item-badges {
    align-items: flex-start;
  }

  .corner-button {
    width: 100%;
  }
}

.owned-count {
  position: absolute;
  right: 22px;
  top: 22px;
  display: inline-flex;
  align-items: center;
  color: #f9a8d4;
  font-size: 1rem;
  font-weight: 900;
  letter-spacing: 0;
  z-index: 2;
  text-shadow: 0 0 14px rgba(236, 72, 153, 0.42);
}

</style>
