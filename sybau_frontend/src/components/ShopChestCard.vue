<script setup lang="ts">
import { computed, ref } from 'vue';
import { Info } from 'lucide-vue-next';
import coinIcon from '@/assets/SYBAU_Coin.png';
import type { Chest } from '@/models/Chest';
import { useLanguage } from '@/composables/useLanguage';

const { text, translate, locale } = useLanguage();

const props = defineProps<{
  chest: Chest;
  currentCoins: number;
  busy?: boolean;
}>();

const emit = defineEmits<{
  open: [chest: Chest];
}>();

const showRates = ref(false);
const canAfford = computed(() => props.currentCoins >= Number(props.chest.price ?? 0));
const formatPrice = (value: number) => {
  const amount = Number(value || 0);
  const sign = amount < 0 ? '-' : '';
  const absolute = Math.abs(amount);
  if (absolute >= 1_000_000) return `${sign}${Number((absolute / 1_000_000).toFixed(1)).toLocaleString(locale.value)}M`;
  if (absolute >= 10_000) return `${sign}${Number((absolute / 1_000).toFixed(1)).toLocaleString(locale.value)}K`;
  return `${sign}${Math.round(absolute).toLocaleString(locale.value)}`;
};
const priceText = computed(() => formatPrice(Number(props.chest.price ?? 0)));
const priceSizeClass = computed(() => {
  if (priceText.value.length >= 7) return 'price-compact';
  if (priceText.value.length >= 5) return 'price-medium';
  return 'price-large';
});
</script>

<template>
  <article class="chest-card">
    <div class="chest-bg"></div>
    <button class="info-btn" type="button" @click="showRates = !showRates" :aria-label="text('Drop-Rates anzeigen', 'Show drop rates')">
      <Info :size="18" />
    </button>

    <div class="chest-image-shell">
      <img :src="chest.imageUrl" alt="" class="chest-image" />
    </div>

    <div class="chest-copy">
      <h3>{{ translate(chest.name) }}</h3>
      <p>{{ chest.items?.length ?? 0 }} {{ text('mögliche Items', 'possible items') }}</p>
    </div>

    <div v-if="showRates" class="rates-popover">
      <div class="rate-common"><span>Common</span><strong>{{ chest.commonChance }}%</strong></div>
      <div class="rate-rare"><span>Rare</span><strong>{{ chest.rareChance }}%</strong></div>
      <div class="rate-epic"><span>Epic</span><strong>{{ chest.epicChance }}%</strong></div>
      <div class="rate-legendary"><span>Legendary</span><strong>{{ chest.legendaryChance }}%</strong></div>
      <div class="rate-mythic"><span>Mythisch</span><strong>{{ chest.mythicChance }}%</strong></div>
    </div>

    <button
      class="open-btn"
      :class="{ disabled: !canAfford || busy }"
      :disabled="!canAfford || busy"
      @click="emit('open', chest)"
    >
      <span v-if="busy">...</span>
      <span v-else class="button-price" :class="priceSizeClass">
        <img :src="coinIcon" alt="" />
        <span>{{ priceText }}</span>
      </span>
    </button>
  </article>
</template>

<style scoped>
.chest-card {
  position: relative;
  min-height: 300px;
  overflow: hidden;
  border-radius: 26px;
  padding: 24px;
  display: flex;
  flex-direction: column;
  background: rgba(8, 10, 31, 0.78);
  border: 1px solid rgba(139, 92, 246, 0.2);
  box-shadow: 0 22px 42px rgba(2, 6, 23, 0.22);
}

.chest-bg {
  position: absolute;
  inset: 0;
  pointer-events: none;
  opacity: 0.28;
  background: linear-gradient(135deg, rgba(236, 72, 153, 0.32), rgba(250, 204, 21, 0.12) 45%, transparent 72%);
}

.info-btn {
  position: absolute;
  top: 18px;
  right: 18px;
  z-index: 3;
  width: 32px;
  height: 32px;
  display: grid;
  place-items: center;
  border-radius: 999px;
  border: 0;
  background: rgba(15, 23, 42, 0.58);
  color: #f9a8d4;
  cursor: pointer;
  padding: 0;
  transition: transform 0.18s ease, color 0.18s ease, background 0.18s ease;
}

.info-btn:hover {
  transform: scale(1.08);
  background: rgba(236, 72, 153, 0.12);
  color: #fbcfe8;
}

.info-btn :deep(svg) {
  display: block;
  stroke-width: 2.4;
}

.chest-image-shell {
  position: relative;
  z-index: 1;
  width: 136px;
  height: 136px;
  display: grid;
  place-items: center;
  border-radius: 22px;
  background: rgba(2, 6, 23, 0.3);
  border: 1px solid rgba(255, 255, 255, 0.07);
  box-shadow: inset 0 0 0 2px rgba(255, 255, 255, 0.025);
}

