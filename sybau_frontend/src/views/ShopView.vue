<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { Package, Sparkles } from 'lucide-vue-next';
import Navbar from '@/components/Navbar.vue';
import Header from '@/components/Header.vue';
import ShopItemCard from '@/components/ShopItemCard.vue';
import ShopFeatureCard from '@/components/ShopFeatureCard.vue';
import coinIcon from '@/assets/SYBAU_Coin.png';
import { ItemType } from '@/models/ItemType';
import type { item } from '@/models/Item';
import type { ShopDisplayItem } from '@/models/ShopDisplayItem';
import { itemService, userService } from '@/services/api';
import FooterComponent from '@/components/FooterComponent.vue';
import { useAuth } from '@/composables/useAuth';
import MessagePopup from '@/components/MessagePopup.vue';

const items = ref<ShopDisplayItem[]>([]);
const ownedItems = ref<Record<number, number>>({});
const currentCoins = ref(0);
const loading = ref(false);
const error = ref('');
const successMessage = ref('');
const buyingItemId = ref<number | null>(null);
const activeFilter = ref<'all' | 'chest' | 'boost' | 'item'>('all');
const { refreshUser } = useAuth();

const popupMessage = ref("");
const popupType = ref<"success" | "error">("success");


const syncCoinsFromStorage = () => {
  const raw = JSON.parse(localStorage.getItem('user') || '{}');
  currentCoins.value = Number(raw.coins ?? raw.Coins ?? 0);
};

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
  // Rarity aus Backend nutzen wenn vorhanden
  if (shopItem.rarity) return shopItem.rarity;

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
    ownedQuantity: ownedItems.value[shopItem.id] ?? 0,
    maxQuantity: (shopItem as any).maxQuantity ?? 5,
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
    syncCoinsFromStorage();
    refreshUser(); 
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

  // Owned-Quantity lokal hochzählen
  ownedItems.value[shopItem.id] = (ownedItems.value[shopItem.id] ?? 0) + 1;
  // Items neu mappen damit Quantity aktualisiert wird
  items.value = items.value.map(i => ({ ...i, ownedQuantity: ownedItems.value[i.id] ?? 0 }));

  popupType.value = "success";
  popupMessage.value = `${shopItem.name} gekauft! Verbleibende Coins: ${currentCoins.value}`;
} catch (buyError: any) {
  console.error("Fehler beim Kauf:", buyError);

  popupType.value = "error";
  popupMessage.value =
    buyError.response?.data?.message ||
    buyError.response?.data ||
    "Kauf fehlgeschlagen";
} finally {
  buyingItemId.value = null;
}

};

const loadOwnedItems = async () => {
  try {
    const res = await userService.getUserBoosters();
    const boosters = res.data ?? [];
    const map: Record<number, number> = {};
    for (const b of boosters) {
      map[b.id] = b.quantity ?? 1;
    }
    ownedItems.value = map;
  } catch (e) {
    console.warn('Inventar konnte nicht geladen werden', e);
  }
};

const loadPageData = async () => {
  syncCoinsFromStorage();
  await loadProfile();
  await loadOwnedItems();
  await loadShopItems();
};

onMounted(loadPageData);
</script>

<template>

  <MessagePopup
  v-if="popupMessage"
  :message="popupMessage"
  :type="popupType"
  @close="popupMessage = ''"
/>

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

      </section>

      <div v-if="loading" class="state-box">Lade Shop-Items…</div>
      <div v-if="error" class="state-box state-box-error">{{ error }}</div>

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
              Chests
            </button>
            <button
              class="filter-chip"
              :class="{ active: activeFilter === 'boost' }"
              @click="activeFilter = 'boost'"
            >
              Boosts
            </button>
            <button
              class="filter-chip"
              :class="{ active: activeFilter === 'item' }"
              @click="activeFilter = 'item'"
            >
              Items
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
            <div class="earn-title">
              <div>
                <h2>Coins verdienen</h2>
                <p>Schließe Aktivitäten ab. Die Coins werden danach automatisch deinem Konto gutgeschrieben.</p>
              </div>
            </div>
          </div>

          <div class="earn-stats">
            <article class="earn-pill">
              <div>
                <span>Workout abschließen</span>
                <strong>
                  <img :src="coinIcon" alt="" class="earn-coin" />
                  50–150
                </strong>
              </div>
            </article>
            <article class="earn-pill">
              <div>
                <span>Quest erledigen</span>
                <strong>
                  <img :src="coinIcon" alt="" class="earn-coin" />
                  100–500
                </strong>
              </div>
            </article>
          </div>
        </section>
      </template>
    </main>
     <!-- Footer -->
    <FooterComponent />
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

.section-card,
.state-box,
.empty-box {
  border-radius: 22px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  background: rgba(15, 23, 42, 0.62);
  backdrop-filter: blur(18px);
  -webkit-backdrop-filter: blur(18px);
  box-shadow: 0 18px 42px rgba(2, 6, 23, 0.24);
}

.shop-hero-card {
  display: block;
  padding: 0;
  background: transparent;
}

.hero-kicker {
  display: inline-flex;
  padding: 0;
  background: transparent;
  border: 0;
  color: #f9a8d4;
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
  border: 1px solid rgba(236, 72, 153, 0.22);
  border-radius: 999px;
  padding: 11px 14px;
  color: #f9a8d4;
  background: rgba(15, 23, 42, 0.44);
  font-weight: 700;
}

.filter-chip.active {
  background: linear-gradient(90deg, #ec4899, #f43f5e);
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

.earn-title {
  display: flex;
  align-items: center;
  gap: 16px;
}

.earn-title-coin {
  width: 42px;
  height: 42px;
  image-rendering: pixelated;
  flex: 0 0 auto;
}

.earn-title h2 {
  margin: 0;
  font-size: 1.35rem;
}

.earn-title p {
  margin: 8px 0 0;
  color: #cbd5e1;
  line-height: 1.5;
}

.earn-stats {
  display: grid;
  grid-template-columns: repeat(2, minmax(170px, 1fr));
  gap: 12px;
}

.earn-pill {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 16px;
  border-radius: 18px;
  background: rgba(2, 6, 23, 0.42);
  border: 1px solid rgba(255, 255, 255, 0.075);
}

.earn-coin {
  width: 24px;
  height: 24px;
  image-rendering: pixelated;
  flex: 0 0 auto;
}

.earn-pill span {
  display: block;
  color: rgba(255, 255, 255, 0.62);
  font-size: 0.82rem;
  font-weight: 700;
}

.earn-pill strong {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  margin-top: 4px;
  color: white;
  font-size: 1.05rem;
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
  .earn-card,
  .section-heading-spread {
    grid-template-columns: 1fr;
  }

  .section-heading-spread {
    align-items: flex-start;
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

  .section-card,
  .state-box,
  .empty-box {
    border-radius: 22px;
  }
}
</style>
