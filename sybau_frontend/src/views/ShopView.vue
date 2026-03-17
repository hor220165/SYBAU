<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { Coins, Package, Sparkles, Target, Zap } from 'lucide-vue-next';
import Navbar from '@/components/Navbar.vue';
import Header from '@/components/Header.vue';
import ShopItemCard from '@/components/ShopItemCard.vue';
import ShopFeatureCard from '@/components/ShopFeatureCard.vue';
import { useAuth } from '@/composables/useAuth';
import { ItemType } from '@/models/ItemType';
import type { item } from '@/models/Item';
import type { ShopDisplayItem } from '@/models/ShopDisplayItem';
import { itemService, userService } from '@/services/api';

const items = ref<ShopDisplayItem[]>([]);
const loading = ref(false);
const error = ref('');
const successMessage = ref('');
const buyingItemId = ref<number | null>(null);
const activeFilter = ref<'all' | 'chest' | 'boost' | 'item'>('all');
const { user, syncUserFromStorage } = useAuth();

const currentCoins = computed(() => Number(user.value?.coins ?? user.value?.Coins ?? 0));

const normalizeTypeValue = (value: unknown) => {
  if (value === ItemType.Booster || value === 'Booster' || value === 'booster') return 'Booster';
  return 'Cosmetic';
};

const getCategory = (shopItem: item): ShopDisplayItem['category'] => {
  const searchBase = `${shopItem.name} ${shopItem.description}`.toLowerCase();

  if (/chest|crate|box|truhe|bundle|pack/.test(searchBase)) {
    return 'chest';
  }

  if (
    normalizeTypeValue(shopItem.type) === 'Booster' ||
    Number(shopItem.xpBoostPercentage) > 0 ||
    /boost|xp|potion|luck/.test(searchBase)
  ) {
    return 'boost';
  }

  return 'item';
};

const getRarity = (shopItem: item): ShopDisplayItem['rarity'] => {
  const searchBase = `${shopItem.name} ${shopItem.description}`.toLowerCase();

  if (/legend|legendary|mythic/.test(searchBase) || shopItem.price >= 1200 || shopItem.xpBoostPercentage >= 100) {
    return 'legendary';
  }
  if (/epic|gold|premium/.test(searchBase) || shopItem.price >= 700 || shopItem.xpBoostPercentage >= 60) {
    return 'epic';
  }
  if (/rare|silver/.test(searchBase) || shopItem.price >= 350 || shopItem.xpBoostPercentage >= 25) {
    return 'rare';
  }
  return 'common';
};

const getIcon = (category: ShopDisplayItem['category'], rarity: ShopDisplayItem['rarity']) => {
  if (category === 'chest') {
    if (rarity === 'legendary') return '👑';
    if (rarity === 'epic') return '💎';
    if (rarity === 'rare') return '🎁';
    return '📦';
  }

  if (category === 'boost') {
    if (rarity === 'legendary') return '✨';
    if (rarity === 'epic') return '⚡';
    if (rarity === 'rare') return '🧪';
    return '💫';
  }

  return '🛡️';
};

const buildHighlights = (shopItem: item, category: ShopDisplayItem['category']) => {
  const highlights: string[] = [];

  if (shopItem.xpBoostPercentage > 0) {
    highlights.push(`+${shopItem.xpBoostPercentage}% XP Boost`);
  }

  if (category === 'chest') {
    highlights.push('Loot-Reward Item');
    highlights.push('Ideal für neue Drops');
  } else if (category === 'boost') {
    highlights.push('Direkter Fortschritts-Boost');
    highlights.push('Perfekt für schnelle XP-Runs');
  } else {
    highlights.push('Kosmetisches Upgrade');
    highlights.push('Für Avatar und Sammlung');
  }

  if (shopItem.description && !highlights.includes(shopItem.description)) {
    highlights.unshift(shopItem.description);
  }

  return highlights.slice(0, 3);
};