.chest-image {
  width: 112px;
  height: 112px;
  object-fit: contain;
  image-rendering: pixelated;
  filter: drop-shadow(0 16px 20px rgba(0, 0, 0, 0.38));
}

.chest-copy {
  position: relative;
  z-index: 1;
  margin-top: 18px;
}

.chest-copy h3 {
  margin: 0;
  color: white;
  font-size: 1.5rem;
  line-height: 1.05;
  font-weight: 900;
}

.chest-copy p {
  margin: 8px 0 0;
  color: rgba(255, 255, 255, 0.58);
  font-weight: 700;
}

.rates-popover {
  position: absolute;
  right: 18px;
  top: 58px;
  z-index: 4;
  width: 190px;
  padding: 12px;
  border-radius: 16px;
  background: rgba(2, 6, 23, 0.94);
  border: 1px solid rgba(236, 72, 153, 0.28);
  box-shadow: 0 18px 34px rgba(0, 0, 0, 0.35);
}

.rates-popover div {
  display: flex;
  justify-content: space-between;
  font-size: 0.86rem;
  font-weight: 800;
}

.rates-popover div + div {
  margin-top: 7px;
}

.rates-popover span,
.rates-popover strong {
  color: var(--rate-color);
}

.rate-common {
  --rate-color: #cbd5e1;
}

.rate-rare {
  --rate-color: #60a5fa;
}

.rate-epic {
  --rate-color: #c084fc;
}

.rate-legendary {
  --rate-color: #fbbf24;
}

.rate-mythic {
  --rate-color: #f472b6;
}

.open-btn {
  position: relative;
  z-index: 1;
  margin-top: auto;
  align-self: flex-end;
  min-width: clamp(98px, 7.5vw, 132px);
  width: max-content;
  max-width: 100%;
  min-height: 48px;
  padding: 0 clamp(14px, 1.4vw, 20px);
  display: inline-flex;
  justify-content: center;
  align-items: center;
  overflow: hidden;
  border: 1px solid rgba(74, 222, 128, 0.42);
  border-radius: 8px;
  background:
    linear-gradient(135deg, rgba(34, 197, 94, 0.24), rgba(20, 83, 45, 0.86)),
    rgba(6, 78, 59, 0.7);
  color: white;
  font-weight: 900;
  cursor: pointer;
  box-shadow: 0 16px 28px rgba(22, 163, 74, 0.16), inset 0 0 20px rgba(34, 197, 94, 0.08);
  transition: transform 0.18s ease, filter 0.18s ease;
}

.open-btn::before,
.open-btn::after {
  content: '';
  position: absolute;
  width: 10px;
  height: 10px;
  pointer-events: none;
}

.open-btn::before {
  top: 5px;
  left: 5px;
  border-top: 1px solid rgba(255, 255, 255, 0.42);
  border-left: 1px solid rgba(255, 255, 255, 0.42);
}

.open-btn::after {
  right: 5px;
  bottom: 5px;
  border-right: 1px solid rgba(255, 255, 255, 0.28);
  border-bottom: 1px solid rgba(255, 255, 255, 0.28);
}

.open-btn:hover:not(:disabled) {
  transform: translateY(-1px);
  filter: brightness(1.08);
}

.button-price {
  display: inline-flex;
  align-items: center;
  gap: 7px;
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

.button-price img {
  width: 19px;
  height: 19px;
  object-fit: contain;
  image-rendering: pixelated;
}

.open-btn.disabled,
.open-btn:disabled {
  cursor: not-allowed;
  background: rgba(30, 41, 59, 0.72);
  border-color: rgba(148, 163, 184, 0.18);
  color: rgba(255, 255, 255, 0.62);
  box-shadow: none;
}

@media (max-width: 760px) {
  .chest-card {
    min-height: 194px;
    padding: 10px;
    border-radius: 18px;
  }

  .info-btn {
    top: 10px;
    right: 10px;
    width: 28px;
    height: 28px;
  }

  .chest-image-shell {
    width: 100%;
    height: 88px;
    border: 0;
    background: transparent;
    box-shadow: none;
  }

  .chest-image {
    width: 86px;
    height: 86px;
  }

  .chest-copy {
    margin-top: 8px;
    text-align: center;
  }

  .chest-copy h3 {
    font-size: clamp(0.82rem, 3.6vw, 1rem);
    line-height: 1.05;
  }

  .chest-copy p {
    display: none;
  }

  .open-btn {
    align-self: stretch;
    width: 100%;
    min-width: 0;
    min-height: 36px;
    padding: 0 8px;
    border-radius: 8px;
  }

  .button-price {
    gap: 5px;
    font-size: 0.95rem;
  }

  .button-price img {
    width: 16px;
    height: 16px;
  }

  .rates-popover {
    right: 8px;
    top: 44px;
    width: min(190px, calc(100vw - 40px));
  }
}
</style>
