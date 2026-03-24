<script setup lang="ts">
import { computed } from 'vue';
import { Coins, ShoppingBag } from 'lucide-vue-next';
import type { ShopDisplayItem } from '@/models/ShopDisplayItem';

const props = defineProps<{
  item: ShopDisplayItem;
  currentCoins: number;
  busy?: boolean;
  badgeText?: string;
}>();

const emit = defineEmits<{
  (e: 'buy', item: ShopDisplayItem): void;
}>();

const canAfford = computed(() => props.currentCoins >= props.item.price);
const limitReached = computed(() => props.item.ownedQuantity >= props.item.maxQuantity);
const canBuy = computed(() => canAfford.value && !limitReached.value);
</script>

<template>
  <article class="feature-card" :class="[`rarity-${item.rarity}`]">
    <span v-if="badgeText" class="feature-badge">{{ badgeText }}</span>

    <span v-if="item.ownedQuantity > 0" class="owned-badge"
          :class="{ 'owned-badge-full': limitReached }">
      {{ item.ownedQuantity }}/{{ item.maxQuantity }}
    </span>
    <span v-else class="owned-badge owned-badge-empty">0/{{ item.maxQuantity }}</span>
    <div class="feature-icon">{{ item.icon }}</div>
    <h4 class="feature-title">{{ item.name }}</h4>
    <p class="feature-description">{{ item.description }}</p>

    <div class="feature-price-row">
      <div class="feature-price">
        <Coins :size="18" />
        <span>{{ item.price }}</span>
      </div>
      <button
        class="feature-buy-btn"
        :class="{ disabled: !canBuy || busy }"
        :disabled="!canBuy || busy"
        @click="emit('buy', item)"
      >
        <ShoppingBag :size="16" />
        {{ busy ? 'Kaufe...' : limitReached ? 'Max erreicht' : canAfford ? 'Jetzt kaufen' : 'Zu teuer' }}
      </button>
    </div>
  </article>
</template>

<style scoped>
.feature-card {
  position: relative;
  overflow: hidden;
  border-radius: 24px;
  padding: 22px;
  background: linear-gradient(180deg, rgba(15, 23, 42, 0.92), rgba(15, 23, 42, 0.78));
  border: 1px solid rgba(250, 204, 21, 0.18);
  box-shadow: 0 20px 40px rgba(2, 6, 23, 0.22);
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

.rarity-rare::before {
  background: linear-gradient(135deg, rgba(59, 130, 246, 0.24), transparent 55%);
}

.rarity-epic::before {
  background: linear-gradient(135deg, rgba(168, 85, 247, 0.28), transparent 55%);
}

.rarity-legendary::before {
  background: linear-gradient(135deg, rgba(245, 158, 11, 0.28), transparent 55%);
}

.feature-badge {
  position: absolute;
  right: 16px;
  top: 16px;
  z-index: 1;
  padding: 7px 10px;
  border-radius: 999px;
  background: linear-gradient(90deg, #f43f5e, #fb7185);
  color: white;
  font-size: 0.76rem;
  font-weight: 800;
}

.feature-icon,
.feature-title,
.feature-description,
.feature-price-row {
  position: relative;
  z-index: 1;
}

.feature-icon {
  font-size: 3rem;
  margin-bottom: 10px;
}

.feature-title {
  margin: 0 0 6px;
  color: white;
  font-size: 1.08rem;
}

.feature-description {
  margin: 0;
  color: #d8b4fe;
  min-height: 46px;
}

.feature-price-row {
  margin-top: 24px;
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 12px;
}

.feature-price {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  color: #facc15;
  font-weight: 800;
  font-size: 1.1rem;
}

.feature-buy-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  border: none;
  border-radius: 14px;
  padding: 12px 16px;
  background: linear-gradient(90deg, #f59e0b, #f97316);
  color: white;
  font-weight: 700;
  box-shadow: 0 14px 28px rgba(249, 115, 22, 0.22);
}

.feature-buy-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  border-color: transparent;
}

.feature-buy-btn.disabled,
.feature-buy-btn:disabled {
  background: rgba(71, 85, 105, 0.82);
  box-shadow: none;
}

@media (max-width: 680px) {
  .feature-price-row {
    flex-direction: column;
    align-items: stretch;
  }

  .feature-buy-btn {
    justify-content: center;
  }
}

.owned-badge {
  display: inline-block;
  padding: 5px 12px;
  border-radius: 999px;
  background: rgba(34, 197, 94, 0.18);
  border: 1px solid rgba(34, 197, 94, 0.4);
  color: #86efac;
  font-size: 0.76rem;
  font-weight: 700;
  margin-bottom: 6px;
  z-index: 1;
  position: relative;
}

.owned-badge-empty {
  background: rgba(148, 163, 184, 0.1);
  border-color: rgba(148, 163, 184, 0.25);
  color: rgba(148, 163, 184, 0.6);
}

.owned-badge-full {
  background: rgba(239, 68, 68, 0.18);
  border-color: rgba(239, 68, 68, 0.4);
  color: #fca5a5;
}
</style>