const toDisplayItem = (shopItem: item): ShopDisplayItem => {
  const category = getCategory(shopItem);
  const rarity = getRarity(shopItem);

  return {
    id: shopItem.id,
    name: shopItem.name,
    description: shopItem.description,
    price: Number(shopItem.price ?? 0),
    type: shopItem.type,
    xpBoostPercentage: Number(shopItem.xpBoostPercentage ?? 0),
    category,
    categoryLabel: category === 'chest' ? 'Chest' : category === 'boost' ? 'Boost' : 'Item',
    rarity,
    icon: getIcon(category, rarity),
    highlights: buildHighlights(shopItem, category),
  };
};

const rarityScore: Record<ShopDisplayItem['rarity'], number> = {
  common: 1,
  rare: 2,
  epic: 3,
  legendary: 4,
};

const featuredItems = computed(() =>
  [...items.value]
    .sort((a, b) => {
      const rarityDifference = rarityScore[b.rarity] - rarityScore[a.rarity];
      if (rarityDifference !== 0) return rarityDifference;
      return b.price - a.price;
    })
    .slice(0, 3),
);

const filteredItems = computed(() => {
  if (activeFilter.value === 'all') return items.value;
  return items.value.filter((shopItem) => shopItem.category === activeFilter.value);
});

const activeFilterLabel = computed(() => {
  const labels = {
    all: 'Shop-Items',
    chest: 'Chests',
    boost: 'Boosts',
    item: 'Items',
  } as const;

  return labels[activeFilter.value];
});

const loadProfile = async () => {
  try {
    await userService.getProfile();
  } catch (profileError) {
    console.warn('Profil konnte nicht aktualisiert werden:', profileError);
  } finally {
    syncUserFromStorage();
  }
};

const loadShopItems = async () => {
  loading.value = true;
  error.value = '';

  try {
    const response = await itemService.getShopItems();
    const rawItems = Array.isArray(response.data) ? response.data : [];
    items.value = rawItems.map(toDisplayItem);
  } catch (shopError: any) {
    console.error('Fehler beim Laden der Shop-Items:', shopError);
    error.value = shopError.response?.data?.message || shopError.response?.data || 'Fehler beim Laden der Shop-Items';
  } finally {
    loading.value = false;
  }
};

const buyItem = async (shopItem: ShopDisplayItem) => {
  buyingItemId.value = shopItem.id;
  error.value = '';
  successMessage.value = '';

  try {
    await itemService.buyItem(shopItem.id);
    await loadProfile();
    successMessage.value = `✅ ${shopItem.name} gekauft! Verbleibende Coins: ${currentCoins.value}`;

    window.setTimeout(() => {
      successMessage.value = '';
    }, 3000);
  } catch (buyError: any) {
    console.error('Fehler beim Kauf:', buyError);
    error.value = buyError.response?.data?.message || buyError.response?.data || 'Kauf fehlgeschlagen';

    window.setTimeout(() => {
      error.value = '';
    }, 4000);
  } finally {
    buyingItemId.value = null;
  }
};

const loadPageData = async () => {
  syncUserFromStorage();
  await loadProfile();
  await loadShopItems();
};

onMounted(loadPageData);
</script>

