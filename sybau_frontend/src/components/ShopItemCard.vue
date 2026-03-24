<script setup lang="ts">
import { computed } from 'vue';
import { Coins, ShoppingBag, Sparkles, Package, Zap, Shirt } from 'lucide-vue-next';
import type { ShopDisplayItem } from '@/models/ShopDisplayItem';

const props = defineProps<{
  item: ShopDisplayItem;
  currentCoins: number;
  busy?: boolean;
}>();

const emit = defineEmits<{
  (e: 'buy', item: ShopDisplayItem): void;
}>();

const canAfford = computed(() => props.currentCoins >= props.item.price);
const limitReached = computed(() => props.item.ownedQuantity >= props.item.maxQuantity);
const canBuy = computed(() => canAfford.value && !limitReached.value);

const categoryIcon = computed(() => {
  if (props.item.category === 'chest') return Package;
  if (props.item.category === 'boost') return Zap;
  return Shirt;
});
</script>

<template>
  <article class="shop-item-card" :class="[`rarity-${item.rarity}`, `category-${item.category}`]">
    <div class="card-background"></div>

    <div class="card-content">
      <div class="card-top-row">
        <div class="item-icon-shell">
          <span class="item-icon">{{ item.icon }}</span>
        </div>

        <div class="item-badges">
          <span v-if="item.ownedQuantity > 0" class="owned-badge"
                :class="{ 'owned-badge-full': limitReached }">
            {{ item.ownedQuantity }}/{{ item.maxQuantity }}
          </span>
          <span v-else class="owned-badge owned-badge-empty">0/{{ item.maxQuantity }}</span>
          <span class="rarity-badge">{{ item.rarity }}</span>
          <span class="category-badge">
            <component :is="categoryIcon" :size="14" />
            {{ item.categoryLabel }}
          </span>
        </div>
      </div>

      <div class="title-block">
        <h3>{{ item.name }}</h3>
        <p>{{ item.description }}</p>
      </div>

      <ul class="highlight-list">
        <li v-for="highlight in item.highlights" :key="highlight">
          <Sparkles :size="14" />
          <span>{{ highlight }}</span>
        </li>
      </ul>

      <div class="item-footer">
        <div class="price-block">
          <Coins :size="18" />
          <span>{{ item.price }}</span>
        </div>

        <button
          class="buy-button"
          :class="{ disabled: !canBuy || busy }"
          :disabled="!canBuy || busy"
          @click="emit('buy', item)"
        >
          <ShoppingBag :size="16" />
          {{ busy ? 'Kaufe...' : limitReached ? 'Max erreicht' : canAfford ? 'Kaufen' : 'Zu teuer' }}
        </button>
      </div>
    </div>
  </article>
</template>

<style scoped>
.shop-item-card {
  position: relative;
  overflow: hidden;
  border-radius: 24px;
  min-height: 100%;
  background: rgba(15, 23, 42, 0.68);
  border: 1px solid rgba(255, 255, 255, 0.08);
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
  opacity: 0.38;
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

.rarity-common {
  border-color: rgba(148, 163, 184, 0.18);
}

.rarity-rare {
  border-color: rgba(59, 130, 246, 0.2);
}

.rarity-epic {
  border-color: rgba(168, 85, 247, 0.24);
}

.rarity-legendary {
  border-color: rgba(250, 204, 21, 0.3);
}

.card-content {
  position: relative;
  z-index: 1;
  height: 100%;
  display: flex;
  flex-direction: column;
  padding: 22px;
}

.card-top-row {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: flex-start;
}

.item-icon-shell {
  width: 74px;
  height: 74px;
  flex-shrink: 0;
  display: grid;
  place-items: center;
  border-radius: 22px;
  background: rgba(2, 6, 23, 0.3);
  border: 1px solid rgba(255, 255, 255, 0.08);
}

.item-icon {
  font-size: 2.4rem;
}

.item-badges {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 8px;
}

.rarity-badge,
.category-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  border-radius: 999px;
  padding: 7px 11px;
  font-size: 0.76rem;
  font-weight: 700;
  text-transform: capitalize;
}

.rarity-badge {
  background: rgba(255, 255, 255, 0.1);
  color: white;
}

.category-badge {
  background: rgba(139, 92, 246, 0.14);
  color: #ddd6fe;
  border: 1px solid rgba(139, 92, 246, 0.22);
}

.title-block {
  margin-top: 18px;
}

.title-block h3 {
  margin: 0 0 8px;
  color: white;
  font-size: 1.08rem;
}

.title-block p {
  margin: 0;
  color: #d8b4fe;
  line-height: 1.55;
}

.highlight-list {
  list-style: none;
  margin: 18px 0 0;
  padding: 0;
  display: grid;
  gap: 10px;
}

.highlight-list li {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  color: #e2e8f0;
  font-size: 0.9rem;
}

.highlight-list svg {
  flex-shrink: 0;
  color: #c084fc;
  margin-top: 2px;
}

.item-footer {
  margin-top: auto;
  padding-top: 20px;
  display: flex;
  justify-content: space-between;
  gap: 12px;
  align-items: center;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
}

.price-block {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  color: #facc15;
  font-size: 1.18rem;
  font-weight: 800;
}

.buy-button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  border: none;
  border-radius: 14px;
  padding: 12px 16px;
  min-width: 132px;
  background: linear-gradient(90deg, #a855f7, #ec4899);
  color: white;
  font-weight: 700;
  box-shadow: 0 16px 30px rgba(168, 85, 247, 0.22);
}

.buy-button:hover:not(:disabled) {
  transform: translateY(-1px);
  border-color: transparent;
}

.buy-button.disabled,
.buy-button:disabled {
  background: rgba(71, 85, 105, 0.82);
  box-shadow: none;
}

@media (max-width: 560px) {
  .card-top-row,
  .item-footer {
    flex-direction: column;
    align-items: stretch;
  }

  .item-badges {
    align-items: flex-start;
  }

  .buy-button {
    width: 100%;
  }
}

.owned-badge {
  display: inline-flex;
  align-items: center;
  padding: 4px 10px;
  border-radius: 999px;
  background: rgba(34, 197, 94, 0.18);
  border: 1px solid rgba(34, 197, 94, 0.4);
  color: #86efac;
  font-size: 0.72rem;
  font-weight: 700;
  letter-spacing: 0.02em;
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
