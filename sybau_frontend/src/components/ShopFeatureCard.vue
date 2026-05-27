<script setup lang="ts">
import { computed } from 'vue';
import coinIcon from '@/assets/SYBAU_Coin.png';
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
  <article class="feature-card" :class="[`rarity-${item.rarity}`]">
    <span v-if="item.ownedQuantity > 0" class="feature-count">
      x{{ item.ownedQuantity }}
    </span>

    <div class="feature-main-row">
      <div class="feature-icon">
        <img v-if="item.imageUrl" :src="item.imageUrl" alt="" class="feature-image" />
        <span v-else>{{ item.icon }}</span>
      </div>

      <div class="feature-copy">
        <h4 class="feature-title">{{ translate(item.name) }}</h4>
        <span class="rarity-label">{{ rarityLabel }}</span>
      </div>
    </div>

    <div v-if="item.xpBoostPercentage > 0 || item.coinBoostPercentage > 0" class="boost-row">
      <span v-if="item.xpBoostPercentage > 0" class="boost-pill xp">
        +{{ item.xpBoostPercentage }}% XP
      </span>
      <span v-if="item.coinBoostPercentage > 0" class="boost-pill coin">
        +{{ item.coinBoostPercentage }}% Coins
      </span>
    </div>

    <div class="feature-price-row">
      <button
        class="feature-buy-btn corner-button"
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
  </article>
</template>

<style scoped>
.feature-card {
  position: relative;
  overflow: hidden;
  border-radius: 24px;
  min-height: 300px;
  padding: 22px;
  background: rgba(8, 10, 31, 0.78);
  border: 1px solid rgba(139, 92, 246, 0.18);
  box-shadow: 0 20px 40px rgba(2, 6, 23, 0.22);
  display: flex;
  flex-direction: column;
}

.feature-card::before {
  content: '';
  position: absolute;
  inset: 0;
  opacity: 0.42;
  pointer-events: none;
}

.rarity-common::before {
  background: linear-gradient(135deg, rgba(148, 163, 184, 0.22), transparent 55%);
}

.rarity-common {
  --rarity-color: #cbd5e1;
}

.rarity-rare::before {
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.24), transparent 55%);
}

.rarity-rare {
  --rarity-color: #60a5fa;
}

.rarity-epic::before {
  background: linear-gradient(135deg, rgba(168, 85, 247, 0.28), transparent 55%);
}

.rarity-epic {
  --rarity-color: #c084fc;
}

.rarity-legendary::before {
  background: linear-gradient(135deg, rgba(245, 158, 11, 0.28), transparent 55%);
}

.rarity-legendary {
  --rarity-color: #fbbf24;
}

.rarity-mythic::before {
  background: linear-gradient(135deg, rgba(236, 72, 153, 0.34), rgba(34, 211, 238, 0.12) 55%, transparent 72%);
}

.rarity-mythic {
  --rarity-color: #f472b6;
}

.feature-count {
  position: absolute;
  right: 16px;
  top: 16px;
  z-index: 1;
  color: #f9a8d4;
  font-size: 1rem;
  font-weight: 900;
  text-shadow: 0 0 14px rgba(236, 72, 153, 0.42);
}

.feature-main-row,
.feature-copy,
.feature-title,
.feature-price-row {
  position: relative;
  z-index: 1;
}

.feature-main-row {
  display: grid;
  grid-template-columns: 112px minmax(0, 1fr);
  gap: 20px;
  align-items: start;
  padding-right: 54px;
  margin-top: 26px;
}

.feature-icon {
  position: relative;
  width: 112px;
  height: 112px;
  display: grid;
  place-items: center;
  border-radius: 18px;
  background: rgba(2, 6, 23, 0.26);
  border: 1px solid rgba(255, 255, 255, 0.06);
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.025);
  font-size: 3.6rem;
}

.feature-icon::before,
.feature-icon::after {
  content: '';
  position: absolute;
  width: 12px;
  height: 12px;
  pointer-events: none;
}

.feature-icon::before {
  left: 9px;
  top: 9px;
  border-left: 1px solid rgba(255, 255, 255, 0.3);
  border-top: 1px solid rgba(255, 255, 255, 0.3);
}