<template>
  <div class="shop-page-shell">
    <Header />
    <Navbar />

    <main class="shop-page">
      <section class="shop-hero-card">
        <div class="hero-copy">
          <span class="hero-kicker">Shop</span>
          <h1>Item Shop</h1>
          <p>
            Kaufe Chests, Booster und kosmetische Upgrades im Figma-Look – aber direkt auf deine
            echte Shop-API gemappt.
          </p>
        </div>

        <div class="wallet-box">
          <span class="wallet-label">Deine Coins</span>
          <div class="wallet-value-row">
            <Coins :size="22" />
            <strong>{{ currentCoins.toLocaleString() }}</strong>
          </div>
        </div>
      </section>

      <div v-if="loading" class="state-box">Lade Shop-Items…</div>
      <div v-if="error" class="state-box state-box-error">{{ error }}</div>
      <div v-if="successMessage" class="state-box state-box-success">{{ successMessage }}</div>

      <template v-if="!loading">
        <section v-if="featuredItems.length" class="section-card">
          <div class="section-heading section-heading-spread">
            <div>
              <div class="title-with-icon">
                <Sparkles :size="20" />
                <h2>Highlights</h2>
              </div>
              <p>Die stärksten oder seltensten Shop-Items aus deinem aktuellen Backend.</p>
            </div>
            <span class="mini-pill">Live aus dem echten Shop</span>
          </div>

          <div class="feature-grid">
            <ShopFeatureCard
              v-for="(shopItem, index) in featuredItems"
              :key="`featured-${shopItem.id}`"
              :item="shopItem"
              :current-coins="currentCoins"
              :busy="buyingItemId === shopItem.id"
              :badge-text="index === 0 ? 'Top Pick' : index === 1 ? 'Beliebt' : 'Neu im Fokus'"
              @buy="buyItem"
            />
          </div>
        </section>

        <section class="section-card">
          <div class="section-heading section-heading-spread">
            <div>
              <div class="title-with-icon">
                <Package :size="20" />
                <h2>{{ activeFilterLabel }}</h2>
              </div>
              <p>
                Die Karten sind als eigene Komponenten gebaut, damit du neue Chests und Booster
                später nur noch als neue Shop-Items hinzufügen musst.
              </p>
            </div>
          </div>

          <div class="filter-row">
            <button
              class="filter-chip"
              :class="{ active: activeFilter === 'all' }"
              @click="activeFilter = 'all'"
            >
              Alle
            </button>
            <button
              class="filter-chip"
              :class="{ active: activeFilter === 'chest' }"
              @click="activeFilter = 'chest'"
            >
              📦 Chests
            </button>
            <button
              class="filter-chip"
              :class="{ active: activeFilter === 'boost' }"
              @click="activeFilter = 'boost'"
            >
              ⚡ Boosts
            </button>
            <button
              class="filter-chip"
              :class="{ active: activeFilter === 'item' }"
              @click="activeFilter = 'item'"
            >
              🛡️ Items
            </button>
          </div>

          <div v-if="filteredItems.length" class="items-grid">
            <ShopItemCard
              v-for="shopItem in filteredItems"
              :key="shopItem.id"
              :item="shopItem"
              :current-coins="currentCoins"
              :busy="buyingItemId === shopItem.id"
              @buy="buyItem"
            />
          </div>
          <div v-else class="empty-box">
            <Sparkles :size="18" />
            Für diesen Filter gibt es aktuell keine Items.
          </div>
        </section>

        <section class="section-card earn-card">
          <div class="earn-copy">
            <div class="title-with-icon">
              <Target :size="20" />
              <h2>Mehr Coins verdienen</h2>
            </div>
            <p>Workouts und Quests sind weiterhin dein schnellster Weg, um dir neue Shop-Items zu holen.</p>
          </div>

          <div class="earn-stats">
            <article class="earn-pill">
              <Zap :size="18" />
              <div>
                <span>Pro Workout</span>
                <strong>50–150 Coins</strong>
              </div>
            </article>
            <article class="earn-pill">
              <Sparkles :size="18" />
              <div>
                <span>Pro Quest</span>
                <strong>100–500 Coins</strong>
              </div>
            </article>
          </div>
        </section>
      </template>
    </main>
  </div>
</template>

<style scoped>
.shop-page-shell {
  min-height: 100vh;
  color: white;
}

.shop-page {
  width: min(1280px, calc(100% - 32px));
  margin: 0 auto;
  padding: 32px 0 48px;
  display: grid;
  gap: 24px;
}

.shop-hero-card,
.section-card,
.state-box,
.empty-box {
  border-radius: 28px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(15, 23, 42, 0.56);
  backdrop-filter: blur(18px);
  -webkit-backdrop-filter: blur(18px);
  box-shadow: 0 24px 50px rgba(2, 6, 23, 0.22);
}

.shop-hero-card {
  display: grid;
  grid-template-columns: minmax(0, 1.2fr) minmax(240px, 0.5fr);
  gap: 24px;
  align-items: center;
  padding: clamp(24px, 3vw, 36px);
  background: linear-gradient(135deg, #ec4899, #f43f5e);
}

.hero-kicker {
  display: inline-flex;
  border-radius: 999px;
  padding: 7px 12px;
  background: rgba(255, 255, 255, 0.14);
  color: #fef3c7;
  font-size: 0.82rem;
  font-weight: 700;
  margin-bottom: 14px;
}

.hero-copy h1 {
  margin: 0;
  font-size: clamp(2rem, 4vw, 3.4rem);
  line-height: 1;
}

.hero-copy p {
  margin: 16px 0 0;
  color: rgba(255, 255, 255, 0.84);
  max-width: 58ch;
  line-height: 1.65;
}

.wallet-box {
  justify-self: end;
  width: min(100%, 280px);
  padding: 22px;
  border-radius: 24px;
  background: rgba(255, 255, 255, 0.12);
  border: 1px solid rgba(255, 255, 255, 0.12);
}

.wallet-label {
  color: rgba(255, 255, 255, 0.72);
  font-size: 0.86rem;
}

.wallet-value-row {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 10px;
  color: #facc15;
}

.wallet-value-row strong {
  font-size: clamp(1.35rem, 3vw, 2rem);
}

.section-card {
  padding: clamp(22px, 3vw, 30px);
}

.section-heading {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 22px;
}

.section-heading p {
  margin: 0;
  color: #cbd5e1;
}

.section-heading-spread {
  flex-direction: row;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.title-with-icon {
  display: flex;
  align-items: center;
  gap: 10px;
}

.title-with-icon h2 {
  margin: 0;
  font-size: 1.2rem;
}

.title-with-icon svg {
  color: #facc15;
}

.mini-pill {
  display: inline-flex;
  align-items: center;
  border-radius: 999px;
  padding: 10px 14px;
  color: #fde68a;
  background: rgba(250, 204, 21, 0.1);
  border: 1px solid rgba(250, 204, 21, 0.2);
  white-space: nowrap;
}

.feature-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 18px;
}

.filter-row {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  margin-bottom: 18px;
}

.filter-chip {
  border: 1px solid rgba(139, 92, 246, 0.24);
  border-radius: 999px;
  padding: 11px 14px;
  color: #ddd6fe;
  background: rgba(15, 23, 42, 0.44);
  font-weight: 700;
}

.filter-chip.active {
  background: linear-gradient(90deg, #a855f7, #ec4899);
  color: white;
  border-color: transparent;
}

.filter-chip:hover {
  border-color: rgba(236, 72, 153, 0.36);
}

.items-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 18px;
}

.earn-card {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 20px;
  align-items: center;
}

.earn-copy p {
  margin: 12px 0 0;
  color: #cbd5e1;
}

.earn-stats {
  display: grid;
  grid-template-columns: repeat(2, minmax(180px, 1fr));
  gap: 14px;
}

.earn-pill {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px 18px;
  border-radius: 20px;
  background: rgba(15, 23, 42, 0.44);
  border: 1px solid rgba(139, 92, 246, 0.18);
}

.earn-pill svg {
  color: #facc15;
}

.earn-pill span {
  display: block;
  color: #cbd5e1;
  font-size: 0.82rem;
}

.earn-pill strong {
  display: block;
  margin-top: 4px;
  color: white;
}

.state-box,
.empty-box {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 12px;
  padding: 26px;
}

.state-box-error {
  color: #fecaca;
  background: rgba(127, 29, 29, 0.32);
}

.state-box-success {
  color: #dcfce7;
  background: rgba(20, 83, 45, 0.3);
}

@media (max-width: 1180px) {
  .feature-grid,
  .items-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 980px) {
  .shop-hero-card,
  .earn-card,
  .section-heading-spread {
    grid-template-columns: 1fr;
  }

  .section-heading-spread {
    align-items: flex-start;
  }

  .wallet-box {
    justify-self: stretch;
    width: 100%;
  }
}

@media (max-width: 760px) {
  .shop-page {
    width: min(100%, calc(100% - 24px));
    padding-top: 24px;
  }

  .feature-grid,
  .items-grid,
  .earn-stats {
    grid-template-columns: 1fr;
  }
}

@media (max-width: 560px) {
  .shop-page {
    width: min(100%, calc(100% - 16px));
    gap: 18px;
  }

  .shop-hero-card,
  .section-card,
  .state-box,
  .empty-box {
    border-radius: 22px;
  }
}
</style>