.feature-icon::after {
  right: 9px;
  bottom: 9px;
  border-right: 1px solid rgba(255, 255, 255, 0.2);
  border-bottom: 1px solid rgba(255, 255, 255, 0.2);
}

.feature-image {
  width: 86px;
  height: 86px;
  object-fit: contain;
  image-rendering: pixelated;
  filter: drop-shadow(0 12px 18px rgba(0, 0, 0, 0.35));
}

.feature-copy {
  min-width: 0;
  padding-top: 4px;
}

.feature-title {
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
  position: relative;
  z-index: 1;
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

.feature-price-row {
  margin-top: auto;
  padding-top: 22px;
  display: flex;
  justify-content: flex-end;
  align-items: center;
  gap: 12px;
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
  border-radius: 8px;
  padding: 12px clamp(14px, 1.4vw, 20px);
  min-width: clamp(92px, 7.5vw, 124px);
  width: max-content;
  max-width: 100%;
  color: white;
  font-weight: 900;
  cursor: pointer;
  overflow: hidden;
  transition: transform 0.18s ease, filter 0.18s ease;
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

.feature-buy-btn {
  background:
    linear-gradient(135deg, rgba(34, 197, 94, 0.24), rgba(20, 83, 45, 0.86)),
    rgba(6, 78, 59, 0.7);
  border-color: rgba(74, 222, 128, 0.42);
  box-shadow: 0 14px 28px rgba(21, 128, 61, 0.16), inset 0 0 20px rgba(34, 197, 94, 0.08);
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
  transform: translateY(-2px);
  filter: brightness(1.08);
}

.corner-button:disabled,
.feature-buy-btn.disabled {
  background: rgba(30, 41, 59, 0.72);
  border-color: rgba(148, 163, 184, 0.18);
  color: rgba(255, 255, 255, 0.62);
  box-shadow: none;
  cursor: not-allowed;
}

@media (max-width: 760px) {
  .feature-card {
    min-height: 274px;
    padding: 18px 8px 8px;
    border-radius: 18px;
  }

  .feature-count {
    top: 6px;
    right: 6px;
    font-size: 0.68rem;
  }

  .feature-main-row {
    display: flex;
    flex-direction: column;
    align-items: stretch;
    gap: 7px;
    margin-top: 0;
    padding-right: 0;
  }

  .feature-icon {
    width: 100%;
    height: 96px;
    border: 0;
    border-radius: 14px;
    background: transparent;
    box-shadow: none;
    font-size: 2.6rem;
  }

  .feature-icon::before,
  .feature-icon::after {
    display: none;
  }

  .feature-image {
    width: 92px;
    height: 92px;
  }

  .feature-copy {
    padding-top: 0;
    text-align: center;
  }

  .feature-title {
    min-height: 30px;
    margin: 0;
    display: -webkit-box;
    overflow: hidden;
    -webkit-box-orient: vertical;
    -webkit-line-clamp: 2;
    font-size: 0.84rem;
    line-height: 1.05;
  }

  .rarity-label {
    margin-top: 5px;
    overflow: hidden;
    text-overflow: ellipsis;
    font-size: 0.58rem;
    letter-spacing: 0.14em;
    white-space: nowrap;
  }

  .boost-row {
    min-height: 38px;
    margin-top: 6px;
    padding-bottom: 0;
    align-content: center;
    justify-content: center;
    gap: 3px;
    border-bottom: 0;
  }

  .boost-pill {
    min-height: auto;
    padding: 0;
    border: 0;
    background: transparent;
    font-size: 0.66rem;
    line-height: 1;
    text-align: center;
  }

  .feature-price-row {
    margin-top: auto;
    padding-top: 6px;
    flex-direction: column;
    align-items: stretch;
  }

  .corner-button {
    width: 100%;
    min-width: 0;
    min-height: 38px;
    justify-content: center;
    padding: 0 6px;
    border-radius: 9px;
  }

  .coin-icon {
    width: 16px;
    height: 16px;
  }

  .button-price {
    gap: 5px;
    --price-font-size: 0.95rem;
  }

  .button-price.price-medium,
  .button-price.price-compact {
    --price-font-size: 0.82rem;
  }
}

</style>
